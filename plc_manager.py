#!/usr/bin/env python3

import argparse
import ipaddress
import os
import re
import subprocess
import sys
import time

import requests

USERNAME = "openplc"
PASSWORD = "openplc"
OPENPLC_WEB_PORT = 8080
DOCKER_COMPOSE_TIMEOUT_S = 300
COMPILE_LOG_POLL_INTERVAL_S = 2
COMPILE_LOG_FETCH_TIMEOUT_S = 10
MAX_COMPILE_LOG_DELTA_CHARS = 8000


def is_loopback_ip(ip):
    if ip == "localhost":
        return True

    try:
        return ipaddress.ip_address(ip).is_loopback
    except ValueError:
        return False


def get_published_host_ports(plc_name):
    try:
        output = subprocess.check_output(
            ["docker", "port", plc_name, str(OPENPLC_WEB_PORT)],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return set()

    ports = set()
    for line in output.splitlines():
        line = line.strip()
        if not line:
            continue

        # docker port output examples:
        # 0.0.0.0:8210
        # [::]:8210
        host_port = line.rsplit(":", 1)[-1]
        if host_port.isdigit():
            ports.add(int(host_port))

    return ports


def is_openplc_login(html):
    html_l = html.lower()
    has_openplc_marker = "openplc" in html_l
    has_login_form_fields = (
        "name='username'" in html_l
        or 'name="username"' in html_l
        or "name='password'" in html_l
        or 'name="password"' in html_l
    )
    return has_openplc_marker and has_login_form_fields


def is_login_form_html(html):
    html_l = (html or "").lower()
    return (
        ("name='username'" in html_l or 'name="username"' in html_l)
        and ("name='password'" in html_l or 'name="password"' in html_l)
    )


# ---------------------------
# Start Docker
# ---------------------------
def run_docker(plc_name, ip, port):
    print(f"🚀 Starting PLC '{plc_name}' at {ip}:{port}")

    env = {
        "SERVICE_NAME": plc_name,
        "TARGET_IP": ip,
        "PORT": str(port),
    }

    try:
        subprocess.run(
            ["docker", "compose", "up", "-d"],
            env={**os.environ, **env},
            check=True,
            timeout=DOCKER_COMPOSE_TIMEOUT_S,
        )
    except subprocess.TimeoutExpired:
        print("❌ Timed out while starting Docker Compose")
        sys.exit(1)


# ---------------------------
# Stop Docker
# ---------------------------
def down_docker(plc_name, ip, port):
    print(f"🛑 Stopping PLC '{plc_name}'")

    env = {
        "SERVICE_NAME": plc_name,
        "TARGET_IP": ip,
        "PORT": str(port),
    }

    try:
        subprocess.run(
            ["docker", "compose", "down"],
            env={**os.environ, **env},
            check=True,
            timeout=DOCKER_COMPOSE_TIMEOUT_S,
        )
    except subprocess.TimeoutExpired:
        print("❌ Timed out while stopping Docker Compose")
        sys.exit(1)


# ---------------------------
# Resolve usable web endpoint
# ---------------------------
def build_base_candidates(plc_name, ip, port):
    raw = [
        f"http://{ip}:{port}",
    ]

    # OpenPLC web UI runs on 8080 in-container. If caller passes a host-mapped
    # port (e.g. 4840), fallback candidates help reach the same service.
    if port != OPENPLC_WEB_PORT:
        raw.append(f"http://{ip}:{OPENPLC_WEB_PORT}")

    published_ports = get_published_host_ports(plc_name)
    allow_localhost = (
        is_loopback_ip(ip)
        or port in published_ports
        or OPENPLC_WEB_PORT in published_ports
    )

    if allow_localhost:
        raw.append(f"http://127.0.0.1:{port}")
        if port != OPENPLC_WEB_PORT:
            raw.append(f"http://127.0.0.1:{OPENPLC_WEB_PORT}")

    seen = set()
    candidates = []
    for base in raw:
        if base not in seen:
            seen.add(base)
            candidates.append(base)

    return candidates


# ---------------------------
# Wait for PLC readiness
# ---------------------------
def wait_for_plc(plc_name, ip, port, timeout=30):
    print("⏳ Waiting for PLC to become ready...")
    candidates = build_base_candidates(plc_name, ip, port)
    deadline = time.time() + timeout
    last_error = None
    non_openplc_candidates = set()

    while time.time() < deadline:
        for base in candidates:
            url = f"{base}/login"
            try:
                r = requests.get(url, timeout=2)
                if r.status_code == 200 and is_openplc_login(r.text or ""):
                    print(f"✅ PLC is ready at {base}")
                    return base
                if r.status_code == 200 and base not in non_openplc_candidates:
                    non_openplc_candidates.add(base)
                    print(f"⚠️ Ignoring non-OpenPLC service at {base}")
            except requests.RequestException as exc:
                last_error = exc

        time.sleep(1)

    print("❌ PLC did not become ready in time")
    print("Tried endpoints:", ", ".join(candidates))
    if last_error:
        print("Last error:", last_error)
    sys.exit(1)


# ---------------------------
# Extract values from HTML
# ---------------------------
def extract(html, key):
    html = html.replace(">", "\n")

    if key == "file":
        matches = re.findall(r"value='([0-9]+\.st)'", html)
        return matches[0] if matches else None

    if key == "epoch":
        match = re.search(r"id='epoch_time'.*?value='([0-9]+)'", html)
        if match:
            return match.group(1)

        match = re.search(r"value='([0-9]+)'.*epoch_time", html)
        return match.group(1) if match else None

    return None


# ---------------------------
# Wait for compile result
# ---------------------------
def wait_for_compile(session, base, timeout=180):
    print("⏳ Waiting for compilation to finish...")
    deadline = time.time() + timeout
    last_len = 0
    last_error = None

    while time.time() < deadline:
        try:
            r = session.get(f"{base}/compilation-logs", timeout=COMPILE_LOG_FETCH_TIMEOUT_S)

            # requests follows redirects; detect auth loss explicitly
            if r.url.rstrip("/").endswith("/login") or is_login_form_html(r.text):
                print("❌ Lost authentication while waiting for compilation logs")
                sys.exit(1)

            r.raise_for_status()
            logs = r.text or ""
        except requests.RequestException as exc:
            last_error = exc
            time.sleep(COMPILE_LOG_POLL_INTERVAL_S)
            continue

        if len(logs) < last_len:
            last_len = 0

        if len(logs) > last_len:
            delta = logs[last_len:]
            if len(delta) > MAX_COMPILE_LOG_DELTA_CHARS:
                delta = delta[-MAX_COMPILE_LOG_DELTA_CHARS:]
                print("   ... log output truncated ...")
            for line in delta.splitlines():
                line = line.strip()
                if line:
                    print(f"   {line}")
            last_len = len(logs)

        if "Compilation finished successfully!" in logs:
            print("✅ Compilation finished successfully")
            return

        if "Compilation finished with errors!" in logs:
            print("❌ Compilation failed")
            sys.exit(1)

        time.sleep(COMPILE_LOG_POLL_INTERVAL_S)

    print("❌ Compilation timed out")
    if last_error:
        print("Last error:", last_error)
    sys.exit(1)


# ---------------------------
# Deploy PLC program
# ---------------------------
def deploy_plc(base, plc_name, st_file):
    session = requests.Session()

    print(f"🔗 Using endpoint: {base}")
    print("🔐 Logging in...")
    session.post(
        f"{base}/login",
        data={"username": USERNAME, "password": PASSWORD},
        timeout=5,
    )

    print("📤 Uploading ST...")
    with open(st_file, "rb") as f:
        resp = session.post(
            f"{base}/upload-program",
            files={"file": ("program.st", f, "text/plain")},
            headers={"Origin": base, "Referer": f"{base}/programs"},
            timeout=20,
        )

    html = resp.text

    file_name = extract(html, "file")
    epoch = extract(html, "epoch")

    if not file_name or not epoch:
        print("❌ Failed to extract file/epoch")
        sys.exit(1)

    print(f"📄 File: {file_name}")
    print(f"⏱ Epoch: {epoch}")

    print("⚙️ Upload action...")
    session.post(
        f"{base}/upload-program-action",
        data={
            "prog_name": plc_name,
            "prog_descr": "",
            "prog_file": file_name,
            "epoch_time": epoch,
        },
        headers={"Origin": base, "Referer": f"{base}/programs"},
        timeout=20,
    )

    print("🔧 Compiling...")
    session.get(f"{base}/compile-program?file={file_name}", timeout=20)
    wait_for_compile(session, base)

    print("▶️ Starting PLC...")
    session.get(f"{base}/start_plc", headers={"Referer": f"{base}/dashboard"}, timeout=20)

    print("✅ PLC deployed successfully!")


# ---------------------------
# MAIN
# ---------------------------
def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("--ip", required=True)
    parser.add_argument("--port", required=True, type=int)
    parser.add_argument("--plc-name", required=True)
    parser.add_argument("--st-file")
    parser.add_argument("--down", action="store_true", help="Bring down the PLC")

    args = parser.parse_args()

    if args.down:
        down_docker(args.plc_name, args.ip, args.port)
        return

    if not args.st_file:
        parser.error("--st-file is required unless --down is specified")

    run_docker(args.plc_name, args.ip, args.port)
    base = wait_for_plc(args.plc_name, args.ip, args.port)
    deploy_plc(base, args.plc_name, args.st_file)


if __name__ == "__main__":
    main()

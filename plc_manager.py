#!/usr/bin/env python3

import argparse
import os
import re
import subprocess
import sys
import time

import requests

USERNAME = "openplc"
PASSWORD = "openplc"


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

    subprocess.run(
        ["docker", "compose", "up", "-d"],
        env={**os.environ, **env},
        check=True,
    )


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

    subprocess.run(
        ["docker", "compose", "down"],
        env={**os.environ, **env},
        check=True,
    )


# ---------------------------
# Resolve usable web endpoint
# ---------------------------
def build_base_candidates(ip, port):
    raw = [
        f"http://{ip}:{port}",
        f"http://127.0.0.1:{port}",
    ]

    # OpenPLC web UI runs on 8080 in-container. If caller passes a host-mapped
    # port (e.g. 4840), fallback candidates help reach the same service.
    if port != 8080:
        raw.extend([
            f"http://{ip}:8080",
            "http://127.0.0.1:8080",
        ])

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
def wait_for_plc(ip, port, timeout=30):
    print("⏳ Waiting for PLC to become ready...")
    candidates = build_base_candidates(ip, port)
    deadline = time.time() + timeout
    last_error = None

    while time.time() < deadline:
        for base in candidates:
            url = f"{base}/login"
            try:
                r = requests.get(url, timeout=2)
                if r.status_code == 200:
                    print(f"✅ PLC is ready at {base}")
                    return base
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

    while time.time() < deadline:
        r = session.get(f"{base}/compilation-logs", timeout=10)
        logs = r.text or ""

        if len(logs) > last_len:
            delta = logs[last_len:]
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

        time.sleep(1)

    print("❌ Compilation timed out")
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
    base = wait_for_plc(args.ip, args.port)
    deploy_plc(base, args.plc_name, args.st_file)


if __name__ == "__main__":
    main()

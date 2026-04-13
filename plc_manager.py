#!/usr/bin/env python3

import argparse
import subprocess
import time
import requests
import re
import sys

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
        "PORT": str(port)
    }

    subprocess.run(
        ["docker", "compose", "up", "-d"],
        env={**env, **dict(**env, **dict())},
        check=True
    )


# ---------------------------
# Stop Docker
# ---------------------------
def down_docker(plc_name, ip, port):
    print(f"🛑 Stopping PLC '{plc_name}'")

    env = {
        "SERVICE_NAME": plc_name,
        "TARGET_IP": ip,
        "PORT": str(port)
    }

    subprocess.run(
        ["docker", "compose", "down"],
        env={**env, **dict(**env, **dict())},
        check=True
    )


# ---------------------------
# Wait for PLC readiness
# ---------------------------
def wait_for_plc(ip, port, timeout=30):
    print("⏳ Waiting for PLC to become ready...")

    url = f"http://{ip}:{port}/login"

    for i in range(timeout):
        try:
            r = requests.get(url, timeout=2)
            if r.status_code == 200:
                print("✅ PLC is ready")
                return
        except:
            pass

        time.sleep(1)

    print("❌ PLC did not become ready in time")
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


# ---------------------------
# Deploy PLC program
# ---------------------------
def deploy_plc(ip, port, plc_name, st_file):
    base = f"http://{ip}:{port}"
    session = requests.Session()

    print("🔐 Logging in...")
    session.post(f"{base}/login", data={
        "username": USERNAME,
        "password": PASSWORD
    })

    print("📤 Uploading ST...")
    with open(st_file, "rb") as f:
        resp = session.post(
            f"{base}/upload-program",
            files={"file": ("program.st", f, "text/plain")},
            headers={
                "Origin": base,
                "Referer": f"{base}/programs"
            }
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
            "epoch_time": epoch
        },
        headers={
            "Origin": base,
            "Referer": f"{base}/programs"
        }
    )

    print("🔧 Compiling...")
    session.get(f"{base}/compile-program?file={file_name}")

    time.sleep(3)

    print("▶️ Starting PLC...")
    session.get(
        f"{base}/start_plc",
        headers={"Referer": f"{base}/dashboard"}
    )

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
    wait_for_plc(args.ip, args.port)
    deploy_plc(args.ip, args.port, args.plc_name, args.st_file)


if __name__ == "__main__":
    main()

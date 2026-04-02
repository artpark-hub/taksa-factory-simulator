#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: $0 <target_ip> <program_zip>
Example: $0 10.10.10.1 /home/plc-sim/Program1/program.zip

Environment overrides:
  COMPOSE_FILE   Path to docker-compose yaml (default: docker-compose.yaml)
  USER_NAME      OpenPLC username (default: admin)
  PASSWORD       OpenPLC password (required)
  INSECURE       1 to use curl -k (default: 0)
  TIMEOUT_SEC    Compilation timeout seconds (default: 300)
  POLL_SEC       Poll interval seconds (default: 1)
USAGE
}

if [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

is_valid_ipv4() {
  local ip="$1"
  local o1 o2 o3 o4 octet

  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1

  IFS='.' read -r o1 o2 o3 o4 <<< "$ip"
  for octet in "$o1" "$o2" "$o3" "$o4"; do
    [[ "$octet" =~ ^[0-9]{1,3}$ ]] || return 1
    (( 10#$octet <= 255 )) || return 1
  done

  return 0
}

TARGET_IP="$1"
ZIP_PATH="$2"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yaml}"
USER_NAME="${USER_NAME:-admin}"
PASSWORD="${PASSWORD:-}"
INSECURE="${INSECURE:-0}"
TIMEOUT_SEC="${TIMEOUT_SEC:-300}"
POLL_SEC="${POLL_SEC:-1}"

if ! is_valid_ipv4 "$TARGET_IP"; then
  echo "ERROR: target_ip must be a valid IPv4 address. Got: $TARGET_IP" >&2
  usage
  exit 1
fi

if [[ -z "$PASSWORD" ]]; then
  echo "ERROR: PASSWORD environment variable is required" >&2
  exit 1
fi

if [[ "$INSECURE" == "1" ]]; then
  echo "WARN: TLS certificate verification is disabled (INSECURE=1)" >&2
  CURL_TLS=(-sk)
else
  CURL_TLS=(-s)
fi

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing command: $1" >&2; exit 1; }
}

need docker
need curl
need python3

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "ERROR: compose file not found: $COMPOSE_FILE" >&2
  exit 1
fi

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "ERROR: ZIP file not found: $ZIP_PATH" >&2
  exit 1
fi

PLC_NUM="${TARGET_IP##*.}"
SERVICE_NAME="openplc${PLC_NUM}"

json_get_env() {
  local key="$1"
  JSON_KEY="$key" JSON_PAYLOAD="$2" python3 - <<'PY'
import json, os, sys
payload = os.environ.get('JSON_PAYLOAD', '').strip()
key = os.environ.get('JSON_KEY', '').strip()
try:
    data = json.loads(payload)
except Exception:
    print('')
    sys.exit(0)
if isinstance(data, dict):
    val = data.get(key, '')
    if isinstance(val, (dict, list)):
        print(json.dumps(val))
    elif val is None:
        print('')
    else:
        print(str(val))
else:
    print('')
PY
}

auth_header() {
  printf 'Authorization: Bearer %s' "$ACCESS_TOKEN"
}

wait_http_up() {
  local url="$1"
  local ready=0
  for _ in $(seq 1 120); do
    local resp
    if ! resp="$(curl "${CURL_TLS[@]}" --connect-timeout 2 "$url" 2>&1)"; then
      echo "WARN: runtime check failed: $resp" >&2
      sleep 1
      continue
    fi
    if echo "$resp" | grep -Eq 'Missing Authorization Header|Bad Authorization header|PING:OK'; then
      ready=1
      break
    fi
    sleep 1
  done
  [[ "$ready" == "1" ]]
}

login() {
  local resp
  resp="$({ curl "${CURL_TLS[@]}" -X POST "${BASE_URL}/login" \
      -H "Content-Type: application/json" \
      -d "{\"username\":\"${USER_NAME}\",\"password\":\"${PASSWORD}\"}"; } || true)"

  ACCESS_TOKEN="$(json_get_env access_token "$resp")"
  if [[ -z "$ACCESS_TOKEN" ]]; then
    echo "ERROR: login failed" >&2
    exit 1
  fi
  echo "Login successful"
}

echo "== target service =="
echo "$SERVICE_NAME"

echo "== removing old target container if present =="
if docker ps -a --format '{{.Names}}' | grep -qx "$SERVICE_NAME"; then
  if ! docker stop "$SERVICE_NAME" >/dev/null 2>&1; then
    echo "ERROR: failed to stop existing container ${SERVICE_NAME}" >&2
    exit 1
  fi
  if ! docker rm -f "$SERVICE_NAME" >/dev/null 2>&1; then
    echo "ERROR: failed to remove existing container ${SERVICE_NAME}" >&2
    exit 1
  fi
fi

echo "== docker compose up only ${SERVICE_NAME} =="
docker compose -f "$COMPOSE_FILE" up -d "$SERVICE_NAME"

sleep 3

NETWORK_NAME="$(docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{println $k}}{{end}}' "$SERVICE_NAME" | head -n1 | tr -d '[:space:]')"
if [[ -z "$NETWORK_NAME" ]]; then
  echo "ERROR: could not determine Docker network for ${SERVICE_NAME}" >&2
  exit 1
fi

echo "== docker network =="
echo "$NETWORK_NAME"

CURRENT_IP="$(docker inspect -f "{{with index .NetworkSettings.Networks \"${NETWORK_NAME}\"}}{{.IPAddress}}{{end}}" "$SERVICE_NAME")"

echo "== current container IP =="
echo "$CURRENT_IP"

if [[ "$CURRENT_IP" != "$TARGET_IP" ]]; then
  echo "== assigning requested static IP ${TARGET_IP} on ${NETWORK_NAME} =="
  docker network disconnect "$NETWORK_NAME" "$SERVICE_NAME" || true
  docker network connect --ip "$TARGET_IP" "$NETWORK_NAME" "$SERVICE_NAME"
fi

ACTUAL_IP="$(docker inspect -f "{{with index .NetworkSettings.Networks \"${NETWORK_NAME}\"}}{{.IPAddress}}{{end}}" "$SERVICE_NAME")"

echo "== actual container IP =="
echo "$ACTUAL_IP"

if [[ "$ACTUAL_IP" != "$TARGET_IP" ]]; then
  echo "ERROR: failed to assign requested IP. Expected $TARGET_IP but got $ACTUAL_IP" >&2
  exit 1
fi

BASE_URL="https://${TARGET_IP}:8443/api"

echo "== waiting for runtime on ${TARGET_IP}:8443 =="
if ! wait_http_up "$BASE_URL/ping"; then
  echo "ERROR: runtime did not become reachable within 120 seconds" >&2
  docker logs --tail 100 "$SERVICE_NAME" || true
  exit 1
fi

echo "== create user if needed =="
curl "${CURL_TLS[@]}" -X POST "${BASE_URL}/create-user" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${USER_NAME}\",\"password\":\"${PASSWORD}\",\"role\":\"admin\"}" || true
echo

ACCESS_TOKEN=""
echo "== login =="
login

echo "== ping =="
curl "${CURL_TLS[@]}" "${BASE_URL}/ping" -H "$(auth_header)"
echo

echo "== status =="
curl "${CURL_TLS[@]}" "${BASE_URL}/status" -H "$(auth_header)"
echo

echo "== stop =="
curl "${CURL_TLS[@]}" "${BASE_URL}/stop-plc" -H "$(auth_header)"
echo

echo "== upload =="
curl "${CURL_TLS[@]}" -X POST "${BASE_URL}/upload-file" \
  -H "$(auth_header)" \
  -F "file=@${ZIP_PATH}"
echo

echo "== wait for compilation =="
START_TS="$(date +%s)"
while true; do
  RESP="$(curl "${CURL_TLS[@]}" "${BASE_URL}/compilation-status" -H "$(auth_header)")"

  STATUS="$(json_get_env status "$RESP")"
  MESSAGE="$(json_get_env message "$RESP")"
  if [[ -n "$MESSAGE" ]]; then
    echo "Compilation status: ${STATUS:-UNKNOWN} - ${MESSAGE}"
  else
    echo "Compilation status: ${STATUS:-UNKNOWN}"
  fi
  if [[ "$STATUS" == "SUCCESS" ]]; then
    echo "Compilation successful"
    break
  fi
  if [[ "$STATUS" == "FAILED" ]]; then
    echo "ERROR: compilation failed" >&2
    exit 1
  fi

  NOW="$(date +%s)"
  ELAPSED=$((NOW - START_TS))
  if (( ELAPSED >= TIMEOUT_SEC )); then
    echo "ERROR: compilation timed out after ${TIMEOUT_SEC} seconds" >&2
    exit 1
  fi
  sleep "$POLL_SEC"
done

echo "== start =="
START_RESP="$(curl "${CURL_TLS[@]}" "${BASE_URL}/start-plc" -H "$(auth_header)")"
echo "$START_RESP"
if echo "$START_RESP" | grep -q 'ERROR_ALREADY_RUNNING'; then
  echo "PLC already running - treating as success"
fi

echo "== final status =="
curl "${CURL_TLS[@]}" "${BASE_URL}/status" -H "$(auth_header)"
echo

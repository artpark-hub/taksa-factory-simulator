#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: $0 <target_ip> <program_zip>
Example: $0 10.10.10.1 /home/plc-sim/Program1/program.zip

Environment overrides:
  COMPOSE_FILE   Path to docker-compose yaml (default: docker-compose.yaml)
  USER_NAME      OpenPLC username (default: admin)
  PASSWORD       OpenPLC password (default: admin123)
  INSECURE       1 to use curl -k (default: 1)
  TIMEOUT_SEC    Compilation timeout seconds (default: 300)
  POLL_SEC       Poll interval seconds (default: 1)
USAGE
}

if [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

TARGET_IP="$1"
ZIP_PATH="$2"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yaml}"
USER_NAME="${USER_NAME:-admin}"
PASSWORD="${PASSWORD:-admin123}"
INSECURE="${INSECURE:-1}"
TIMEOUT_SEC="${TIMEOUT_SEC:-300}"
POLL_SEC="${POLL_SEC:-1}"

if [[ "$INSECURE" == "1" ]]; then
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
    resp="$(curl "${CURL_TLS[@]}" --connect-timeout 2 "$url" || true)"
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

  echo "Login response: ${resp}"
  ACCESS_TOKEN="$(json_get_env access_token "$resp")"
  if [[ -z "$ACCESS_TOKEN" ]]; then
    echo "ERROR: login failed" >&2
    exit 1
  fi
}

echo "== target service =="
echo "$SERVICE_NAME"

echo "== removing old target container if present =="
docker stop "$SERVICE_NAME" 2>/dev/null || true
docker rm -f "$SERVICE_NAME" 2>/dev/null || true

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
  echo "$RESP"

  STATUS="$(json_get_env status "$RESP")"
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

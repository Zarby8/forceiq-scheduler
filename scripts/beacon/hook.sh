#!/bin/sh
# Fail open. This hook never calls Jev. It redacts, then optionally forwards
# only the redacted payload to beacon-hooks.
set +e
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd) || {
  printf '%s\n' '{"continue":true}'
  exit 0
}

harness="cursor"
event="post-tool"
while [ $# -gt 0 ]; do
  case "$1" in
    --harness) harness="$2"; shift 2 ;;
    --event) event="$2"; shift 2 ;;
    *) shift ;;
  esac
done

redacted=$(mktemp)
node "$ROOT/scripts/beacon/capture.mjs" --harness "$harness" --event "$event" --redacted-out "$redacted"
code=$?

bin="${BEACON_HOOKS_BIN:-}"
if [ -z "$bin" ] && [ -x /tmp/beacon/bin/beacon-hooks ]; then
  bin="/tmp/beacon/bin/beacon-hooks"
fi

if [ "$code" -eq 0 ] && [ -s "$redacted" ] && [ -n "$bin" ] && [ -x "$bin" ]; then
  log="${BEACON_UPSTREAM_LOG:-/tmp/beacon/runtime.jsonl}"
  mkdir -p "$(dirname "$log")" 2>/dev/null
  response=$(
    BEACON_ENDPOINT_MODE=1 \
    BEACON_ORIGIN=cloud \
    BEACON_RUN_PROVIDER=cursor_cloud \
    BEACON_RUN_EPHEMERAL=true \
    BEACON_ENDPOINT_LOG="$log" \
    "$bin" --platform "$harness" "$event" < "$redacted" 2>/dev/null
  )
  rm -f "$redacted"
  if printf '%s' "$response" | grep -q '^{'; then
    printf '%s\n' "$response"
    exit 0
  fi
else
  rm -f "$redacted"
fi

printf '%s\n' '{"continue":true}'
exit 0

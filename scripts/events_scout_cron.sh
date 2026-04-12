#!/usr/bin/env bash
set -u -o pipefail

export TZ=America/New_York

REPO_DIR="/home/ryan/ryanclaw"
PROMPT_FILE="$REPO_DIR/prompts/dc_ai_events_scout_prompt.md"
ENV_FILE="$REPO_DIR/.env"
LOG_DIR="$HOME/logs/events_scout"
LOG_FILE="$LOG_DIR/run-$(date +%Y%m%d-%H%M%S).log"
CLAUDE_BIN="/home/ryan/.local/bin/claude"

mkdir -p "$LOG_DIR"

send_alert() {
  local code="$1"
  local context="$2"
  local ts host tail_log payload resp body

  if [[ -z "${SLACK_ALERTS_URL:-}" ]]; then
    echo "[$(date --iso-8601=seconds)] SLACK_ALERTS_URL not set; cannot send alert. code=$code context=$context" >> "$LOG_FILE"
    return
  fi

  ts="$(date --iso-8601=seconds)"
  host="$(hostname)"
  tail_log="$(tail -n 50 "$LOG_FILE" 2>/dev/null || echo "<log unavailable>")"

  payload=$(jq -n \
    --arg host "$host" \
    --arg ts "$ts" \
    --arg code "$code" \
    --arg context "$context" \
    --arg log "$LOG_FILE" \
    --arg tail "$tail_log" \
    '{text: ("*DC AI Events Scout cron FAILED*\nHost: " + $host + "\nTime: " + $ts + "\nExit code: " + $code + "\nContext: " + $context + "\nLog: " + $log + "\n\n```\n" + $tail + "\n```")}')

  resp=$(curl -sS -o /tmp/events_scout_alert_body.$$ -w "%{http_code}" \
    -X POST -H 'Content-type: application/json' \
    --data "$payload" \
    "$SLACK_ALERTS_URL" 2>>"$LOG_FILE") || resp="curl_failed"
  body="$(cat /tmp/events_scout_alert_body.$$ 2>/dev/null || true)"
  rm -f /tmp/events_scout_alert_body.$$

  if [[ "$resp" != "200" || "$body" != "ok" ]]; then
    echo "[$(date --iso-8601=seconds)] alert_delivery_failed: http=$resp body=$body" >> "$LOG_FILE"
  fi
}

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[$(date --iso-8601=seconds)] env file missing: $ENV_FILE" >> "$LOG_FILE"
  echo "env file missing: $ENV_FILE" >&2
  exit 2
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

cd "$REPO_DIR"

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "[$(date --iso-8601=seconds)] prompt file missing: $PROMPT_FILE" >> "$LOG_FILE"
  send_alert 3 "prompt_file_missing: $PROMPT_FILE"
  exit 3
fi

stdbuf -oL -eL "$CLAUDE_BIN" -p "Begin the DC AI Events Scout run now. Follow the system prompt end to end. Deliver to Slack via the configured webhook. Exit when the Slack POST confirms HTTP 200 with body ok, or when a failure has been logged per the prompt's rules." \
  --append-system-prompt-file "$PROMPT_FILE" \
  --permission-mode bypassPermissions \
  --no-session-persistence \
  --max-turns 60 \
  --output-format stream-json \
  --verbose \
  >> "$LOG_FILE" 2>&1
EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
  send_alert "$EXIT_CODE" "claude_p_nonzero_exit"
fi

exit "$EXIT_CODE"

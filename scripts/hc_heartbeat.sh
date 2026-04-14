#!/usr/bin/env bash
# Path 1 of Principle IV — Healthchecks.io heartbeat from the home server.
# Missed pings trigger an SMS/email alert through Healthchecks.io itself.
#
# Suggested cron (every 5 minutes):
#   */5 * * * * /home/ryan/ryanclaw/scripts/hc_heartbeat.sh
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "env file missing: $ENV_FILE (see .env.example)" >&2
  exit 2
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if [[ -z "${HC_HEARTBEAT_URL:-}" ]]; then
  echo "HC_HEARTBEAT_URL not set (see .env.example)" >&2
  exit 3
fi

exec curl -fsS -m 10 --retry 3 --retry-connrefused -o /dev/null "$HC_HEARTBEAT_URL"

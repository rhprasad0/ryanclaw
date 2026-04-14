#!/usr/bin/env python3
"""Path 2 of Principle IV — post a synthetic ping to #sandbox, confirm the
webhook returned 200/ok, then ping Healthchecks.io. Failures post to #ops."""
from __future__ import annotations

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib import error, request

REPO_ROOT = Path(__file__).resolve().parent.parent
ENV_FILE = REPO_ROOT / ".env"
REQUIRED_ENV = (
    "SLACK_SANDBOX_WEBHOOK_URL",
    "HC_SYNTHETIC_URL",
    "SLACK_OPS_WEBHOOK_URL",
)


def load_dotenv(path: Path) -> None:
    if not path.is_file():
        return
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def post_webhook(url: str, text: str) -> tuple[int, str]:
    req = request.Request(
        url,
        data=json.dumps({"text": text}).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with request.urlopen(req, timeout=10) as resp:
        body = resp.read().decode("utf-8", errors="replace").strip()
        return resp.status, body


def alert_ops(message: str) -> None:
    try:
        post_webhook(os.environ["SLACK_OPS_WEBHOOK_URL"], message)
    except error.URLError as exc:
        print(f"ops webhook POST also failed: {exc}", file=sys.stderr)


def hc_ping(url: str) -> None:
    try:
        with request.urlopen(url, timeout=10) as resp:
            resp.read()
    except error.URLError as exc:
        print(f"hc ping failed: {exc}", file=sys.stderr)


def main() -> int:
    load_dotenv(ENV_FILE)
    missing = [k for k in REQUIRED_ENV if not os.environ.get(k)]
    if missing:
        print(
            f"missing env: {', '.join(missing)} (see .env.example)", file=sys.stderr
        )
        return 2

    ts = datetime.now(timezone.utc).isoformat(timespec="seconds")
    token = f"synth-check-{ts}"

    try:
        status, body = post_webhook(
            os.environ["SLACK_SANDBOX_WEBHOOK_URL"], token
        )
    except error.URLError as exc:
        msg = f"synthetic check: #sandbox webhook POST failed: {exc}"
        print(msg, file=sys.stderr)
        alert_ops(msg)
        return 3

    if status != 200 or body != "ok":
        msg = (
            f"synthetic check: #sandbox webhook returned status={status} "
            f"body={body!r} (expected 200 / 'ok')"
        )
        print(msg, file=sys.stderr)
        alert_ops(msg)
        return 4

    hc_ping(os.environ["HC_SYNTHETIC_URL"])
    print(f"posted {token}; hc pinged")
    return 0


if __name__ == "__main__":
    sys.exit(main())

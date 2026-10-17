#!/usr/bin/env bash
set -euo pipefail

: "${TELEGRAM_BOT_TOKEN:?Set TELEGRAM_BOT_TOKEN in Render Environment}"
: "${TELEGRAM_ALLOWED_USERS:?Set TELEGRAM_ALLOWED_USERS in Render Environment}"
: "${TELEGRAM_WEBHOOK_SECRET:?Set TELEGRAM_WEBHOOK_SECRET in Render Environment}"

# Render supplies RENDER_EXTERNAL_URL for web services. Telegram sends updates
# to this public URL; this avoids using Colab as a long-running bot host.
if [[ -z "${TELEGRAM_WEBHOOK_URL:-}" ]]; then
  : "${RENDER_EXTERNAL_URL:?RENDER_EXTERNAL_URL is required for webhook mode}"
  export TELEGRAM_WEBHOOK_URL="${RENDER_EXTERNAL_URL%/}/telegram"
fi

# Render's web-service port defaults to 10000. Hermes needs to listen on it.
export TELEGRAM_WEBHOOK_PORT="${PORT:-10000}"
export MUSE_CODE_SUB_CREDENTIALS="${MUSE_CODE_SUB_CREDENTIALS:-/etc/secrets/muse-code-sub.json}"

if [[ ! -s "$MUSE_CODE_SUB_CREDENTIALS" ]]; then
  echo "Missing Muse Code credentials file: $MUSE_CODE_SUB_CREDENTIALS" >&2
  echo "In Render > Environment > Secret Files, add muse-code-sub.json." >&2
  exit 1
fi

mkdir -p "$HERMES_HOME"
cat > "$HERMES_HOME/config.yaml" <<'YAML'
model:
  provider: muse-code
  default: muse-spark-1.3
YAML

exec /root/.local/bin/hermes gateway

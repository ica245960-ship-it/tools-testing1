# Hermes + Gemini Web API + Telegram on Render

Template to run Hermes Agent and `gemini-web2api-go` in one Render Docker Web Service. The generated Hermes config uses `model.default` for the selected model, as required by the current Hermes config schema. Hermes uses the local OpenAI-compatible endpoint; Nginx routes Telegram webhook traffic to Hermes and `/admin` + `/v1` to Gemini.

> Important: `gemini-web2api-go` is an unofficial reverse proxy for Gemini Web, not Google's official API. Using Google session cookies may breach service terms or trigger account restrictions. Use only an account/session you control and understand the risk. Never put cookies in GitHub or logs. Do not reuse any cookie that was pasted into a chat. This template does not contain or upload cookies.

## Files

- `Dockerfile` — extends the official Hermes Agent image and copies the Gemini Web API binary from its published container image.
- `docker/cont-init.d/03-app-config` — validates deployment secrets, writes Hermes custom-provider config, and prepares Nginx.
- `docker/s6-rc.d/*` — supervised Gemini API and Nginx services.
- `render.yaml` — Render Blueprint starter.

## Required Render environment variables

Set these under the Render service's **Environment** tab. Do not store any secret in a repository.

| Key | Value |
|---|---|
| `TELEGRAM_BOT_TOKEN` | Fresh bot token from BotFather. Rotate the token previously pasted into chat. |
| `TELEGRAM_ALLOWED_USERS` | Your numeric Telegram user ID, e.g. `123456789` |
| `TELEGRAM_WEBHOOK_URL` | Full public service URL plus `/telegram`, e.g. `https://YOUR-SERVICE.onrender.com/telegram` |
| `TELEGRAM_WEBHOOK_SECRET` | Random secret, ideally 64 hexadecimal characters |
| `GEMINI_API_KEY` | A new random secret used by Hermes and the Gemini backend. Use hex characters only. |
| `GEMINI_ADMIN_TOKEN` | A separate random secret used to protect the Gemini admin dashboard. |
| `SQL_DSN` | Strongly recommended PostgreSQL DSN for durable Cookie Pool/account data. If blank, the service falls back to local SQLite, which can be lost on redeploy/restart on Render Free. |
| `GEMINI_MODEL` | `gemini-3.1-pro` (or another exact model ID returned by `/v1/models`) |

Generate the three random secrets locally or in a Colab cell (do not paste them into chat):

```python
import secrets
print("TELEGRAM_WEBHOOK_SECRET=", secrets.token_hex(32))
print("GEMINI_API_KEY=", secrets.token_hex(32))
print("GEMINI_ADMIN_TOKEN=", secrets.token_hex(32))
```

Use the output values in the Render Environment page. Do not expose them in GitHub. If a value was posted in a chat or public page, rotate it.

### Create a PostgreSQL database

For reliable Cookie Pool persistence, use a PostgreSQL provider compatible with `gemini-web2api-go` and paste its PostgreSQL connection URL into `SQL_DSN`. The project supports `SQL_DSN` for PostgreSQL and creates its schema automatically. Make sure the password is URL-encoded if it contains reserved URL characters. A Render Free Postgres database has a limited lifetime, so check its current plan terms before relying on it long-term. Without `SQL_DSN`, SQLite is written at `/opt/data/gemini.db`; Render Free does not provide durable local disks.

## Deploy

1. Create a new private GitHub repository and upload all files from this folder. Do not upload cookies, API keys, tokens, `.env` files, or database files.
2. In Render, create a **Web Service** from that repository with the Docker runtime. You can use the Blueprint from `render.yaml`, or create the service manually.
3. Set all required environment variables above. Choose a unique service name; after Render assigns the actual URL, set `TELEGRAM_WEBHOOK_URL` to `https://<actual-service-host>/telegram` exactly (no extra trailing slash after `telegram`).
4. Ensure `TELEGRAM_WEBHOOK_PORT=8443` and `HERMES_GATEWAY_BOOTSTRAP_STATE=running` are set (the Blueprint includes them).
5. Deploy. Check Render logs for `Connected to Telegram (webhook mode)`, the Gemini backend listening on port 8083, and successful Nginx startup.
6. Visit `https://<actual-service-host>/healthz`. It should return `ok`.
7. Open `https://<actual-service-host>/admin/` and authenticate with `GEMINI_ADMIN_TOKEN`. Import a **fresh** Gemini cookie session through Cookie Pool if you intend to use a cookie-backed Pro model. The cookie is not copied from Colab automatically; the Render service has its own database. Avoid reusing any cookie that has already been exposed.
8. Test from Telegram by sending your bot a message. If `gemini-3.1-pro` is not shown by `https://<actual-service-host>/v1/models`, change `GEMINI_MODEL` to an exact ID from that list and redeploy.

## How routing works

- `https://<host>/telegram` → Hermes Telegram webhook listener on `127.0.0.1:8443`.
- `https://<host>/admin/` and `https://<host>/v1/...` → Gemini Web API on local port `8083`.
- `https://<host>/healthz` → Nginx health response for Render.

Gemini admin access is protected by `GEMINI_ADMIN_TOKEN`; API calls are protected by `GEMINI_API_KEY`. Keep both secret.

## Limits / persistence

- Render Free web services sleep after inactivity and can cold-start when a webhook arrives. Telegram may retry or a first response can be delayed; this is not a reliable 24/7 service. Use a paid always-on instance if reliable response times matter.
- Render Free has no durable local disk. Use `SQL_DSN` for the Gemini Cookie Pool and request metadata. Hermes conversation/session memory and its config are regenerated at startup in this free-tier template; durable Hermes state requires a persistent disk/paid deployment or a deliberate external backup strategy.
- This template configures a custom OpenAI-compatible provider. It does not provide official Gemini API access. For official Google API usage, use Google's API and a supported Hermes provider instead.

## Troubleshooting

- **Build error fetching backend image**: check whether `ghcr.io/zexadev/gemini-web2api-go:latest` is reachable and retry the deploy.
- **Service exits at startup**: verify every required variable is set, especially `TELEGRAM_WEBHOOK_URL` ending `/telegram` and valid secrets.
- **Telegram doesn't answer**: verify `TELEGRAM_ALLOWED_USERS` matches your numeric user ID, check logs for webhook-mode startup, and confirm `TELEGRAM_WEBHOOK_URL` matches the current Render URL.
- **Model unavailable**: inspect `/v1/models` and set `GEMINI_MODEL` to a listed exact model ID. Some model IDs require a valid cookie in Cookie Pool.
- **Cookie Pool empty after redeploy**: configure `SQL_DSN`; SQLite in the container is not durable on Render Free.

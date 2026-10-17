# Hermes + Muse Code + Telegram (Render webhook starter)

This starter is intended for a Render **Web Service** using webhook mode. It is not a VPS setup and does not run the Telegram gateway inside Google Colab.

## Before deploying

1. In Google Colab, install Hermes and the Muse Code plugin, complete the Muse Code login, and test a one-shot response. See the instructions in the ChatGPT answer that came with this package.
2. Download the generated `muse-code-sub.json` credential file from Colab. Do not print its contents in notebook output, put it in a public repository, or share it in chat.
3. Create a private or public GitHub repository and upload only `Dockerfile`, `start.sh`, and this README. **Never upload `muse-code-sub.json` or any `.env` file to GitHub.**
4. In Render, create a **Web Service** from that repository and choose the **Free** plan to test.
5. In Render > Environment > Secret Files, create a secret file named exactly `muse-code-sub.json`; paste the JSON file's contents into the secret-file editor.
6. In Render > Environment > Environment Variables, add:
   - `TELEGRAM_BOT_TOKEN` = token from @BotFather
   - `TELEGRAM_ALLOWED_USERS` = your numeric Telegram user ID
   - `TELEGRAM_WEBHOOK_SECRET` = a random secret, e.g. 64 hexadecimal characters
   - Optional: `MUSE_CODE_SUB_CREDENTIALS` = `/etc/secrets/muse-code-sub.json`

The service derives `TELEGRAM_WEBHOOK_URL` from Render's `RENDER_EXTERNAL_URL`, with the path `/telegram`, and listens on Render's `PORT` (default 10000).

## Limitations

Render's free Web Services can sleep after inactivity, so replies can be delayed during cold starts. Free instances have limited memory and ephemeral local storage; sessions, logs, and local agent memory may not survive a restart. This is a starter configuration, not a guarantee of 24/7 availability. Check current provider and platform terms before deployment.

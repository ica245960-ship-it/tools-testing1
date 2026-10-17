# Gemini Web API backend binary comes from its published image.
ARG GEMINI_IMAGE=ghcr.io/zexadev/gemini-web2api-go:latest
FROM ${GEMINI_IMAGE} AS gemini_backend

# Official Hermes image includes the Telegram adapter and its dependencies.
FROM nousresearch/hermes-agent:latest
USER root

RUN apt-get -o Acquire::Retries=3 update \
    && apt-get -o Acquire::Retries=3 install -y --no-install-recommends \
       nginx gettext-base ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf

COPY --from=gemini_backend /app/gemini-web2api /usr/local/bin/gemini-web2api
COPY docker/nginx/default.conf.template /etc/nginx/hermes-gemini.conf.template
COPY docker/cont-init.d/03-app-config /etc/cont-init.d/03-app-config
COPY docker/s6-rc.d/gemini-api/type /etc/s6-overlay/s6-rc.d/gemini-api/type
COPY docker/s6-rc.d/gemini-api/run /etc/s6-overlay/s6-rc.d/gemini-api/run
COPY docker/s6-rc.d/nginx/type /etc/s6-overlay/s6-rc.d/nginx/type
COPY docker/s6-rc.d/nginx/run /etc/s6-overlay/s6-rc.d/nginx/run

RUN chmod 0755 /etc/cont-init.d/03-app-config \
    /etc/s6-overlay/s6-rc.d/gemini-api/run \
    /etc/s6-overlay/s6-rc.d/nginx/run \
    && mkdir -p /etc/s6-overlay/s6-rc.d/user/contents.d \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/gemini-api \
             /etc/s6-overlay/s6-rc.d/user/contents.d/nginx

ENV HERMES_HOME=/opt/data \
    TELEGRAM_WEBHOOK_PORT=8443 \
    HERMES_GATEWAY_BOOTSTRAP_STATE=running

# Keep the official Hermes entrypoint/s6 supervision. Gateway uses Telegram webhook mode.
CMD ["gateway", "run"]

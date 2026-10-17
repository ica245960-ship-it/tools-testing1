FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HERMES_HOME=/opt/hermes-data
ENV PATH=/root/.local/bin:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates coreutils curl git tar python3 python3-venv \
    build-essential libffi-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh -o /tmp/hermes-install.sh \
    && bash /tmp/hermes-install.sh --non-interactive \
    && rm -f /tmp/hermes-install.sh

RUN /root/.local/bin/hermes plugins install TheStreamCode/hermes-muse-code --enable

COPY start.sh /usr/local/bin/start.sh
RUN chmod 755 /usr/local/bin/start.sh

EXPOSE 10000
CMD ["/usr/local/bin/start.sh"]

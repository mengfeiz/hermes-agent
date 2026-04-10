FROM debian:13.4

# Disable Python stdout buffering to ensure logs are printed immediately
# UV_SYSTEM_PYTHON: install into Debian's system Python (no venv) for ENTRYPOINT
ENV PYTHONUNBUFFERED=1 \
    UV_SYSTEM_PYTHON=1

# Install system dependencies in one layer, clear APT cache
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential nodejs npm python3 python3-pip ripgrep ffmpeg gcc python3-dev libffi-dev && \
    rm -rf /var/lib/apt/lists/*

COPY . /opt/hermes
WORKDIR /opt/hermes

# Install Python and Node dependencies in one layer, no cache.
# Plain pip hits resolution-too-deep on the fat .[all] graph (PyPI backtracking); uv resolves it quickly.
RUN pip install --no-cache-dir --break-system-packages "uv>=0.6.0" && \
    uv pip install --system --break-system-packages --no-cache -e ".[all]" && \
    npm install --prefer-offline --no-audit && \
    npx playwright install --with-deps chromium --only-shell && \
    cd /opt/hermes/scripts/whatsapp-bridge && \
    npm install --prefer-offline --no-audit && \
    npm cache clean --force

WORKDIR /opt/hermes
RUN chmod +x /opt/hermes/docker/entrypoint.sh

ENV HERMES_HOME=/opt/data
ENTRYPOINT [ "/opt/hermes/docker/entrypoint.sh" ]

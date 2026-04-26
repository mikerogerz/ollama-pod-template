FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

# Set environment variables
# This ensures Python output is immediately visible in logs
ENV PYTHONUNBUFFERED=1

# Set the working directory
WORKDIR /app

# Set environment variables for Ollama
ENV OLLAMA_HOST=127.0.0.1:11434
ENV OLLAMA_MODELS=/root/.ollama/models
ENV OLLAMA_NUM_PARALLEL=1
ENV OLLAMA_MAX_LOADED_MODELS=1
ENV OLLAMA_CONTEXT_LENGTH=32768
ENV OLLAMA_NO_CLOUD=1
ENV OLLAMA_KEEP_ALIVE=-1
ENV OLLAMA_DEBUG=1

# API key will be provided via RunPod environment variable
# Set API_KEY="sk-your-token-here" in your RunPod template

RUN apt-get update --yes && \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
    lshw \
    zstd \
    curl \
    debian-keyring \
    debian-archive-keyring \
    apt-transport-https

# Install Caddy
RUN curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list \
    && apt-get update --yes \
    && apt-get install --yes caddy \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | OLLAMA_VERSION=0.21.2 sh

# Create necessary directories
RUN mkdir -p /root/.ollama/models /etc/caddy

# Expose Ollama API port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 CMD curl -f http://localhost:8080/health || exit 1

COPY Caddyfile /etc/caddy/Caddyfile
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh
CMD ["/app/run.sh"]
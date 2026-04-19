FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

# Set environment variables
# This ensures Python output is immediately visible in logs
ENV PYTHONUNBUFFERED=1

# Set the working directory
WORKDIR /app

# Set environment variables for Ollama
ENV OLLAMA_HOST=0.0.0.0:11434
ENV OLLAMA_MODELS=/root/.ollama/models
ENV OLLAMA_NUM_PARALLEL=1
ENV OLLAMA_MAX_LOADED_MODELS=1
ENV OLLAMA_CONTEXT_LENGTH=32768
ENV OLLAMA_NO_CLOUD=1

RUN apt-get update --yes && \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
        lshw \
        zstd \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | OLLAMA_VERSION=0.21.0 sh

# Create necessary directories
RUN mkdir -p /root/.ollama/models

# Expose Ollama API port
EXPOSE 11434

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 CMD curl -f http://localhost:11434/api/tags || exit 1

COPY . /app
RUN chmod +x /app/run.sh
CMD ["/app/run.sh"]
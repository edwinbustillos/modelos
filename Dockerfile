# Multi-stage build for Ollama with UI
FROM ollama/ollama:latest as ollama-base

# Install dependencies
USER root
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /app/models /app/scripts
WORKDIR /app

# Copy scripts first
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Set up Ollama user and permissions
RUN chown -R ollama:ollama /app
USER ollama

# Expose Ollama port
EXPOSE 11434

# Start Ollama server
CMD ["/bin/bash", "/app/scripts/start-ollama.sh"]
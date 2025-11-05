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
RUN mkdir -p /app/models
WORKDIR /app

# Copy unified script
COPY ollama.sh /app/
RUN chmod +x /app/ollama.sh

# Expose Ollama port
EXPOSE 11434

# Start Ollama server
CMD ["ollama", "serve"]
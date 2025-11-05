#!/bin/bash

echo "🚀 Iniciando Ollama Server..."

# Start Ollama server in background
ollama serve &
OLLAMA_PID=$!

# Wait for Ollama to be ready
echo "⏳ Aguardando Ollama ficar disponível..."
sleep 10

# Function to check if Ollama is running
wait_for_ollama() {
    while ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; do
        echo "⏳ Aguardando Ollama..."
        sleep 2
    done
    echo "✅ Ollama está rodando!"
}

wait_for_ollama

# Import GGUF models if they exist
if [ -d "/app/models" ] && [ "$(ls -A /app/models/*.gguf 2>/dev/null)" ]; then
    echo "📦 Importando modelos GGUF..."
    /app/scripts/import-models.sh
else
    echo "ℹ️  Nenhum modelo GGUF encontrado em /app/models"
    echo "📋 Você pode adicionar modelos .gguf na pasta models/ e reiniciar o container"
fi

# List available models
echo "📋 Modelos disponíveis:"
ollama list

echo "🌐 Ollama está rodando em http://localhost:11434"
echo "🎨 Interface Web disponível em http://localhost:3000"

# Keep the container running
wait $OLLAMA_PID
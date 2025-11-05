#!/bin/bash

echo "🔄 Importando modelos GGUF para Ollama..."

# Directory containing GGUF models
MODELS_DIR="/app/models"

# Check if models directory exists
if [ ! -d "$MODELS_DIR" ]; then
    echo "❌ Diretório de modelos não encontrado: $MODELS_DIR"
    exit 1
fi

# Process each GGUF file
for gguf_file in "$MODELS_DIR"/*.gguf; do
    if [ -f "$gguf_file" ]; then
        # Extract filename without extension
        filename=$(basename "$gguf_file" .gguf)
        
        # Convert filename to lowercase and replace special characters
        model_name=$(echo "$filename" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9.-]/-/g')
        
        echo "📥 Importando: $filename -> $model_name"
        
        # Create Modelfile for this GGUF
        cat > "/tmp/Modelfile-$model_name" << EOF
FROM $gguf_file

TEMPLATE """{{ if .System }}<|start_header_id|>system<|end_header_id|>

{{ .System }}<|eot_id|>{{ end }}{{ if .Prompt }}<|start_header_id|>user<|end_header_id|>

{{ .Prompt }}<|eot_id|>{{ end }}<|start_header_id|>assistant<|end_header_id|>

{{ .Response }}<|eot_id|>"""

PARAMETER stop "<|start_header_id|>"
PARAMETER stop "<|end_header_id|>"
PARAMETER stop "<|eot_id|>"
PARAMETER stop "<|reserved_special_token"
EOF

        # Create the model in Ollama
        if ollama create "$model_name" -f "/tmp/Modelfile-$model_name"; then
            echo "✅ Modelo $model_name criado com sucesso!"
        else
            echo "❌ Erro ao criar modelo $model_name"
        fi
        
        # Clean up temporary Modelfile
        rm -f "/tmp/Modelfile-$model_name"
    fi
done

echo "🎉 Importação de modelos concluída!"
echo "📋 Para listar modelos disponíveis, use: ollama list"
#!/bin/bash

echo "🛑 Parando Ollama + WebUI..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to use docker-compose or docker compose
docker_compose() {
    if command -v docker-compose &> /dev/null; then
        docker-compose "$@"
    else
        docker compose "$@"
    fi
}

# Stop services
print_status "Parando containers..."
if docker_compose down; then
    print_success "✅ Containers parados com sucesso!"
else
    echo -e "${RED}[ERROR]${NC} Erro ao parar containers"
    exit 1
fi

# Option to remove volumes (data)
read -p "Deseja remover os dados armazenados? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Removendo volumes de dados..."
    docker_compose down -v
    print_success "✅ Dados removidos!"
fi

print_success "🎉 Ollama + WebUI parado!"
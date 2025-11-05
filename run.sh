#!/bin/bash

echo "🐳 Ollama + WebUI Setup"
echo "======================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker não está instalado. Instale o Docker primeiro."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose não está disponível. Instale o Docker Compose primeiro."
    exit 1
fi

# Function to use docker-compose or docker compose
docker_compose() {
    if command -v docker-compose &> /dev/null; then
        docker-compose "$@"
    else
        docker compose "$@"
    fi
}

# Create models directory if it doesn't exist
if [ ! -d "models" ]; then
    print_status "Criando diretório models/"
    mkdir -p models
fi

# Copy GGUF files to models directory
if ls *.gguf 1> /dev/null 2>&1; then
    print_status "Copiando arquivos .gguf para models/"
    cp *.gguf models/
    print_success "Modelos copiados para models/"
else
    print_warning "Nenhum arquivo .gguf encontrado no diretório atual"
    print_status "Você pode adicionar arquivos .gguf na pasta models/ manualmente"
fi

# Make scripts executable
chmod +x scripts/*.sh

print_status "Construindo e iniciando containers..."

# Build and start services
if docker_compose up --build -d; then
    print_success "Containers iniciados com sucesso!"
    echo ""
    echo "🌐 Serviços disponíveis:"
    echo "   • Ollama API: http://localhost:11434"
    echo "   • Web UI: http://localhost:3000"
    echo ""
    echo "📋 Comandos úteis:"
    echo "   • Ver logs: docker-compose logs -f"
    echo "   • Parar serviços: docker-compose down"
    echo "   • Reiniciar: docker-compose restart"
    echo ""
    print_status "Aguardando serviços ficarem disponíveis..."
    sleep 15
    
    # Check if services are running
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        print_success "✅ Ollama API está funcionando!"
    else
        print_warning "⚠️  Ollama API pode ainda estar inicializando..."
    fi
    
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        print_success "✅ Web UI está funcionando!"
    else
        print_warning "⚠️  Web UI pode ainda estar inicializando..."
    fi
    
    echo ""
    print_success "🎉 Setup concluído! Acesse http://localhost:3000 para usar a interface web."
else
    print_error "Erro ao iniciar containers"
    exit 1
fi
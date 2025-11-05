#!/bin/bash

# =============================================================================
# 🤖 Ollama + WebUI - Script Unificado
# =============================================================================
# Este script consolida todas as funcionalidades em um único arquivo:
# - Iniciar/parar serviços Docker
# - Importar modelos GGUF
# - Gerenciar containers Ollama + WebUI
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# 🎨 Output Functions
# =============================================================================

print_header() {
    echo -e "${PURPLE}===============================================${NC}"
    echo -e "${PURPLE}🤖 $1${NC}"
    echo -e "${PURPLE}===============================================${NC}"
}

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

print_step() {
    echo -e "${CYAN}➤${NC} $1"
}

# =============================================================================
# 🐳 Docker Functions  
# =============================================================================

check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker não está instalado. Instale o Docker primeiro."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose não está disponível. Instale o Docker Compose primeiro."
        exit 1
    fi
}

docker_compose() {
    if command -v docker-compose &> /dev/null; then
        docker-compose "$@"
    else
        docker compose "$@"
    fi
}

# =============================================================================
# 📦 Model Import Functions (for container use)
# =============================================================================

import_gguf_models() {
    local models_dir="${1:-/app/models}"
    
    print_step "🔄 Importando modelos GGUF para Ollama..."
    
    # Check if models directory exists
    if [ ! -d "$models_dir" ]; then
        print_error "Diretório de modelos não encontrado: $models_dir"
        return 1
    fi
    
    local model_count=0
    
    # Process each GGUF file
    for gguf_file in "$models_dir"/*.gguf; do
        if [ -f "$gguf_file" ]; then
            # Extract filename without extension
            local filename=$(basename "$gguf_file" .gguf)
            
            # Convert filename to lowercase and replace special characters
            local model_name=$(echo "$filename" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9.-]/-/g')
            
            print_step "📥 Importando: $filename -> $model_name"
            
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
                print_success "✅ Modelo $model_name criado com sucesso!"
                ((model_count++))
            else
                print_error "❌ Erro ao criar modelo $model_name"
            fi
            
            # Clean up temporary Modelfile
            rm -f "/tmp/Modelfile-$model_name"
        fi
    done
    
    if [ $model_count -eq 0 ]; then
        print_warning "ℹ️  Nenhum modelo GGUF encontrado em $models_dir"
    else
        print_success "🎉 $model_count modelo(s) importado(s) com sucesso!"
    fi
    
    print_step "📋 Para listar modelos disponíveis, use: ollama list"
}

# =============================================================================
# 🚀 Ollama Server Functions (for container use)
# =============================================================================

start_ollama_server() {
    print_step "🚀 Iniciando Ollama Server..."
    
    # Start Ollama server in background
    ollama serve &
    local ollama_pid=$!
    
    # Wait for Ollama to be ready
    print_step "⏳ Aguardando Ollama ficar disponível..."
    sleep 10
    
    # Function to check if Ollama is running
    local max_attempts=30
    local attempt=0
    
    while ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; do
        if [ $attempt -ge $max_attempts ]; then
            print_error "❌ Timeout: Ollama não ficou disponível após $max_attempts tentativas"
            return 1
        fi
        
        print_step "⏳ Aguardando Ollama... (tentativa $((attempt + 1))/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    print_success "✅ Ollama está rodando!"
    
    # Import GGUF models if they exist
    if [ -d "/app/models" ] && [ "$(ls -A /app/models/*.gguf 2>/dev/null)" ]; then
        import_gguf_models "/app/models"
    else
        print_warning "ℹ️  Nenhum modelo GGUF encontrado em /app/models"
        print_step "📋 Você pode adicionar modelos .gguf na pasta models/ e reiniciar o container"
    fi
    
    # List available models
    print_step "📋 Modelos disponíveis:"
    ollama list
    
    print_success "🌐 Ollama está rodando em http://localhost:11434"
    print_success "🎨 Interface Web disponível em http://localhost:3000"
    
    # Keep the container running
    wait $ollama_pid
}

# =============================================================================
# 🏃‍♂️ Main Docker Management Functions
# =============================================================================

setup_environment() {
    print_step "🔧 Configurando ambiente..."
    
    # Create models directory if it doesn't exist
    if [ ! -d "models" ]; then
        print_step "📁 Criando diretório models/"
        mkdir -p models
    fi
    
    # Copy GGUF files to models directory
    if ls *.gguf 1> /dev/null 2>&1; then
        print_step "📦 Copiando arquivos .gguf para models/"
        cp *.gguf models/
        print_success "✅ Modelos copiados para models/"
    else
        print_warning "⚠️  Nenhum arquivo .gguf encontrado no diretório atual"
        print_step "📋 Você pode adicionar arquivos .gguf na pasta models/ manualmente"
    fi
    
    # Make this script executable (in case it's not)
    chmod +x "$0"
}

start_services() {
    print_header "Ollama + WebUI Setup"
    
    check_docker
    setup_environment
    
    print_step "🐳 Construindo e iniciando containers..."
    
    # Build and start services
    if docker_compose up --build -d; then
        print_success "✅ Containers iniciados com sucesso!"
        echo ""
        echo "🌐 Serviços disponíveis:"
        echo "   • Ollama API: http://localhost:11434"
        echo "   • Web UI: http://localhost:3000"
        echo ""
        echo "📋 Comandos úteis:"
        echo "   • Ver logs: docker-compose logs -f"
        echo "   • Parar: $0 stop"
        echo "   • Reiniciar: $0 restart"
        echo ""
        
        print_step "⏳ Aguardando serviços ficarem disponíveis..."
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
        print_error "❌ Erro ao iniciar containers"
        exit 1
    fi
}

stop_services() {
    print_header "Parando Ollama + WebUI"
    
    check_docker
    
    # Stop services
    print_step "🛑 Parando containers..."
    if docker_compose down; then
        print_success "✅ Containers parados com sucesso!"
    else
        print_error "❌ Erro ao parar containers"
        exit 1
    fi
    
    # Option to remove volumes (data)
    echo ""
    read -p "💾 Deseja remover os dados armazenados? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "🗑️  Removendo volumes de dados..."
        docker_compose down -v
        print_success "✅ Dados removidos!"
    fi
    
    print_success "🎉 Ollama + WebUI parado!"
}

restart_services() {
    print_header "Reiniciando Ollama + WebUI"
    
    check_docker
    
    print_step "🔄 Reiniciando containers..."
    if docker_compose restart; then
        print_success "✅ Containers reiniciados com sucesso!"
        
        print_step "⏳ Aguardando serviços ficarem disponíveis..."
        sleep 10
        
        echo ""
        echo "🌐 Serviços disponíveis:"
        echo "   • Ollama API: http://localhost:11434"
        echo "   • Web UI: http://localhost:3000"
    else
        print_error "❌ Erro ao reiniciar containers"
        exit 1
    fi
}

show_logs() {
    print_header "Logs dos Serviços"
    
    check_docker
    
    print_step "📋 Exibindo logs dos containers..."
    docker_compose logs -f
}

show_status() {
    print_header "Status dos Serviços"
    
    check_docker
    
    print_step "📊 Status dos containers:"
    docker_compose ps
    
    echo ""
    print_step "🔍 Verificando conectividade..."
    
    # Check Ollama API
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        print_success "✅ Ollama API: http://localhost:11434 (funcionando)"
    else
        print_error "❌ Ollama API: http://localhost:11434 (não disponível)"
    fi
    
    # Check WebUI
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        print_success "✅ Web UI: http://localhost:3000 (funcionando)"
    else
        print_error "❌ Web UI: http://localhost:3000 (não disponível)"
    fi
}

# =============================================================================
# 📚 Help Function
# =============================================================================

show_help() {
    print_header "Ollama + WebUI - Ajuda"
    echo ""
    echo "💡 Uso: $0 [comando]"
    echo ""
    echo "📋 Comandos disponíveis:"
    echo "   start         🚀 Iniciar todos os serviços"
    echo "   stop          🛑 Parar todos os serviços"
    echo "   restart       🔄 Reiniciar todos os serviços"
    echo "   status        📊 Verificar status dos serviços"
    echo "   logs          📋 Exibir logs em tempo real"
    echo "   help          ❓ Exibir esta ajuda"
    echo ""
    echo "🌐 URLs dos serviços:"
    echo "   • Ollama API: http://localhost:11434"
    echo "   • Web UI: http://localhost:3000"
    echo ""
    echo "📂 Estrutura de arquivos:"
    echo "   • Modelos GGUF: ./models/"
    echo "   • Dados Ollama: volume Docker 'ollama_data'"
    echo "   • Dados WebUI: volume Docker 'open_webui_data'"
    echo ""
    echo "🔧 Comandos Docker úteis:"
    echo "   docker-compose ps          # Ver status"
    echo "   docker-compose logs -f     # Ver logs"
    echo "   docker-compose down -v     # Parar e remover dados"
}

# =============================================================================
# 🎯 Main Script Logic
# =============================================================================

main() {
    case "${1:-start}" in
        "start"|"run"|"up")
            start_services
            ;;
        "stop"|"down")
            stop_services
            ;;
        "restart"|"reboot")
            restart_services
            ;;
        "status"|"ps")
            show_status
            ;;
        "logs"|"log")
            show_logs
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        "container-start")
            # Função especial para uso dentro do container Docker
            start_ollama_server
            ;;
        "import-models")
            # Função especial para importar modelos
            import_gguf_models "${2:-/app/models}"
            ;;
        *)
            print_error "❌ Comando inválido: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
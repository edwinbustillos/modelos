# Modelos de IA

Este repositório contém modelos de inteligência artificial para uso local.

## 📥 Como fazer download

### Pré-requisitos

Para trabalhar com este repositório que usa Git LFS (Large File Storage), você precisará:

1. **Git** instalado em seu sistema
2. **Git LFS** instalado e configurado

### Instalação do Git LFS

Se você ainda não tem o Git LFS instalado:

```bash
# No macOS (usando Homebrew)
brew install git-lfs

# No Ubuntu/Debian
sudo apt install git-lfs

# No Windows
# Baixe de: https://git-lfs.github.io/
```

### Download do repositório

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/edwinbustillos/modelos.git
   cd modelos
   ```

2. **Inicialize o Git LFS (se necessário):**
   ```bash
   git lfs install
   ```

3. **Baixe os arquivos grandes:**
   ```bash
   git lfs pull
   ```

## 📁 Estrutura do Projeto

```
modelos/
├── 📄 README.md                    # Este arquivo
├── 🤖 llama3-small-Q3_K_S.gguf   # Modelo Llama 3 Small (104.33 MB)
├── 🐳 Dockerfile                   # Configuração Docker
├── 🐙 docker-compose.yml          # Orquestração de serviços
├── 🚀 ollama.sh                   # Script unificado (tudo em um!)
└── 📁 models/                     # Diretório para modelos (volume Docker)
```

## 🔧 Uso

### Opção 1: AI CLI (Novo! ⭐)

A maneira mais moderna de interagir com seus modelos locais - um CLI similar ao Claude Code:

```bash
# Instalação rápida
./install-ai-cli.sh

# Uso básico
./ai-cli chat "Hello, how are you?"
./ai-cli code "Create a Python sorting function"  
./ai-cli explain "What is machine learning?"
./ai-cli translate "Hello world" --to portuguese
./ai-cli review mycode.py

# Chat interativo
./ai-cli chat --interactive

# Com modelo específico
./ai-cli --model llama3.2 chat "Explain quantum physics"
```

**✨ Funcionalidades do AI CLI:**
- 💬 **Chat interativo** e por comando
- 🖥️ **Geração de código** com exemplos
- 📚 **Explicações detalhadas** de conceitos
- 🌐 **Tradução** para qualquer idioma
- 📄 **Resumos** de textos e arquivos
- 🔍 **Review automático** de código
- 🎨 **Interface colorida** e amigável

### Opção 2: Docker + WebUI

A maneira mais fácil de usar os modelos é com Docker + Ollama + Interface Web:

```bash
# Clone o repositório
git clone https://github.com/edwinbustillos/modelos.git
cd modelos

# Execute o setup automático
./ollama.sh start
```

Isso irá:
- 🐳 Construir e iniciar containers Docker
- 🤖 Configurar Ollama com os modelos GGUF  
- 🌐 Disponibilizar interface web em http://localhost:3000
- 📡 API Ollama em http://localhost:11434

**Comandos úteis:**
```bash
./ollama.sh start    # Iniciar tudo
./ollama.sh stop     # Parar serviços
./ollama.sh restart  # Reiniciar serviços
./ollama.sh import   # Importar modelos GGUF
./ollama.sh status   # Verificar status
./ollama.sh help     # Ajuda completa
```

### Opção 3: Uso Direto

Os arquivos `.gguf` são modelos quantizados que podem ser usados com:
- **llama.cpp**
- **Ollama**
- **LM Studio** 
- **GPT4All**
- Outras ferramentas compatíveis com o formato GGUF

## ⚠️ Observações importantes

- Este repositório usa Git LFS para gerenciar arquivos grandes
- Certifique-se de ter o Git LFS instalado antes de clonar
- O download pode demorar dependendo da sua conexão (arquivo de ~104 MB)
- Os modelos são fornecidos "como estão" para fins de pesquisa e desenvolvimento

## 📄 Licença

Consulte a documentação original dos modelos para informações sobre licenciamento.
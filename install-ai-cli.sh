#!/bin/bash

# =============================================================================
# AI CLI Installer
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}===============================================${NC}"
    echo -e "${PURPLE}🚀 $1${NC}"
    echo -e "${PURPLE}===============================================${NC}"
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
    echo -e "${BLUE}➤${NC} $1"
}

# Check if Python is installed
check_python() {
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is required but not installed."
        print_step "Install Python 3 and try again."
        exit 1
    fi
    
    python_version=$(python3 --version | cut -d' ' -f2)
    print_success "Python $python_version found"
}

# Install required Python packages
install_requirements() {
    print_step "Installing required Python packages..."
    
    # Create requirements.txt if it doesn't exist
    cat > requirements.txt << EOF
requests>=2.31.0
EOF
    
    # Try different installation methods
    if command -v pipx &> /dev/null; then
        print_step "Using pipx for installation..."
        if pipx install --editable .; then
            print_success "Python packages installed with pipx"
            return
        fi
    fi
    
    # Try pip with user flag
    if pip3 install --user -r requirements.txt; then
        print_success "Python packages installed to user directory"
    elif pip3 install --break-system-packages -r requirements.txt; then
        print_success "Python packages installed (system-wide)"
        print_warning "Used --break-system-packages flag"
    else
        print_warning "Could not install packages automatically"
        print_step "Please install manually: pip3 install --user requests"
        print_step "Or use pipx: brew install pipx && pipx install requests"
    fi
}

# Make CLI executable and create symlink
setup_cli() {
    print_step "Setting up AI CLI..."
    
    # Make the script executable
    chmod +x ai-cli.py
    
    # Get the current directory
    current_dir=$(pwd)
    
    # Create a wrapper script in /usr/local/bin if possible
    if [ -w "/usr/local/bin" ]; then
        cat > /usr/local/bin/ai-cli << EOF
#!/bin/bash
cd "$current_dir"
python3 "$current_dir/ai-cli.py" "\$@"
EOF
        chmod +x /usr/local/bin/ai-cli
        print_success "AI CLI installed to /usr/local/bin/ai-cli"
        print_success "You can now use 'ai-cli' from anywhere!"
    else
        # Create in ~/.local/bin
        mkdir -p ~/.local/bin
        cat > ~/.local/bin/ai-cli << EOF
#!/bin/bash
cd "$current_dir"
python3 "$current_dir/ai-cli.py" "\$@"
EOF
        chmod +x ~/.local/bin/ai-cli
        print_success "AI CLI installed to ~/.local/bin/ai-cli"
        
        # Check if ~/.local/bin is in PATH
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            print_warning "~/.local/bin is not in your PATH"
            print_step "Add this to your ~/.bashrc or ~/.zshrc:"
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
            print_step "Or use the full path: ~/.local/bin/ai-cli"
        else
            print_success "You can now use 'ai-cli' from anywhere!"
        fi
    fi
}

# Create configuration file
create_config() {
    print_step "Creating configuration file..."
    
    cat > ai-cli-config.json << EOF
{
    "default_model": "llama3-small-q3-k-s",
    "ollama_url": "http://localhost:11434",
    "stream_by_default": false,
    "max_tokens": 4000,
    "temperature": 0.7
}
EOF
    
    print_success "Configuration file created: ai-cli-config.json"
}

# Test installation
test_installation() {
    print_step "Testing installation..."
    
    # Start Ollama if not running
    if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        print_warning "Ollama is not running. Starting it..."
        if [ -f "ollama.sh" ]; then
            ./ollama.sh start
            sleep 10
        else
            print_error "Ollama is not running and ollama.sh not found"
            print_step "Please start Ollama manually: ./ollama.sh start"
            return
        fi
    fi
    
    # Test if ai-cli works
    if command -v ai-cli &> /dev/null; then
        if ai-cli models > /dev/null 2>&1; then
            print_success "AI CLI is working correctly!"
        else
            print_warning "AI CLI installed but may have connection issues"
        fi
    else
        print_warning "AI CLI installed but not in PATH"
        print_step "Try running: python3 ai-cli.py models"
    fi
}

main() {
    print_header "AI CLI Installation"
    
    check_python
    install_requirements
    setup_cli
    create_config
    test_installation
    
    echo ""
    print_header "Installation Complete!"
    echo ""
    print_success "🎉 AI CLI has been successfully installed!"
    echo ""
    echo "📋 Quick Start:"
    echo "   ai-cli chat \"Hello, how are you?\""
    echo "   ai-cli code \"Create a Python function to sort a list\""
    echo "   ai-cli explain \"What is machine learning?\""
    echo "   ai-cli chat --interactive"
    echo ""
    echo "🔧 Configuration:"
    echo "   Edit ai-cli-config.json to customize settings"
    echo ""
    echo "📚 Help:"
    echo "   ai-cli --help"
    echo "   ai-cli chat --help"
}

main "$@"
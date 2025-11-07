# AI CLI Examples

## 🚀 Quick Start

### Basic Chat
```bash
# Single question
ai-cli chat "What is the capital of Brazil?"

# Interactive chat session
ai-cli chat --interactive

# Chat with specific model
ai-cli chat "Explain quantum physics" --model llama3-small-q3-k-s
```

### Code Generation
```bash
# Generate Python code
ai-cli code "Create a Python function to calculate fibonacci sequence"

# Generate with streaming
ai-cli code "Write a REST API in Python using FastAPI" --stream

# JavaScript example
ai-cli code "Create a React component for a todo list"
```

### Code Review
```bash
# Review a Python file
ai-cli review app.py

# Review any code file
ai-cli review script.js
```

### Explanations
```bash
# Explain a concept
ai-cli explain "What is machine learning?"

# Explain code in a file
ai-cli explain complex_algorithm.py

# Explain with streaming
ai-cli explain "How does blockchain work?" --stream
```

### Translation
```bash
# Translate to Portuguese
ai-cli translate "Hello, how are you today?" --to portuguese

# Translate to Spanish
ai-cli translate "Good morning everyone" --to spanish

# Translate from file
ai-cli translate "$(cat document.txt)" --to french
```

### Summarization
```bash
# Summarize text
ai-cli summarize "Long text content here..."

# Summarize a file
ai-cli summarize document.txt

# Summarize with streaming
ai-cli summarize large_article.txt --stream
```

### Model Management
```bash
# List available models
ai-cli models

# Check which models are running
curl http://localhost:11434/api/tags
```

## 🎯 Advanced Usage

### Custom System Prompts (via interactive mode)
```bash
ai-cli chat --interactive
# Then use model-specific features in conversation
```

### Piping and File Processing
```bash
# Process file content
cat myfile.py | ai-cli code "Optimize this code"

# Chain commands
ai-cli code "Generate a sorting algorithm" > algorithm.py
ai-cli review algorithm.py
```

### Batch Processing
```bash
# Review multiple files
for file in *.py; do
    echo "Reviewing $file"
    ai-cli review "$file" > "review_$file.txt"
done
```

### Configuration Options
Edit `ai-cli-config.json`:
```json
{
    "default_model": "llama3-small-q3-k-s",
    "ollama_url": "http://localhost:11434",
    "stream_by_default": false,
    "max_tokens": 4000,
    "temperature": 0.7
}
```

## 🛠️ Development Workflows

### Code Development
```bash
# 1. Generate initial code
ai-cli code "Create a web scraper in Python" > scraper.py

# 2. Review the code
ai-cli review scraper.py

# 3. Get explanations
ai-cli explain scraper.py

# 4. Ask for improvements
ai-cli code "Improve this code to handle errors better: $(cat scraper.py)"
```

### Learning Workflow
```bash
# 1. Ask for explanation
ai-cli explain "What is Docker?"

# 2. Ask for practical example
ai-cli code "Show me a simple Dockerfile example"

# 3. Get more details
ai-cli explain "What are Docker layers?"
```

### Content Creation
```bash
# 1. Generate content
ai-cli chat "Write a technical blog post about AI" > blog_draft.md

# 2. Summarize for social media
ai-cli summarize blog_draft.md

# 3. Translate for international audience
ai-cli translate "$(cat blog_draft.md)" --to spanish > blog_es.md
```

## 🎨 Creative Uses

### Documentation
```bash
# Generate README for project
ai-cli code "Create a comprehensive README.md for a Python machine learning project"

# Document code
ai-cli code "Add detailed docstrings to this code: $(cat mymodule.py)"
```

### Problem Solving
```bash
# Debug issues
ai-cli explain "Why am I getting this error: $(python script.py 2>&1)"

# Get solutions
ai-cli code "Fix this Python error: ImportError: No module named 'requests'"
```

### Data Analysis
```bash
# Analyze data structure
ai-cli explain "$(head -20 data.csv)"

# Generate analysis code
ai-cli code "Create Python code to analyze this CSV data structure: $(head -5 data.csv)"
```

## 🔧 Tips and Tricks

### Aliases for Faster Usage
Add to your `.bashrc` or `.zshrc`:
```bash
alias ask="ai-cli chat"
alias code-help="ai-cli code"
alias explain="ai-cli explain"
alias review="ai-cli review"
alias ai-translate="ai-cli translate"
```

### Environment Variables
```bash
export AI_CLI_MODEL="llama3-small-q3-k-s"
export AI_CLI_STREAM=true
```

### Integration with Editors
#### VS Code
Create a VS Code task in `.vscode/tasks.json`:
```json
{
    "label": "AI Code Review",
    "type": "shell",
    "command": "ai-cli review ${file}"
}
```

#### Vim/Neovim
Add to your `.vimrc`:
```vim
" Send current file to AI for review
nnoremap <leader>ar :!ai-cli review %<CR>

" Explain current selection
vnoremap <leader>ae :!ai-cli explain<CR>
```

## 🚨 Troubleshooting

### Common Issues
```bash
# Ollama not running
ai-cli models  # Will show error if Ollama is down
./ollama.sh start  # Start Ollama

# Permission issues
chmod +x ai-cli.py
sudo chmod +x /usr/local/bin/ai-cli

# Python issues
pip3 install --upgrade requests
```

### Performance Tips
```bash
# Use streaming for long responses
ai-cli code "Create a complex web application" --stream

# Use specific models for different tasks
ai-cli chat "Quick question" --model tinyllama-1.1b-chat
ai-cli code "Complex algorithm" --model llama3-small-q3-k-s
```

## 📊 Model Comparison

| Model | Best For | Speed | Quality |
|-------|----------|-------|---------|
| tinyllama-1.1b-chat | Quick questions, simple tasks | Fast | Good |
| llama3-small-q3-k-s | General purpose, coding | Medium | Excellent |

Choose model based on your needs:
- Quick answers: `tinyllama-1.1b-chat`
- Code generation: `llama3-small-q3-k-s`
- Complex analysis: `llama3-small-q3-k-s`
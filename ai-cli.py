#!/usr/bin/env python3
"""
AI CLI - Command Line Interface for Local AI Models
Similar to Claude Code but using local Ollama models

Usage:
    ai-cli chat "Hello, how are you?"
    ai-cli code "Create a Python function to sort a list"
    ai-cli explain "What is machine learning?"
    ai-cli translate "Hello world" --to portuguese
    ai-cli summarize file.txt
    ai-cli review code.py
"""

import argparse
import json
import requests
import sys
import os
import subprocess
from pathlib import Path
from typing import Optional, Dict, List
import time

class AIClient:
    def __init__(self, base_url: str = "http://localhost:11434"):
        self.base_url = base_url
        self.default_model = "llama3-small-q3-k-s"
        
    def check_connection(self) -> bool:
        """Check if Ollama is running and accessible"""
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=5)
            return response.status_code == 200
        except:
            return False
    
    def list_models(self) -> List[Dict]:
        """Get list of available models"""
        try:
            response = requests.get(f"{self.base_url}/api/tags")
            if response.status_code == 200:
                return response.json().get("models", [])
            return []
        except:
            return []
    
    def chat(self, message: str, model: Optional[str] = None, system_prompt: Optional[str] = None) -> str:
        """Send a chat message to the model"""
        if not model:
            model = self.default_model
            
        payload = {
            "model": model,
            "prompt": message,
            "stream": False
        }
        
        if system_prompt:
            payload["system"] = system_prompt
            
        try:
            response = requests.post(
                f"{self.base_url}/api/generate",
                json=payload,
                timeout=120
            )
            
            if response.status_code == 200:
                return response.json().get("response", "No response received")
            else:
                return f"Error: {response.status_code} - {response.text}"
        except Exception as e:
            return f"Connection error: {e}"
    
    def chat_stream(self, message: str, model: Optional[str] = None, system_prompt: Optional[str] = None):
        """Send a chat message with streaming response"""
        if not model:
            model = self.default_model
            
        payload = {
            "model": model,
            "prompt": message,
            "stream": True
        }
        
        if system_prompt:
            payload["system"] = system_prompt
            
        try:
            response = requests.post(
                f"{self.base_url}/api/generate",
                json=payload,
                stream=True,
                timeout=120
            )
            
            for line in response.iter_lines():
                if line:
                    try:
                        data = json.loads(line)
                        if "response" in data:
                            yield data["response"]
                    except json.JSONDecodeError:
                        continue
                        
        except Exception as e:
            yield f"Connection error: {e}"

class AICLI:
    def __init__(self):
        self.client = AIClient()
        self.colors = {
            'blue': '\033[94m',
            'green': '\033[92m',
            'yellow': '\033[93m',
            'red': '\033[91m',
            'purple': '\033[95m',
            'cyan': '\033[96m',
            'white': '\033[97m',
            'end': '\033[0m',
            'bold': '\033[1m'
        }
    
    def colored(self, text: str, color: str) -> str:
        """Add color to text"""
        if not sys.stdout.isatty():
            return text
        return f"{self.colors.get(color, '')}{text}{self.colors['end']}"
    
    def print_header(self, text: str):
        """Print a colored header"""
        print(f"\n{self.colored('═' * 60, 'blue')}")
        print(f"{self.colored(f'🤖 AI CLI - {text}', 'bold')}")
        print(f"{self.colored('═' * 60, 'blue')}\n")
    
    def check_ollama_status(self) -> bool:
        """Check if Ollama is running"""
        if not self.client.check_connection():
            print(f"{self.colored('❌ Error:', 'red')} Ollama is not running or not accessible.")
            print(f"{self.colored('💡 Tip:', 'yellow')} Start Ollama with: ./ollama.sh start")
            return False
        return True
    
    def cmd_chat(self, args):
        """Interactive chat or single message"""
        if not self.check_ollama_status():
            return
            
        if args.message:
            # Single message mode
            self.print_header(f"Chat with {args.model}")
            print(f"{self.colored('👤 You:', 'green')} {args.message}")
            print(f"{self.colored('🤖 AI:', 'blue')}", end=" ", flush=True)
            
            if args.stream:
                response = ""
                for chunk in self.client.chat_stream(args.message, args.model):
                    print(chunk, end="", flush=True)
                    response += chunk
                print()
            else:
                response = self.client.chat(args.message, args.model)
                print(response)
        else:
            # Interactive mode
            self.print_header(f"Interactive Chat with {args.model}")
            print(f"{self.colored('Type /quit to exit, /help for commands', 'yellow')}\n")
            
            while True:
                try:
                    message = input(f"{self.colored('👤 You: ', 'green')}")
                    
                    if message.lower() in ['/quit', '/exit', '/q']:
                        print(f"{self.colored('👋 Goodbye!', 'yellow')}")
                        break
                    elif message.lower() == '/help':
                        self.show_interactive_help()
                        continue
                    elif message.lower() == '/clear':
                        os.system('clear' if os.name == 'posix' else 'cls')
                        continue
                    elif message.lower() == '/models':
                        self.list_models()
                        continue
                        
                    if not message.strip():
                        continue
                        
                    print(f"{self.colored('🤖 AI:', 'blue')}", end=" ", flush=True)
                    
                    if args.stream:
                        for chunk in self.client.chat_stream(message, args.model):
                            print(chunk, end="", flush=True)
                        print("\n")
                    else:
                        response = self.client.chat(message, args.model)
                        print(f"{response}\n")
                        
                except KeyboardInterrupt:
                    print(f"\n{self.colored('👋 Goodbye!', 'yellow')}")
                    break
    
    def cmd_code(self, args):
        """Code generation and assistance"""
        if not self.check_ollama_status():
            return
            
        system_prompt = """You are an expert programmer. Provide clean, well-commented code solutions. 
        Always include explanations of how the code works. Format code blocks properly with language markers."""
        
        self.print_header("Code Assistant")
        print(f"{self.colored('📝 Request:', 'green')} {args.prompt}")
        print(f"{self.colored('💻 AI Response:', 'blue')}\n")
        
        if args.stream:
            for chunk in self.client.chat_stream(args.prompt, args.model, system_prompt):
                print(chunk, end="", flush=True)
            print()
        else:
            response = self.client.chat(args.prompt, args.model, system_prompt)
            print(response)
    
    def cmd_explain(self, args):
        """Explain concepts or code"""
        if not self.check_ollama_status():
            return
            
        system_prompt = """You are a helpful teacher. Explain concepts clearly and thoroughly. 
        Use examples when helpful. Break down complex topics into understandable parts."""
        
        # Check if it's a file
        if os.path.isfile(args.topic):
            try:
                with open(args.topic, 'r', encoding='utf-8') as f:
                    content = f.read()
                prompt = f"Please explain this code:\n\n```\n{content}\n```"
            except Exception as e:
                print(f"{self.colored('❌ Error reading file:', 'red')} {e}")
                return
        else:
            prompt = f"Please explain: {args.topic}"
            
        self.print_header("Explanation")
        print(f"{self.colored('❓ Topic:', 'green')} {args.topic}")
        print(f"{self.colored('📚 Explanation:', 'blue')}\n")
        
        if args.stream:
            for chunk in self.client.chat_stream(prompt, args.model, system_prompt):
                print(chunk, end="", flush=True)
            print()
        else:
            response = self.client.chat(prompt, args.model, system_prompt)
            print(response)
    
    def cmd_translate(self, args):
        """Translate text"""
        if not self.check_ollama_status():
            return
            
        system_prompt = f"""You are a professional translator. Translate the given text to {args.to} accurately, 
        maintaining the original meaning and context. Provide only the translation unless asked otherwise."""
        
        self.print_header(f"Translation to {args.to}")
        print(f"{self.colored('🌐 Original:', 'green')} {args.text}")
        print(f"{self.colored('🔄 Translation:', 'blue')}\n")
        
        prompt = f"Translate this to {args.to}: {args.text}"
        
        if args.stream:
            for chunk in self.client.chat_stream(prompt, args.model, system_prompt):
                print(chunk, end="", flush=True)
            print()
        else:
            response = self.client.chat(prompt, args.model, system_prompt)
            print(response)
    
    def cmd_summarize(self, args):
        """Summarize text or files"""
        if not self.check_ollama_status():
            return
            
        system_prompt = """You are an expert at creating concise, informative summaries. 
        Capture the key points and main ideas while being clear and comprehensive."""
        
        # Check if it's a file
        if os.path.isfile(args.input):
            try:
                with open(args.input, 'r', encoding='utf-8') as f:
                    content = f.read()
                prompt = f"Please summarize this content:\n\n{content}"
                input_desc = f"File: {args.input}"
            except Exception as e:
                print(f"{self.colored('❌ Error reading file:', 'red')} {e}")
                return
        else:
            prompt = f"Please summarize: {args.input}"
            content = args.input
            input_desc = "Text input"
            
        self.print_header("Summary")
        print(f"{self.colored('📄 Input:', 'green')} {input_desc}")
        print(f"{self.colored('📝 Summary:', 'blue')}\n")
        
        if args.stream:
            for chunk in self.client.chat_stream(prompt, args.model, system_prompt):
                print(chunk, end="", flush=True)
            print()
        else:
            response = self.client.chat(prompt, args.model, system_prompt)
            print(response)
    
    def cmd_review(self, args):
        """Code review"""
        if not self.check_ollama_status():
            return
            
        system_prompt = """You are an experienced code reviewer. Analyze code for:
        - Bugs and potential issues
        - Performance improvements
        - Best practices
        - Security concerns
        - Code style and readability
        Provide constructive feedback with specific suggestions."""
        
        if not os.path.isfile(args.file):
            print(f"{self.colored('❌ Error:', 'red')} File not found: {args.file}")
            return
            
        try:
            with open(args.file, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"{self.colored('❌ Error reading file:', 'red')} {e}")
            return
            
        prompt = f"Please review this code and provide feedback:\n\n```\n{content}\n```"
        
        self.print_header(f"Code Review: {args.file}")
        print(f"{self.colored('🔍 Reviewing:', 'green')} {args.file}")
        print(f"{self.colored('📋 Review:', 'blue')}\n")
        
        if args.stream:
            for chunk in self.client.chat_stream(prompt, args.model, system_prompt):
                print(chunk, end="", flush=True)
            print()
        else:
            response = self.client.chat(prompt, args.model, system_prompt)
            print(response)
    
    def list_models(self):
        """List available models"""
        self.print_header("Available Models")
        
        models = self.client.list_models()
        if not models:
            print(f"{self.colored('❌ No models found or Ollama not running', 'red')}")
            return
            
        print(f"{self.colored('Model Name', 'bold'):40} {self.colored('Size', 'bold'):10} {self.colored('Modified', 'bold')}")
        print(f"{self.colored('-' * 70, 'blue')}")
        
        for model in models:
            name = model.get('name', 'Unknown')
            size = self.format_size(model.get('size', 0))
            modified = model.get('modified_at', 'Unknown')[:19].replace('T', ' ')
            
            print(f"{self.colored(name, 'green'):40} {size:10} {modified}")
    
    def format_size(self, bytes_size: int) -> str:
        """Format bytes to human readable format"""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if bytes_size < 1024.0:
                return f"{bytes_size:.1f}{unit}"
            bytes_size /= 1024.0
        return f"{bytes_size:.1f}TB"
    
    def show_interactive_help(self):
        """Show help for interactive mode"""
        print(f"\n{self.colored('📋 Interactive Commands:', 'yellow')}")
        print(f"{self.colored('/quit, /exit, /q', 'green'):20} - Exit the chat")
        print(f"{self.colored('/help', 'green'):20} - Show this help")
        print(f"{self.colored('/clear', 'green'):20} - Clear screen")
        print(f"{self.colored('/models', 'green'):20} - List available models")
        print()

def main():
    cli = AICLI()
    
    parser = argparse.ArgumentParser(
        description="AI CLI - Local AI Assistant similar to Claude Code",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  ai-cli chat "Hello, how are you?"
  ai-cli chat --interactive --model llama3-small-q3-k-s
  ai-cli code "Create a Python function to calculate fibonacci"
  ai-cli explain "What is recursion?"
  ai-cli translate "Bonjour le monde" --to english
  ai-cli summarize document.txt
  ai-cli review mycode.py
  ai-cli models
        """
    )
    
    parser.add_argument('--model', '-m', default='llama3-small-q3-k-s', 
                       help='Model to use (default: llama3-small-q3-k-s)')
    parser.add_argument('--stream', '-s', action='store_true',
                       help='Stream response in real-time')
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Chat command
    chat_parser = subparsers.add_parser('chat', help='Chat with AI')
    chat_parser.add_argument('message', nargs='?', help='Message to send (optional for interactive mode)')
    chat_parser.add_argument('--interactive', '-i', action='store_true',
                            help='Start interactive chat session')
    
    # Code command
    code_parser = subparsers.add_parser('code', help='Code generation and assistance')
    code_parser.add_argument('prompt', help='Code request or question')
    
    # Explain command
    explain_parser = subparsers.add_parser('explain', help='Explain concepts or code')
    explain_parser.add_argument('topic', help='Topic to explain or file to analyze')
    
    # Translate command
    translate_parser = subparsers.add_parser('translate', help='Translate text')
    translate_parser.add_argument('text', help='Text to translate')
    translate_parser.add_argument('--to', required=True, help='Target language')
    
    # Summarize command
    summarize_parser = subparsers.add_parser('summarize', help='Summarize text or files')
    summarize_parser.add_argument('input', help='Text to summarize or file path')
    
    # Review command
    review_parser = subparsers.add_parser('review', help='Code review')
    review_parser.add_argument('file', help='File to review')
    
    # Models command
    models_parser = subparsers.add_parser('models', help='List available models')
    
    args = parser.parse_args()
    
    if not args.command:
        # Default to interactive chat
        args.command = 'chat'
        args.message = None
        args.interactive = True
    
    # Execute command
    if args.command == 'chat':
        cli.cmd_chat(args)
    elif args.command == 'code':
        cli.cmd_code(args)
    elif args.command == 'explain':
        cli.cmd_explain(args)
    elif args.command == 'translate':
        cli.cmd_translate(args)
    elif args.command == 'summarize':
        cli.cmd_summarize(args)
    elif args.command == 'review':
        cli.cmd_review(args)
    elif args.command == 'models':
        cli.list_models()

if __name__ == "__main__":
    main()
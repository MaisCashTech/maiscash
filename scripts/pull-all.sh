#!/bin/bash

# Script para atualizar todos os submodules do workspace MaisCash
# Autor: MaisCashTech Automation
# Uso: ./scripts/pull-all.sh

set -e  # Exit on any error

echo "🚀 MaisCash Workspace - Atualizando todos os projetos..."
echo "=================================================="

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

# Update main repository
print_status "Atualizando repositório principal..."
git pull origin main || print_warning "Falha ao atualizar repositório principal"

# Update all submodules
print_status "Inicializando submodules..."
git submodule update --init --recursive

print_status "Atualizando todos os submodules..."
git submodule update --remote --merge

# Check status of each submodule
print_status "Verificando status dos submodules..."
echo ""

submodules=$(git submodule status | awk '{print $2}')

for submodule in $submodules; do
    if [ -d "$submodule" ]; then
        echo -e "${BLUE}=== $submodule ===${NC}"
        cd "$submodule"

        # Check if there are uncommitted changes
        if ! git diff-index --quiet HEAD --; then
            print_warning "Mudanças não commitadas encontradas em $submodule"
            git status --porcelain
        else
            print_success "Limpo"
        fi

        # Show current branch and latest commit
        current_branch=$(git branch --show-current)
        latest_commit=$(git log -1 --oneline)
        echo -e "Branch: ${GREEN}$current_branch${NC}"
        echo -e "Commit: $latest_commit"

        cd - > /dev/null
        echo ""
    fi
done

print_success "Atualização completa do workspace MaisCash!"
echo ""
echo "📋 Próximos passos sugeridos:"
echo "   • Execute ./scripts/build-all.sh para compilar todos os projetos"
echo "   • Execute ./scripts/test-all.sh para rodar todos os testes"
echo "   • Verifique se há mudanças para commit: git status"
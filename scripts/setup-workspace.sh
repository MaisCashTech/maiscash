#!/bin/bash

# Script de setup inicial do workspace MaisCash
# Autor: MaisCashTech Automation
# Uso: ./scripts/setup-workspace.sh

set -e

echo "🏗️ MaisCash Workspace - Setup Inicial"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check prerequisites
print_status "Verificando pré-requisitos..."

# Check Git
if ! command -v git &> /dev/null; then
    print_error "Git não está instalado!"
    exit 1
fi

# Check Java
if ! command -v java &> /dev/null; then
    print_warning "Java não encontrado. Instale Java 17 para os microserviços."
fi

# Check Node.js
if ! command -v node &> /dev/null; then
    print_warning "Node.js não encontrado. Instale Node.js para os projetos frontend."
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    print_warning "Docker não encontrado. Instale Docker para containerização."
fi

print_success "Verificação de pré-requisitos concluída"

# Initialize submodules if not already done
print_status "Inicializando submodules..."
git submodule update --init --recursive

# Make scripts executable
print_status "Configurando permissões dos scripts..."
chmod +x scripts/*.sh

# Setup each major project
print_status "Configurando projetos principais..."

# Setup MaisCashPro if it exists
if [ -d "services/MaisCashPro" ]; then
    print_status "Configurando MaisCashPro..."
    cd services/MaisCashPro
    if [ -f "./mvnw" ]; then
        ./mvnw clean compile -q
        print_success "MaisCashPro backend configurado"
    fi
    if [ -f "package.json" ]; then
        if command -v npm &> /dev/null; then
            npm install --silent
            print_success "MaisCashPro frontend configurado"
        else
            print_warning "npm não encontrado, pulando instalação de dependências frontend"
        fi
    fi
    cd ../..
fi

# Setup Frontend standalone if it exists
if [ -d "frontend/MaiscashPro-Frontend" ]; then
    print_status "Configurando MaiscashPro-Frontend..."
    cd frontend/MaiscashPro-Frontend
    if [ -f "package.json" ] && command -v npm &> /dev/null; then
        npm install --silent
        print_success "MaiscashPro-Frontend configurado"
    fi
    cd ../..
fi

# Create local configuration file
print_status "Criando arquivo de configuração local..."
cat > .maiscash-config << EOF
# MaisCash Workspace Configuration
# Este arquivo é específico da máquina local - não faça commit

# Ambiente de desenvolvimento
ENVIRONMENT=development

# Portas padrão dos serviços
MAISCASH_PRO_PORT=8080
MAISCASH_PRO_FRONTEND_PORT=9000
CONSIG1MS_PORT=8081
COLLECTORS_PORT=8082

# Database
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=maiscash

# Message Queue
ARTEMIS_HOST=localhost
ARTEMIS_PORT=61616

EOF

print_success "Setup inicial concluído!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Configure suas variáveis de ambiente em .maiscash-config"
echo "   2. Execute ./scripts/pull-all.sh para atualizar todos os projetos"
echo "   3. Execute ./scripts/build-all.sh para compilar tudo"
echo "   4. Inicie os serviços com ./scripts/start-all.sh"
echo ""
echo "📖 Documentação:"
echo "   • Consulte README.md para visão geral"
echo "   • Consulte CLAUDE.md para orientações técnicas detalhadas"
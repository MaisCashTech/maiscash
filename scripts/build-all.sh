#!/bin/bash

# Script para compilar todos os projetos do workspace MaisCash
# Autor: MaisCashTech Automation
# Uso: ./scripts/build-all.sh [--clean]

set -e

echo "🔨 MaisCash Workspace - Build All Projects"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Parse arguments
CLEAN_BUILD=false
if [[ "$1" == "--clean" ]]; then
    CLEAN_BUILD=true
    print_status "Build limpo solicitado"
fi

# Build counters
SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_PROJECTS=()

# Function to build a project
build_project() {
    local project_path="$1"
    local project_name="$2"
    local build_command="$3"

    print_status "Building $project_name..."
    cd "$project_path"

    if eval "$build_command"; then
        print_success "$project_name build concluído"
        ((SUCCESS_COUNT++))
    else
        print_error "$project_name build falhou"
        ((FAILED_COUNT++))
        FAILED_PROJECTS+=("$project_name")
    fi

    cd - > /dev/null
    echo ""
}

# Java/Maven projects
print_status "=== BUILDING JAVA/MAVEN PROJECTS ==="

if [ -d "services/MaisCashPro" ]; then
    build_cmd="./mvnw clean compile"
    if [ "$CLEAN_BUILD" = true ]; then
        build_cmd="./mvnw clean verify"
    fi
    build_project "services/MaisCashPro" "MaisCashPro" "$build_cmd"
fi

# Build all microservices
for service_dir in services/*/; do
    if [ -d "$service_dir" ] && [ -f "$service_dir/mvnw" ]; then
        service_name=$(basename "$service_dir")
        if [ "$service_name" != "MaisCashPro" ]; then  # Already built above
            build_cmd="./mvnw clean compile -q"
            if [ "$CLEAN_BUILD" = true ]; then
                build_cmd="./mvnw clean verify -q"
            fi
            build_project "$service_dir" "$service_name" "$build_cmd"
        fi
    fi
done

# Angular/Node.js projects
print_status "=== BUILDING ANGULAR/NODE.JS PROJECTS ==="

if [ -d "frontend/MaiscashPro-Frontend" ] && [ -f "frontend/MaiscashPro-Frontend/package.json" ]; then
    if command -v npm &> /dev/null; then
        build_cmd="npm run build"
        if [ "$CLEAN_BUILD" = true ]; then
            build_cmd="npm ci && npm run build"
        fi
        build_project "frontend/MaiscashPro-Frontend" "MaiscashPro-Frontend" "$build_cmd"
    else
        print_warning "npm não encontrado, pulando MaiscashPro-Frontend"
    fi
fi

if [ -d "frontend/consig1-dashboard" ] && [ -f "frontend/consig1-dashboard/package.json" ]; then
    if command -v npm &> /dev/null; then
        build_cmd="npm run build"
        if [ "$CLEAN_BUILD" = true ]; then
            build_cmd="npm ci && npm run build"
        fi
        build_project "frontend/consig1-dashboard" "consig1-dashboard" "$build_cmd"
    else
        print_warning "npm não encontrado, pulando consig1-dashboard"
    fi
fi

# Build summary
echo "==============================================="
echo "📊 RELATÓRIO DE BUILD"
echo "==============================================="
print_success "Projetos compilados com sucesso: $SUCCESS_COUNT"

if [ $FAILED_COUNT -gt 0 ]; then
    print_error "Projetos com falha: $FAILED_COUNT"
    echo "Projetos que falharam:"
    for project in "${FAILED_PROJECTS[@]}"; do
        echo "  - $project"
    done
    echo ""
    print_error "Alguns builds falharam! Verifique os logs acima."
    exit 1
else
    print_success "Todos os projetos foram compilados com sucesso! 🎉"
fi

echo ""
echo "📋 Próximos passos:"
echo "   • Execute ./scripts/test-all.sh para rodar todos os testes"
echo "   • Execute ./scripts/start-all.sh para iniciar os serviços"
#!/bin/bash

# Script para executar todos os testes do workspace MaisCash
# Autor: MaisCashTech Automation
# Uso: ./scripts/test-all.sh [--coverage]

set -e

echo "🧪 MaisCash Workspace - Test All Projects"
echo "========================================="

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
COVERAGE_MODE=false
if [[ "$1" == "--coverage" ]]; then
    COVERAGE_MODE=true
    print_status "Modo de cobertura ativado"
fi

# Test counters
SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_PROJECTS=()

# Function to test a project
test_project() {
    local project_path="$1"
    local project_name="$2"
    local test_command="$3"

    print_status "Testing $project_name..."
    cd "$project_path"

    if eval "$test_command"; then
        print_success "$project_name testes passaram"
        ((SUCCESS_COUNT++))
    else
        print_error "$project_name testes falharam"
        ((FAILED_COUNT++))
        FAILED_PROJECTS+=("$project_name")
    fi

    cd - > /dev/null
    echo ""
}

# Java/Maven projects tests
print_status "=== TESTING JAVA/MAVEN PROJECTS ==="

# Test MaisCashPro
if [ -d "services/MaisCashPro" ] && [ -f "services/MaisCashPro/mvnw" ]; then
    test_cmd="./mvnw verify -q"
    if [ "$COVERAGE_MODE" = true ]; then
        test_cmd="./mvnw verify jacoco:report -q"
    fi
    test_project "services/MaisCashPro" "MaisCashPro" "$test_cmd"
fi

# Test all microservices
for service_dir in services/*/; do
    if [ -d "$service_dir" ] && [ -f "$service_dir/mvnw" ]; then
        service_name=$(basename "$service_dir")
        if [ "$service_name" != "MaisCashPro" ]; then  # Already tested above
            test_cmd="./mvnw test -q"
            if [ "$COVERAGE_MODE" = true ]; then
                test_cmd="./mvnw verify jacoco:report -q"
            fi
            test_project "$service_dir" "$service_name" "$test_cmd"
        fi
    fi
done

# Angular/Node.js projects tests
print_status "=== TESTING ANGULAR/NODE.JS PROJECTS ==="

if [ -d "frontend/MaiscashPro-Frontend" ] && [ -f "frontend/MaiscashPro-Frontend/package.json" ]; then
    if command -v npm &> /dev/null; then
        test_cmd="npm test -- --watch=false --browsers=ChromeHeadless"
        if [ "$COVERAGE_MODE" = true ]; then
            test_cmd="npm test -- --watch=false --browsers=ChromeHeadless --code-coverage"
        fi
        test_project "frontend/MaiscashPro-Frontend" "MaiscashPro-Frontend" "$test_cmd"
    else
        print_warning "npm não encontrado, pulando testes do MaiscashPro-Frontend"
    fi
fi

if [ -d "frontend/consig1-dashboard" ] && [ -f "frontend/consig1-dashboard/package.json" ]; then
    if command -v npm &> /dev/null; then
        test_cmd="npm test"
        if [ "$COVERAGE_MODE" = true ]; then
            test_cmd="npm run test:coverage"
        fi
        test_project "frontend/consig1-dashboard" "consig1-dashboard" "$test_cmd"
    else
        print_warning "npm não encontrado, pulando testes do consig1-dashboard"
    fi
fi

# Test summary
echo "==============================================="
echo "📊 RELATÓRIO DE TESTES"
echo "==============================================="
print_success "Projetos com testes passando: $SUCCESS_COUNT"

if [ $FAILED_COUNT -gt 0 ]; then
    print_error "Projetos com testes falhando: $FAILED_COUNT"
    echo "Projetos que falharam:"
    for project in "${FAILED_PROJECTS[@]}"; do
        echo "  - $project"
    done
    echo ""
    print_error "Alguns testes falharam! Corrija os problemas antes de fazer deploy."
    exit 1
else
    print_success "Todos os testes passaram! ✅ Pronto para deploy!"
fi

if [ "$COVERAGE_MODE" = true ]; then
    echo ""
    print_status "📈 Relatórios de cobertura gerados nos diretórios target/ e coverage/"
fi

echo ""
echo "📋 Próximos passos:"
echo "   • Se todos os testes passaram, você pode fazer deploy"
echo "   • Execute ./scripts/build-all.sh --clean para build completo"
echo "   • Execute ./scripts/start-all.sh para testar localmente"
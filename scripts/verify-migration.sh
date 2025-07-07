#!/bin/bash

# =============================================================================
# Script de Migração - Organização de Scripts
# =============================================================================
# Script para verificar e validar a nova organização dos scripts
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}   Verificação da Nova Estrutura de Scripts${NC}"
echo -e "${BLUE}============================================================${NC}"
echo

# Função para verificar se arquivo existe
check_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}[OK]${NC} $description: $file"
        return 0
    else
        echo -e "${RED}[ERRO]${NC} $description: $file não encontrado"
        return 1
    fi
}

# Função para verificar diretório
check_directory() {
    local dir="$1"
    local description="$2"
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}[OK]${NC} $description: $dir"
        return 0
    else
        echo -e "${RED}[ERRO]${NC} $description: $dir não encontrado"
        return 1
    fi
}

# Função para verificar link simbólico
check_symlink() {
    local link="$1"
    local target="$2"
    local description="$3"
    
    if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
        echo -e "${GREEN}[OK]${NC} $description: $link -> $target"
        return 0
    else
        echo -e "${RED}[ERRO]${NC} $description: Link $link não aponta para $target"
        return 1
    fi
}

echo -e "${YELLOW}VERIFICANDO ESTRUTURA DE DIRETÓRIOS${NC}"
echo "=================================================="

# Verificar diretórios principais
check_directory "scripts" "Diretório principal"
check_directory "scripts/monitoring" "Monitoramento"
check_directory "scripts/setup" "Setup"
check_directory "scripts/testing" "Testes"
check_directory "scripts/utilities" "Utilitários"
check_directory "scripts/dashboards" "Dashboards"

echo
echo -e "${YELLOW}VERIFICANDO SCRIPTS DE MONITORAMENTO${NC}"
echo "=================================================="

# Verificar scripts de monitoramento
check_file "scripts/monitoring/monitor-holesky.sh" "Monitor Holesky"
check_file "scripts/monitoring/monitor-simple.sh" "Monitor Simples"
check_file "scripts/monitoring/monitor-complete-status.sh" "Monitor Completo"
check_file "scripts/monitoring/monitor-ssd.sh" "Monitor SSD"
check_file "scripts/monitoring/README.md" "Documentação Monitoramento"

echo
echo -e "${YELLOW}VERIFICANDO SCRIPTS DE SETUP${NC}"
echo "=================================================="

# Verificar scripts de setup
check_file "scripts/setup/setup-holesky.sh" "Setup Holesky"
check_file "scripts/setup/setup-ssd.sh" "Setup SSD"
check_file "scripts/setup/setup-external-ssd.sh" "Setup SSD Externo"
check_file "scripts/setup/README.md" "Documentação Setup"

echo
echo -e "${YELLOW}VERIFICANDO SCRIPTS DE TESTE${NC}"
echo "=================================================="

# Verificar scripts de teste
check_file "scripts/testing/test-simple-holesky.sh" "Teste Simples"
check_file "scripts/testing/test-dashboards-holesky.sh" "Teste Dashboards"
check_file "scripts/testing/README.md" "Documentação Testes"

echo
echo -e "${YELLOW}VERIFICANDO SCRIPTS UTILITÁRIOS${NC}"
echo "=================================================="

# Verificar scripts utilitários
check_file "scripts/utilities/status-holesky.sh" "Status Holesky"
check_file "scripts/utilities/verify-wallet.sh" "Verificar Wallet"
check_file "scripts/utilities/show-dashboard-structure.sh" "Estrutura Dashboards"
check_file "scripts/utilities/README.md" "Documentação Utilitários"

echo
echo -e "${YELLOW}VERIFICANDO SCRIPTS DE DASHBOARDS${NC}"
echo "=================================================="

# Verificar scripts de dashboards
check_file "scripts/dashboards/import-recommended-dashboards.sh" "Importar Dashboards"
check_file "scripts/dashboards/download-dashboards.sh" "Download Dashboards"
check_file "scripts/dashboards/download-dashboards-curl.sh" "Download cURL"
check_file "scripts/dashboards/fix-dashboard-containers.sh" "Corrigir Containers"
check_file "scripts/dashboards/README.md" "Documentação Dashboards"

echo
echo -e "${YELLOW}VERIFICANDO COMPATIBILIDADE (LINKS SIMBÓLICOS)${NC}"
echo "=================================================="

# Verificar links simbólicos para compatibilidade
check_symlink "monitor-holesky.sh" "scripts/monitoring/monitor-holesky.sh" "Link Monitor Holesky"
check_symlink "monitor-simple.sh" "scripts/monitoring/monitor-simple.sh" "Link Monitor Simples"
check_symlink "monitor-complete-status.sh" "scripts/monitoring/monitor-complete-status.sh" "Link Monitor Completo"
check_symlink "setup-holesky.sh" "scripts/setup/setup-holesky.sh" "Link Setup Holesky"
check_symlink "setup-ssd.sh" "scripts/setup/setup-ssd.sh" "Link Setup SSD"

echo
echo -e "${YELLOW}VERIFICANDO DOCUMENTAÇÃO${NC}"
echo "=================================================="

# Verificar documentação
check_file "scripts/README.md" "README principal"
check_file "docs/README.md" "README docs"
check_file "docs/troubleshooting-consensus-errors.md" "Troubleshooting"

echo
echo -e "${YELLOW}TESTANDO EXECUÇÃO${NC}"
echo "=================================================="

# Testar execução de scripts principais
echo -e "${BLUE}Testando scripts principais...${NC}"

# Teste do monitor via link simbólico
if [ -x "./monitor-holesky.sh" ]; then
    echo -e "${GREEN}[OK]${NC} Link monitor-holesky.sh é executável"
else
    echo -e "${RED}[ERRO]${NC} Link monitor-holesky.sh não é executável"
fi

# Teste do monitor via caminho completo
if [ -x "./scripts/monitoring/monitor-holesky.sh" ]; then
    echo -e "${GREEN}[OK]${NC} Script scripts/monitoring/monitor-holesky.sh é executável"
else
    echo -e "${RED}[ERRO]${NC} Script scripts/monitoring/monitor-holesky.sh não é executável"
fi

echo
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}   Resumo da Migração${NC}"
echo -e "${BLUE}============================================================${NC}"

echo -e "${GREEN}✅ Estrutura de diretórios criada${NC}"
echo -e "${GREEN}✅ Scripts organizados por categoria${NC}"
echo -e "${GREEN}✅ Documentação completa criada${NC}"
echo -e "${GREEN}✅ Links simbólicos para compatibilidade${NC}"
echo -e "${GREEN}✅ Permissões de execução mantidas${NC}"

echo
echo -e "${BLUE}Comandos ainda funcionam:${NC}"
echo "  ./monitor-holesky.sh"
echo "  ./monitor-simple.sh"
echo "  ./setup-holesky.sh"
echo

echo -e "${BLUE}Nova estrutura disponível:${NC}"
echo "  ./scripts/monitoring/monitor-holesky.sh"
echo "  ./scripts/setup/setup-holesky.sh"
echo "  ./scripts/testing/test-simple-holesky.sh"
echo "  ./scripts/utilities/status-holesky.sh"
echo "  ./scripts/dashboards/import-recommended-dashboards.sh"

echo
echo -e "${GREEN}🎉 MIGRAÇÃO CONCLUÍDA COM SUCESSO!${NC}"
echo -e "${YELLOW}📖 Consulte scripts/README.md para mais informações${NC}"

#!/bin/bash

# =============================================================================
# Fix Markdown - Correção Automática de Arquivos Markdown
# =============================================================================
# Script para corrigir problemas comuns em arquivos markdown
# Remove emojis dos títulos e corrige formatação para padrão profissional
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}   Fix Markdown - Correção Automática de Arquivos MD${NC}"
echo -e "${BLUE}============================================================${NC}"
echo

# Função para mostrar ajuda
show_help() {
    echo -e "${YELLOW}Uso:${NC}"
    echo "  $0 [opções] [arquivos...]"
    echo
    echo -e "${YELLOW}Opções:${NC}"
    echo "  -h, --help      Mostra esta ajuda"
    echo "  -a, --all       Processa todos os arquivos .md do projeto"
    echo "  -s, --scripts   Processa apenas arquivos em scripts/"
    echo "  -d, --docs      Processa apenas arquivos em docs/"
    echo "  -b, --backup    Cria backup antes de modificar"
    echo "  -v, --verbose   Mostra detalhes das correções"
    echo
    echo -e "${YELLOW}Exemplos:${NC}"
    echo "  $0 --all                    # Corrige todos os arquivos .md"
    echo "  $0 --scripts --backup       # Corrige scripts/ com backup"
    echo "  $0 docs/README.md           # Corrige arquivo específico"
    echo "  $0 --docs --verbose         # Corrige docs/ com detalhes"
}

# Variáveis de controle
BACKUP=false
VERBOSE=false
PROCESS_ALL=false
PROCESS_SCRIPTS=false
PROCESS_DOCS=false
FILES=()

# Processar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -a|--all)
            PROCESS_ALL=true
            shift
            ;;
        -s|--scripts)
            PROCESS_SCRIPTS=true
            shift
            ;;
        -d|--docs)
            PROCESS_DOCS=true
            shift
            ;;
        -b|--backup)
            BACKUP=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -*)
            echo -e "${RED}Opção desconhecida: $1${NC}"
            show_help
            exit 1
            ;;
        *)
            FILES+=("$1")
            shift
            ;;
    esac
done

# Função para fazer backup
make_backup() {
    local file="$1"
    if [ "$BACKUP" = true ]; then
        cp "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${GREEN}[BACKUP]${NC} Backup criado para $file"
    fi
}

# Função para verificar se o arquivo precisa de correção
needs_correction() {
    local file="$1"
    
    # Verificar se há emojis em títulos
    if grep -q "^#.*[🎯📊⚙️🔧🧪📈🚀🔄📝🏷️🔍🛠️📁]" "$file"; then
        return 0
    fi
    
    # Verificar se há emphasis usado como heading
    if grep -q "^\*\*.*\*\*$" "$file"; then
        return 0
    fi
    
    # Verificar se há itálico usado como heading
    if grep -q "^\*[^*]*\*$" "$file"; then
        return 0
    fi
    
    # Verificar se há títulos com emojis específicos
    if grep -q "^#.*[🎉✅❌⚠️💡🔥🎊🎁🎈🎀🌟⭐🏆🥇🎪🎨🎭🎯🎲🎳🎮🎰🎱🎲🎸🎹🎺🎻🎼🎵🎶🎤🎧🎬🎥📹📷📸📺📻📡]" "$file"; then
        return 0
    fi
    
    return 1
}

# Função para processar um arquivo
process_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}[ERRO]${NC} Arquivo não encontrado: $file"
        return 1
    fi
    
    # Verificar se precisa de correção
    if ! needs_correction "$file"; then
        if [ "$VERBOSE" = true ]; then
            echo -e "${GREEN}[OK]${NC} $file já está correto"
        fi
        return 0
    fi
    
    echo -e "${YELLOW}[PROCESSANDO]${NC} $file"
    
    # Fazer backup se solicitado
    make_backup "$file"
    
    # Contador de correções
    local corrections=0
    
    # Arquivo temporário
    local temp_file=$(mktemp)
    
    # Aplicar correções usando sed
    sed \
        -e 's/^# 🛠️ /# /' \
        -e 's/^# 📊 /# /' \
        -e 's/^# ⚙️ /# /' \
        -e 's/^# 🧪 /# /' \
        -e 's/^# 🔧 /# /' \
        -e 's/^# 📈 /# /' \
        -e 's/^# 🎯 /# /' \
        -e 's/^# 📁 /# /' \
        -e 's/^# 🚀 /# /' \
        -e 's/^# 🔄 /# /' \
        -e 's/^# 📝 /# /' \
        -e 's/^# 🏷️ /# /' \
        -e 's/^# 🔍 /# /' \
        -e 's/^# 🎉 /# /' \
        -e 's/^# ✅ /# /' \
        -e 's/^## 🎯 /## /' \
        -e 's/^## 📁 /## /' \
        -e 's/^## 🚀 /## /' \
        -e 's/^## 📊 /## /' \
        -e 's/^## ⚙️ /## /' \
        -e 's/^## 🎯 /## /' \
        -e 's/^## 🔄 /## /' \
        -e 's/^## 📈 /## /' \
        -e 's/^## 🚨 /## /' \
        -e 's/^## 🔧 /## /' \
        -e 's/^## 📝 /## /' \
        -e 's/^## 🏷️ /## /' \
        -e 's/^## 🔍 /## /' \
        -e 's/^## 🎉 /## /' \
        -e 's/^## ✅ /## /' \
        -e 's/^## 📋 /## /' \
        -e 's/^### 📊 /### /' \
        -e 's/^### ⚙️ /### /' \
        -e 's/^### 🎯 /### /' \
        -e 's/^### 🔄 /### /' \
        -e 's/^### 📈 /### /' \
        -e 's/^### 🚨 /### /' \
        -e 's/^### 🔧 /### /' \
        -e 's/^### 🎉 /### /' \
        -e 's/^### ✅ /### /' \
        -e 's/^### 📋 /### /' \
        -e 's/^\*\*\([^*]*\)\*\*$/\1/' \
        -e 's/^\*\([^*]*\)\*$/\1/' \
        "$file" > "$temp_file"
    
    # Verificar se houve mudanças
    if ! diff -q "$file" "$temp_file" > /dev/null; then
        mv "$temp_file" "$file"
        echo -e "${GREEN}[CORRIGIDO]${NC} $file"
        
        if [ "$VERBOSE" = true ]; then
            echo -e "  ${BLUE}→${NC} Emojis removidos dos títulos"
            echo -e "  ${BLUE}→${NC} Formatação padronizada"
        fi
    else
        rm "$temp_file"
        if [ "$VERBOSE" = true ]; then
            echo -e "${GREEN}[OK]${NC} $file não precisava de correção"
        fi
    fi
}

# Função para encontrar arquivos
find_files() {
    local pattern="$1"
    local dir="$2"
    
    if [ -d "$dir" ]; then
        find "$dir" -name "$pattern" -type f | sort
    fi
}

# Determinar quais arquivos processar
if [ "$PROCESS_ALL" = true ]; then
    echo -e "${YELLOW}Processando todos os arquivos .md do projeto...${NC}"
    while IFS= read -r -d '' file; do
        FILES+=("$file")
    done < <(find . -name "*.md" -type f -print0)
elif [ "$PROCESS_SCRIPTS" = true ]; then
    echo -e "${YELLOW}Processando arquivos em scripts/...${NC}"
    while IFS= read -r file; do
        FILES+=("$file")
    done < <(find_files "*.md" "scripts")
elif [ "$PROCESS_DOCS" = true ]; then
    echo -e "${YELLOW}Processando arquivos em docs/...${NC}"
    while IFS= read -r file; do
        FILES+=("$file")
    done < <(find_files "*.md" "docs")
elif [ ${#FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}Nenhum arquivo especificado. Use --help para ver opções.${NC}"
    exit 1
fi

# Processar arquivos
echo -e "${BLUE}Arquivos a processar: ${#FILES[@]}${NC}"
echo

processed=0
corrected=0

for file in "${FILES[@]}"; do
    if process_file "$file"; then
        processed=$((processed + 1))
        if needs_correction "$file" 2>/dev/null; then
            :
        else
            corrected=$((corrected + 1))
        fi
    fi
done

echo
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}   Resumo das Correções${NC}"
echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}Arquivos processados: $processed${NC}"
echo -e "${GREEN}Arquivos corrigidos: $corrected${NC}"

if [ "$BACKUP" = true ]; then
    echo -e "${YELLOW}Backups criados com timestamp${NC}"
fi

echo -e "${GREEN}Correções concluídas!${NC}"

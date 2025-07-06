#!/bin/bash

# Script para corrigir dashboards do Grafana após mudança de nomes dos containers
# De: eth1-holesky, eth2-holesky -> Para: geth, lighthouse

set -e

echo "🔧 Correção de Dashboards Grafana - Nomes de Containers"
echo "======================================================="

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
GRAFANA_DIR="$WORKSPACE_DIR/grafana"

echo "📁 Diretório do Grafana: $GRAFANA_DIR"

# Encontrar todos os arquivos JSON
DASHBOARD_FILES=(
    "$GRAFANA_DIR/dashboards/*.json"
    "$GRAFANA_DIR/provisioning/dashboards/**/*.json"
)

echo "🔍 Procurando arquivos JSON para corrigir..."

# Função para processar um arquivo
process_file() {
    local file="$1"
    local changed=false
    
    if [[ ! -f "$file" ]]; then
        return 0
    fi
    
    echo "📝 Processando: $(basename "$file")"
    
    # Fazer backup se não existir
    if [[ ! -f "$file.backup-containers" ]]; then
        cp "$file" "$file.backup-containers"
        echo "   💾 Backup criado: $(basename "$file").backup-containers"
    fi
    
    # Substituições necessárias
    local temp_file=$(mktemp)
    cp "$file" "$temp_file"
    
    # Substituir nomes de containers nos targets/expressions
    if sed -i.tmp 's/eth1-holesky/geth/g' "$temp_file" 2>/dev/null; then
        changed=true
        echo "   ✅ eth1-holesky → geth"
    fi
    
    if sed -i.tmp 's/eth2-holesky/lighthouse/g' "$temp_file" 2>/dev/null; then
        changed=true
        echo "   ✅ eth2-holesky → lighthouse"
    fi
    
    # Verificar se houve mudanças
    if $changed; then
        mv "$temp_file" "$file"
        echo "   ✅ $(basename "$file") atualizado!"
    else
        rm -f "$temp_file"
        echo "   ℹ️  $(basename "$file") - nenhuma alteração necessária"
    fi
    
    # Limpar arquivos temporários
    rm -f "$temp_file.tmp"
}

# Processar todos os arquivos JSON
for pattern in "${DASHBOARD_FILES[@]}"; do
    for file in $pattern; do
        if [[ -f "$file" ]]; then
            process_file "$file"
        fi
    done
done

# Verificar arquivos específicos conhecidos
echo ""
echo "🔍 Verificando arquivos específicos conhecidos..."

SPECIFIC_FILES=(
    "$GRAFANA_DIR/provisioning/dashboards/Ethereum/ethereum.json"
    "$GRAFANA_DIR/provisioning/dashboards/Ethereum/geth.json"
    "$GRAFANA_DIR/provisioning/dashboards/Holesky/geth-holesky.json"
    "$GRAFANA_DIR/provisioning/dashboards/Holesky/lighthouse-holesky.json"
)

for file in "${SPECIFIC_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        process_file "$file"
    else
        echo "   ⚠️  Arquivo não encontrado: $(basename "$file")"
    fi
done

echo ""
echo "🔧 Corrigindo arquivo de configuração do Prometheus..."

# Já foi corrigido anteriormente, mas vamos verificar
PROMETHEUS_FILE="$WORKSPACE_DIR/prometheus-holesky.yml"
if [[ -f "$PROMETHEUS_FILE" ]]; then
    if grep -q "eth1-holesky\|eth2-holesky" "$PROMETHEUS_FILE"; then
        echo "   ⚠️  ATENÇÃO: $PROMETHEUS_FILE ainda contém nomes antigos!"
        echo "   Execute: Edite $PROMETHEUS_FILE e substitua:"
        echo "   - eth1-holesky:6060 → geth:6060"
        echo "   - eth2-holesky:5054 → lighthouse:5054"
    else
        echo "   ✅ prometheus-holesky.yml já está correto"
    fi
else
    echo "   ⚠️  prometheus-holesky.yml não encontrado"
fi

echo ""
echo "📊 Verificando status dos serviços..."

# Verificar se os containers estão rodando
if command -v docker &> /dev/null; then
    echo "Containers em execução:"
    docker ps --filter name="geth\|lighthouse\|prometheus-holesky\|grafana-holesky" \
        --format "table {{.Names}}\t{{.Status}}" || echo "Erro ao verificar containers"
else
    echo "Docker não disponível para verificação"
fi

echo ""
echo "🎯 Próximos passos:"
echo "1. Reiniciar Prometheus: docker-compose -f docker-compose-holesky.yml --env-file .env.holesky restart prometheus"
echo "2. Aguardar Lighthouse inicializar completamente"
echo "3. Verificar dashboards no Grafana: http://localhost:3000"
echo "4. Importar novos dashboards recomendados se necessário"

echo ""
echo "✅ Correção de dashboards concluída!"
echo "💡 Os backups estão salvos com extensão .backup-containers"

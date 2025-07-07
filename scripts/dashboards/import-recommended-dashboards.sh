#!/bin/bash

# Script para importar dashboards recomendados do eth-docker
# Baseado na análise dos dashboards disponíveis

set -e

# Mudar para o diretório raiz do projeto
cd "$(dirname "$0")/../.."

# Configurações
DASHBOARD_DIR="grafana/dashboards"
PROVISIONING_DIR="grafana/provisioning/dashboards"
RECOMMENDED_DIR="$PROVISIONING_DIR/Recommended"

echo "🔄 Importando dashboards recomendados..."

# Criar diretórios se não existirem
mkdir -p "$DASHBOARD_DIR"
mkdir -p "$RECOMMENDED_DIR"

# Função para baixar dashboard do Grafana.com
download_grafana_dashboard() {
    local dashboard_id=$1
    local output_file=$2
    local dashboard_name=$3
    
    echo "📥 Baixando $dashboard_name (ID: $dashboard_id)..."
    
    # Obter informações do dashboard
    local info=$(curl -s "https://grafana.com/api/dashboards/$dashboard_id" | jq -r '.revision')
    
    if [ "$info" != "null" ] && [ -n "$info" ]; then
        # Baixar dashboard
        curl -s "https://grafana.com/api/dashboards/$dashboard_id/revisions/$info/download" > "$output_file"
        echo "✅ Dashboard $dashboard_name baixado"
        return 0
    else
        echo "❌ Falha ao baixar $dashboard_name"
        return 1
    fi
}

# Função para baixar dashboard direto de URL
download_direct_dashboard() {
    local url=$1
    local output_file=$2
    local dashboard_name=$3
    
    echo "📥 Baixando $dashboard_name..."
    
    if curl -s "$url" > "$output_file"; then
        echo "✅ Dashboard $dashboard_name baixado"
        return 0
    else
        echo "❌ Falha ao baixar $dashboard_name"
        return 1
    fi
}

# Função para corrigir referências de datasource
fix_datasource_references() {
    local file=$1
    
    if [ -f "$file" ]; then
        # Substituir referências de datasource por "Prometheus"
        sed -i '' 's/\${DS_PROMETHEUS}/Prometheus/g' "$file"
        sed -i '' 's/\${datasource}/Prometheus/g' "$file"
        sed -i '' 's/"uid": "prometheus"/"uid": "Prometheus"/g' "$file"
        
        # Corrigir referências específicas para nossos containers
        sed -i '' 's/eth1-holesky/geth/g' "$file"
        sed -i '' 's/eth2-holesky/lighthouse/g' "$file"
        sed -i '' 's/rocketpool-holesky/rocketpool-node-holesky/g' "$file"
        
        echo "🔧 Corrigido datasource em: $(basename "$file")"
    fi
}

echo "🚀 Iniciando download dos dashboards recomendados..."

# 1. Lighthouse Summary
download_direct_dashboard \
    "https://raw.githubusercontent.com/sigp/lighthouse-metrics/master/dashboards/Summary.json" \
    "$RECOMMENDED_DIR/lighthouse_summary.json" \
    "Lighthouse Summary"

# 2. Lighthouse Validator Client
download_direct_dashboard \
    "https://raw.githubusercontent.com/sigp/lighthouse-metrics/master/dashboards/ValidatorClient.json" \
    "$RECOMMENDED_DIR/lighthouse_validator_client.json" \
    "Lighthouse Validator Client"

# 3. Lighthouse Validator Monitor
download_direct_dashboard \
    "https://raw.githubusercontent.com/sigp/lighthouse-metrics/master/dashboards/ValidatorMonitor.json" \
    "$RECOMMENDED_DIR/lighthouse_validator_monitor.json" \
    "Lighthouse Validator Monitor"

# 4. Geth Dashboard
download_direct_dashboard \
    "https://gist.githubusercontent.com/karalabe/e7ca79abdec54755ceae09c08bd090cd/raw/3a400ab90f9402f2233280afd086cb9d6aac2111/dashboard.json" \
    "$RECOMMENDED_DIR/geth_dashboard.json" \
    "Geth Dashboard"

# 5. Docker Host Container Overview
download_grafana_dashboard \
    "19724" \
    "$RECOMMENDED_DIR/docker_host_overview.json" \
    "Docker Host Container Overview"

# 6. Home Staking Dashboard
download_grafana_dashboard \
    "17846" \
    "$RECOMMENDED_DIR/home_staking.json" \
    "Home Staking Dashboard"

# 7. Ethereum Metrics Exporter
download_grafana_dashboard \
    "16277" \
    "$RECOMMENDED_DIR/ethereum_metrics_exporter.json" \
    "Ethereum Metrics Exporter"

echo ""
echo "🔧 Corrigindo referências de datasource..."

# Corrigir referências de datasource em todos os arquivos
for file in "$RECOMMENDED_DIR"/*.json; do
    if [ -f "$file" ]; then
        fix_datasource_references "$file"
    fi
done

echo ""
echo "📊 Dashboards baixados:"
ls -la "$RECOMMENDED_DIR"

echo ""
echo "✅ Importação concluída!"
echo "🔄 Reinicie o Grafana para aplicar os novos dashboards:"
echo "   docker restart grafana-holesky"
echo ""
echo "🌐 Acesse o Grafana em: http://localhost:3000"
echo "📁 Dashboards salvos em: $RECOMMENDED_DIR"

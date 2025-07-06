#!/bin/bash

# Script para baixar dashboards recomendados para Rocket Pool
# Baseado no projeto eth-docker - Versão usando curl

set -e

echo "🚀 Rocket Pool - Download de Dashboards Recomendados"
echo "=================================================="

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
DASHBOARD_DIR="$WORKSPACE_DIR/grafana/dashboards"

echo "📁 Diretório de dashboards: $DASHBOARD_DIR"

# Criar diretório se não existir
mkdir -p "$DASHBOARD_DIR"

# Função para baixar dashboard usando curl
download_dashboard() {
    local url="$1"
    local filename="$2"
    local title="$3"
    
    echo "⬇️  Baixando: $title"
    
    if curl -s -L -o "$DASHBOARD_DIR/$filename" "$url"; then
        # Verificar se o arquivo foi baixado corretamente
        if [[ -s "$DASHBOARD_DIR/$filename" ]]; then
            echo "✅ $title baixado com sucesso"
            return 0
        else
            echo "❌ Erro: arquivo vazio para $title"
            rm -f "$DASHBOARD_DIR/$filename"
            return 1
        fi
    else
        echo "❌ Erro ao baixar $title"
        return 1
    fi
}

# Função para baixar dashboard do Grafana.com
download_grafana_dashboard() {
    local id="$1"
    local filename="$2"
    local title="$3"
    
    echo "⬇️  Baixando: $title (ID: $id)"
    
    # Obter a última revisão
    local revision
    revision=$(curl -s "https://grafana.com/api/dashboards/$id" | python3 -c "import sys, json; print(json.load(sys.stdin)['revision'])" 2>/dev/null || echo "")
    
    if [[ "$revision" != "" ]]; then
        local url="https://grafana.com/api/dashboards/$id/revisions/$revision/download"
        
        if curl -s -L -o "$DASHBOARD_DIR/$filename" "$url"; then
            # Verificar se o arquivo foi baixado corretamente
            if [[ -s "$DASHBOARD_DIR/$filename" ]]; then
                echo "✅ $title baixado com sucesso (revisão: $revision)"
                return 0
            else
                echo "❌ Erro: arquivo vazio para $title"
                rm -f "$DASHBOARD_DIR/$filename"
                return 1
            fi
        else
            echo "❌ Erro ao baixar $title"
            return 1
        fi
    else
        echo "❌ Erro ao obter revisão do dashboard $id"
        return 1
    fi
}

# Verificar dependências
echo "🔍 Verificando dependências..."
command -v curl >/dev/null 2>&1 || { echo "❌ curl não encontrado"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ python3 não encontrado"; exit 1; }

echo "✅ Dependências verificadas"
echo ""

# 1. Lighthouse Dashboards
echo "🔥 Baixando Lighthouse Dashboards..."
download_dashboard \
    "https://raw.githubusercontent.com/sigp/lighthouse-metrics/master/dashboards/Summary.json" \
    "lighthouse_summary.json" \
    "Lighthouse Summary"

download_dashboard \
    "https://raw.githubusercontent.com/sigp/lighthouse-metrics/master/dashboards/ValidatorClient.json" \
    "lighthouse_validator_client.json" \
    "Lighthouse Validator Client"

download_dashboard \
    "https://raw.githubusercontent.com/sigp/lighthouse-metrics/master/dashboards/ValidatorMonitor.json" \
    "lighthouse_validator_monitor.json" \
    "Lighthouse Validator Monitor"

# 2. Geth Dashboard
echo ""
echo "⚙️  Baixando Geth Dashboard..."
download_dashboard \
    "https://gist.githubusercontent.com/karalabe/e7ca79abdec54755ceae09c08bd090cd/raw/3a400ab90f9402f2233280afd086cb9d6aac2111/dashboard.json" \
    "geth_dashboard.json" \
    "Geth Dashboard"

# 3. Sistema e Infraestrutura
echo ""
echo "🖥️  Baixando Dashboards de Sistema..."
download_grafana_dashboard \
    "19724" \
    "docker_host_overview.json" \
    "Docker Host Container Overview"

download_grafana_dashboard \
    "17846" \
    "home_staking.json" \
    "Home Staking Dashboard"

download_grafana_dashboard \
    "16277" \
    "ethereum_metrics_exporter.json" \
    "Ethereum Metrics Exporter"

# 4. Corrigir referências de data source
echo ""
echo "🔧 Corrigindo referências de data source..."

for file in "$DASHBOARD_DIR"/*.json; do
    if [[ -f "$file" ]]; then
        echo "🔄 Processando: $(basename "$file")"
        
        # Backup do arquivo original
        cp "$file" "$file.backup"
        
        # Substituir referências de data source usando sed
        sed -i '' 's/\${DS_PROMETHEUS}/Prometheus/g' "$file" 2>/dev/null || sed -i 's/\${DS_PROMETHEUS}/Prometheus/g' "$file"
        sed -i '' 's/\${datasource}/Prometheus/g' "$file" 2>/dev/null || sed -i 's/\${datasource}/Prometheus/g' "$file"
        sed -i '' 's/"uid": "prometheus"/"uid": "Prometheus"/g' "$file" 2>/dev/null || sed -i 's/"uid": "prometheus"/"uid": "Prometheus"/g' "$file"
        sed -i '' 's/"uid": "\${DS_PROMETHEUS}"/"uid": "Prometheus"/g' "$file" 2>/dev/null || sed -i 's/"uid": "\${DS_PROMETHEUS}"/"uid": "Prometheus"/g' "$file"
        
        # Adicionar títulos mais descritivos usando Python
        case "$(basename "$file")" in
            "lighthouse_summary.json")
                python3 -c "import json,sys; d=json.load(open(sys.argv[1])); d['title']='Lighthouse Summary'; json.dump(d, open(sys.argv[1], 'w'), indent=2)" "$file" 2>/dev/null || true
                ;;
            "lighthouse_validator_client.json")
                python3 -c "import json,sys; d=json.load(open(sys.argv[1])); d['title']='Lighthouse Validator Client'; json.dump(d, open(sys.argv[1], 'w'), indent=2)" "$file" 2>/dev/null || true
                ;;
            "lighthouse_validator_monitor.json")
                python3 -c "import json,sys; d=json.load(open(sys.argv[1])); d['title']='Lighthouse Validator Monitor'; json.dump(d, open(sys.argv[1], 'w'), indent=2)" "$file" 2>/dev/null || true
                ;;
            "geth_dashboard.json")
                python3 -c "import json,sys; d=json.load(open(sys.argv[1])); d['title']='Geth Dashboard'; json.dump(d, open(sys.argv[1], 'w'), indent=2)" "$file" 2>/dev/null || true
                ;;
        esac
        
        echo "✅ $(basename "$file") processado"
    fi
done

# 5. Criar arquivo de índice
echo ""
echo "📋 Criando arquivo de índice..."
cat > "$DASHBOARD_DIR/README.md" << EOF
# Dashboards Importados

Este diretório contém dashboards recomendados para monitoramento do Rocket Pool.

## Dashboards Disponíveis

### Lighthouse (Consensus Client)
- \`lighthouse_summary.json\` - Visão geral do Lighthouse
- \`lighthouse_validator_client.json\` - Métricas do validador
- \`lighthouse_validator_monitor.json\` - Monitoramento avançado

### Geth (Execution Client)
- \`geth_dashboard.json\` - Dashboard oficial do Geth

### Sistema e Infraestrutura
- \`docker_host_overview.json\` - Monitoramento de containers
- \`home_staking.json\` - Dashboard para home staking
- \`ethereum_metrics_exporter.json\` - Métricas adicionais

## Como Importar

### Via Grafana UI
1. Acesse: http://localhost:3000
2. Vá em "+" → "Import"
3. Selecione "Upload JSON file"
4. Escolha o arquivo desejado
5. Configure Data Source como "Prometheus"

### Via Docker Compose
Os dashboards serão automaticamente provisionados se você configurar:

\`\`\`yaml
grafana:
  volumes:
    - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
\`\`\`

## Arquivos de Backup
Os arquivos \`.backup\` são backups dos originais antes das modificações.
EOF

echo ""
echo "🎉 Download concluído!"
echo "📊 Dashboards salvos em: $DASHBOARD_DIR"
echo "📖 Veja o arquivo README.md para instruções de importação"
echo ""
echo "🔧 Para importar automaticamente, adicione ao docker-compose:"
echo "   grafana:"
echo "     volumes:"
echo "       - ./grafana/dashboards:/etc/grafana/provisioning/dashboards"
echo ""
echo "🌐 Acesse o Grafana: http://localhost:3000"
echo "   Usuário: admin"
echo "   Senha: admin"

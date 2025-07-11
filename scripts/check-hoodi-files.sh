#!/bin/bash
# Script para verificar se todos os arquivos da Hoodi estão no SSD
# Verification script for Hoodi files on SSD

set -e

echo "🔍 Verificação de Arquivos da Hoodi no SSD"
echo "=========================================="

# Configurar diretório
cd "$(dirname "$0")/.."

# Carregar variáveis de ambiente
if [ -f ".env.hoodi" ]; then
    echo "📋 Carregando variáveis de ambiente..."
    set -a
    source .env.hoodi
    set +a
else
    echo "❌ Arquivo .env.hoodi não encontrado!"
    exit 1
fi

# Verificar se o SSD está montado
if [ ! -d "$SSD_MOUNT_PATH" ]; then
    echo "❌ SSD não encontrado em: $SSD_MOUNT_PATH"
    exit 1
fi

echo "✅ SSD encontrado em: $SSD_MOUNT_PATH"
echo ""

# Função para verificar diretório
check_directory() {
    local dir_path="$1"
    local dir_name="$2"
    
    if [ -d "$dir_path" ]; then
        local size=$(du -sh "$dir_path" 2>/dev/null | cut -f1)
        echo "✅ $dir_name: $dir_path ($size)"
    else
        echo "❌ $dir_name: $dir_path (não encontrado)"
    fi
}

# Função para verificar arquivo
check_file() {
    local file_path="$1"
    local file_name="$2"
    
    if [ -f "$file_path" ]; then
        local size=$(ls -lh "$file_path" 2>/dev/null | awk '{print $5}')
        echo "✅ $file_name: $file_path ($size)"
    else
        echo "❌ $file_name: $file_path (não encontrado)"
    fi
}

echo "📂 Verificando diretórios principais:"
check_directory "$EXECUTION_DATA_PATH" "Execution Data"
check_directory "$CONSENSUS_DATA_PATH" "Consensus Data"
check_directory "$ROCKETPOOL_DATA_PATH" "Rocket Pool Data"
check_directory "$PROMETHEUS_DATA_PATH" "Prometheus Data"
check_directory "$GRAFANA_DATA_PATH" "Grafana Data"
check_directory "$ALERTMANAGER_DATA_PATH" "Alertmanager Data"

echo ""
echo "📄 Verificando arquivos críticos:"
check_file "$ROCKETPOOL_DATA_PATH/.rocketpool/user-settings.yml" "user-settings.yml"
check_file "$ROCKETPOOL_DATA_PATH/secrets/jwtsecret" "JWT Secret"

echo ""
echo "📊 Espaço total utilizado pela Hoodi:"
if [ -d "$SSD_MOUNT_PATH/ethereum-data-hoodi" ]; then
    du -sh "$SSD_MOUNT_PATH/ethereum-data-hoodi" 2>/dev/null || echo "Não foi possível calcular"
else
    echo "Diretório principal não encontrado"
fi

echo ""
echo "💾 Espaço disponível no SSD:"
df -h "$SSD_MOUNT_PATH" | tail -1

echo ""
echo "🔗 Estrutura de diretórios:"
if [ -d "$SSD_MOUNT_PATH/ethereum-data-hoodi" ]; then
    tree "$SSD_MOUNT_PATH/ethereum-data-hoodi" -L 2 2>/dev/null || ls -la "$SSD_MOUNT_PATH/ethereum-data-hoodi"
fi

echo ""
echo "✅ Verificação concluída!"
echo ""
echo "💡 Dicas:"
echo "   - Se algum arquivo estiver faltando, execute: ./scripts/start-hoodi.sh"
echo "   - Para ver logs: docker compose -f docker-compose-hoodi.yml logs"
echo "   - Para backup: tar -czf hoodi-backup.tar.gz $SSD_MOUNT_PATH/ethereum-data-hoodi/"
echo ""

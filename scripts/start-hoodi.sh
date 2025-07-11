#!/bin/bash
# Script para iniciar a testnet Hoodi
# Start script for Hoodi testnet

set -e

echo "🚀 Iniciando Rocket Pool Node - Testnet Hoodi"
echo "=============================================="

# Configurar diretório
cd "$(dirname "$0")/.."

# Verificar se o arquivo existe
if [ ! -f "docker-compose-hoodi.yml" ]; then
    echo "❌ Erro: docker-compose-hoodi.yml não encontrado!"
    exit 1
fi

# Verificar se o arquivo .env existe
if [ ! -f ".env.hoodi" ]; then
    echo "❌ Erro: .env.hoodi não encontrado!"
    exit 1
fi

# Carregar variáveis de ambiente primeiro
echo "📋 Carregando variáveis de ambiente..."
set -a
source .env.hoodi
set +a

# Verificar se o SSD está montado
if [ ! -d "$SSD_MOUNT_PATH" ]; then
    echo "❌ Erro: SSD não encontrado em $SSD_MOUNT_PATH"
    echo "   Verifique se o SSD está conectado e montado."
    exit 1
fi

# Criar diretórios necessários no SSD
echo "📁 Criando diretórios de dados no SSD..."
mkdir -p "$ROCKETPOOL_DATA_PATH/secrets"
mkdir -p "$ROCKETPOOL_DATA_PATH/.rocketpool"
mkdir -p "$EXECUTION_DATA_PATH"
mkdir -p "$CONSENSUS_DATA_PATH"
mkdir -p "$PROMETHEUS_DATA_PATH"
mkdir -p "$GRAFANA_DATA_PATH"
mkdir -p "$ALERTMANAGER_DATA_PATH"

# Verificar se user-settings.yml existe no SSD
if [ ! -f "$ROCKETPOOL_DATA_PATH/.rocketpool/user-settings.yml" ]; then
    echo "⚠️  Arquivo user-settings.yml não encontrado no SSD!"
    echo "   Esperado em: $ROCKETPOOL_DATA_PATH/.rocketpool/user-settings.yml"
    echo "   O Rocket Pool pode não funcionar corretamente sem este arquivo."
fi

# Gerar JWT secret se não existir
if [ ! -f "$ROCKETPOOL_DATA_PATH/secrets/jwtsecret" ]; then
    echo "🔐 Gerando JWT secret..."
    openssl rand -hex 32 > "$ROCKETPOOL_DATA_PATH/secrets/jwtsecret"
    echo "JWT secret gerado em $ROCKETPOOL_DATA_PATH/secrets/jwtsecret"
fi

# Configurar permissões
echo "🔒 Configurando permissões..."
chmod 600 "$ROCKETPOOL_DATA_PATH/secrets/jwtsecret"
chmod -R 755 "$ROCKETPOOL_DATA_PATH"
chmod -R 755 "$EXECUTION_DATA_PATH"
chmod -R 755 "$CONSENSUS_DATA_PATH"
chmod -R 755 "$PROMETHEUS_DATA_PATH"
chmod -R 755 "$GRAFANA_DATA_PATH"
chmod -R 755 "$ALERTMANAGER_DATA_PATH"

# Mostrar informações dos diretórios
echo "� Informações dos diretórios criados:"
echo "   - Rocket Pool: $ROCKETPOOL_DATA_PATH"
echo "   - Execution:   $EXECUTION_DATA_PATH"
echo "   - Consensus:   $CONSENSUS_DATA_PATH"
echo "   - Prometheus:  $PROMETHEUS_DATA_PATH"
echo "   - Grafana:     $GRAFANA_DATA_PATH"
echo "   - Alertmanager: $ALERTMANAGER_DATA_PATH"

# Iniciar serviços
echo "🐳 Iniciando containers Docker..."
docker compose -f docker-compose-hoodi.yml --env-file .env.hoodi up -d

# Aguardar inicialização
echo "⏱️  Aguardando inicialização dos serviços..."
sleep 10

# Verificar status
echo "📊 Verificando status dos serviços..."
docker compose -f docker-compose-hoodi.yml ps

echo ""
echo "✅ Rocket Pool Node - Testnet Hoodi iniciado com sucesso!"
echo ""
echo "🔗 URLs de acesso:"
echo "   - Grafana: http://localhost:3000 (admin/admin123)"
echo "   - Prometheus: http://localhost:9090"
echo "   - Geth RPC: http://localhost:8545"
echo "   - Lighthouse API: http://localhost:5052"
echo "   - Node Exporter: http://localhost:9100"
echo ""
echo "📝 Para monitorar logs:"
echo "   docker compose -f docker-compose-hoodi.yml logs -f [service]"
echo ""
echo "⚠️  Lembre-se de configurar port forwarding no roteador:"
echo "   - Geth P2P: 30304 (TCP/UDP)"
echo "   - Lighthouse P2P: 9001 (TCP/UDP)"
echo ""
echo "💾 Dados armazenados no SSD:"
echo "   - Caminho base: $SSD_MOUNT_PATH/ethereum-data-hoodi/"
echo "   - Uso estimado: ~80-150GB após sincronização completa"
echo ""

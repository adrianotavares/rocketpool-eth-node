#!/bin/bash
# Script para criar/verificar o arquivo user-settings.yml da Hoodi
# Create/verify user-settings.yml for Hoodi testnet

set -e

echo "🔧 Configuração do user-settings.yml - Testnet Hoodi"
echo "=================================================="

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

# Criar diretórios se não existirem
echo "📁 Verificando diretórios..."
mkdir -p "$ROCKETPOOL_DATA_PATH/.rocketpool"

# Função para criar o arquivo user-settings.yml
create_user_settings() {
    echo "📄 Criando user-settings.yml..."
    cat > "$ROCKETPOOL_DATA_PATH/.rocketpool/user-settings.yml" << 'EOF'
# Rocket Pool v1.16.0 - Configuração para Testnet Hoodi
# Baseado no template oficial (user-settings.template.yml)
# Configuração para Rocket Pool v1.16.0 em modo híbrido (Docker)
# Testnet Hoodi (Chain ID: 560048)

root:
  version: "1.16.0"
  network: "testnet"
  isNative: false
  executionClientMode: external
  consensusClientMode: external
  
  # URLs dos clientes externos (nomes dos containers Docker para Hoodi)
  externalExecutionHttpUrl: http://geth-hoodi:8545
  externalExecutionWsUrl: ws://geth-hoodi:8546
  externalConsensusHttpUrl: http://lighthouse-hoodi:5052
  
  # Configurações adicionais para testnet
  enableMetrics: true
  enableMevBoost: true

# Configurações específicas da Testnet Hoodi:
# - Chain ID: 560048 (0x89010 em hexadecimal)
# - Rede: Hoodi (nova geração de testnet)
# - Genesis: 2024-05-10 12:00:00 UTC
# - Checkpoint Sync: https://checkpoint-sync.hoodi.ethpandaops.io
# - Explorer: https://explorer.hoodi.ethpandaops.io/
# - ETH de teste: Disponível via faucets da EthPandaOps
# 
# Comandos básicos:
# - Status: docker exec -it rocketpool-node-hoodi rocketpool node status
# - Sync: docker exec -it rocketpool-node-hoodi rocketpool node sync
# - Wallet: docker exec -it rocketpool-node-hoodi rocketpool wallet status
# - Node: docker exec -it rocketpool-node-hoodi rocketpool node register
EOF

    # Configurar permissões
    chmod 644 "$ROCKETPOOL_DATA_PATH/.rocketpool/user-settings.yml"
    echo "✅ user-settings.yml criado com sucesso!"
}

# Verificar se o arquivo existe
USER_SETTINGS_FILE="$ROCKETPOOL_DATA_PATH/.rocketpool/user-settings.yml"

if [ -f "$USER_SETTINGS_FILE" ]; then
    echo "📄 Arquivo user-settings.yml encontrado em:"
    echo "   $USER_SETTINGS_FILE"
    echo ""
    
    # Verificar se o YAML é válido
    if python3 -c "import yaml; yaml.safe_load(open('$USER_SETTINGS_FILE'))" 2>/dev/null; then
        echo "✅ Arquivo YAML é válido"
        
        # Perguntar se o usuário quer recriar
        read -p "Deseja recriar o arquivo? (y/n): " recreate
        if [[ $recreate == "y" || $recreate == "Y" ]]; then
            create_user_settings
        else
            echo "📄 Mantendo arquivo existente"
        fi
    else
        echo "❌ Arquivo YAML inválido! Recriando..."
        create_user_settings
    fi
else
    echo "📄 Arquivo user-settings.yml não encontrado"
    echo "   Criando em: $USER_SETTINGS_FILE"
    create_user_settings
fi

echo ""
echo "📊 Informações do arquivo:"
echo "   📍 Local: $USER_SETTINGS_FILE"
echo "   📏 Tamanho: $(ls -lh "$USER_SETTINGS_FILE" | awk '{print $5}')"
echo "   🔒 Permissões: $(ls -l "$USER_SETTINGS_FILE" | awk '{print $1}')"

echo ""
echo "🧪 Testando sintaxe YAML..."
if python3 -c "import yaml; yaml.safe_load(open('$USER_SETTINGS_FILE'))" 2>/dev/null; then
    echo "✅ Sintaxe YAML válida!"
else
    echo "❌ Erro na sintaxe YAML!"
    exit 1
fi

echo ""
echo "✅ Configuração concluída!"
echo ""
echo "💡 Próximos passos:"
echo "   1. Iniciar a Hoodi: ./scripts/start-hoodi.sh"
echo "   2. Configurar Rocket Pool: ./scripts/setup-rocketpool-hoodi.sh"
echo ""

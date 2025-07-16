#!/bin/bash
# Script para configuração inicial do Rocket Pool na testnet Hoodi
# Setup script for Rocket Pool on Hoodi testnet

set -e

echo "🚀 Configuração Inicial do Rocket Pool - Testnet Hoodi"
echo "===================================================="

# Configurar diretório
cd "$(dirname "$0")/.."

# Verificar se os containers estão rodando
if ! docker ps --filter name=rocketpool-node-hoodi --format "{{.Names}}" | grep -q rocketpool-node-hoodi; then
    echo "❌ Erro: Container rocketpool-node-hoodi não está rodando!"
    echo "   Execute primeiro: ./scripts/start-hoodi.sh"
    exit 1
fi

# Função para executar comandos via API com timeout
rp_api() {
    timeout 30 docker exec rocketpool-node-hoodi rocketpool api "$@" 2>/dev/null || return 1
}

# Função para executar comandos CLI interativos
rp_cli() {
    docker exec -it rocketpool-node-hoodi rocketpool-cli --allow-root "$@"
}

echo "📋 Este script irá:"
echo "   1. Verificar/corrigir configuração"
echo "   2. Configurar senha da wallet"
echo "   3. Importar/criar wallet"
echo "   4. Verificar sincronização"
echo ""

# 1. Verificar e corrigir configuração se necessário
echo "1️⃣  Verificando configuração..."
echo "==============================="

# Testar conectividade atual
if ! rp_api node sync >/dev/null 2>&1; then
    echo "🔧 Corrigindo configuração de conectividade..."
    
    # Criar configuração para modo external com nomes corretos
    cat > /tmp/rocketpool-config.yml << 'EOF'
root:
  version: "1.16.0"
  network: "testnet"
  isNative: false
  executionClientMode: external
  consensusClientMode: external
  externalExecutionHttpUrl: http://geth-hoodi:8545
  externalExecutionWsUrl: ws://geth-hoodi:8546
  externalConsensusHttpUrl: http://lighthouse-hoodi:5052
  enableMetrics: true
  enableMevBoost: true
EOF
    
    docker cp /tmp/rocketpool-config.yml rocketpool-node-hoodi:/.rocketpool/user-settings.yml
    docker restart rocketpool-node-hoodi
    
    echo "⏳ Aguardando reinicialização..."
    sleep 20
    rm -f /tmp/rocketpool-config.yml
    echo "✅ Configuração corrigida!"
else
    echo "✅ Configuração OK!"
fi

echo ""

# 2. Configurar senha da wallet
echo "2️⃣  Configurando senha da wallet..."
echo "==================================="

wallet_status=$(rp_api wallet status || echo '{"passwordSet":false}')
password_set=$(echo "$wallet_status" | grep -o '"passwordSet":[^,]*' | cut -d':' -f2 | tr -d ' ')

if [[ "$password_set" != "true" ]]; then
    echo "🔐 Configurando senha padrão para testnet..."
    
    if rp_api wallet set-password "testnet123456"; then
        echo "✅ Senha configurada: testnet123456"
    else
        echo "⚠️  Falha ao configurar senha automaticamente"
        echo "   Configure manualmente depois com: rocketpool-cli wallet set-password"
    fi
else
    echo "✅ Senha já configurada!"
fi

echo ""

# 3. Verificar/criar wallet
echo "3️⃣  Configurando wallet..."
echo "=========================="

wallet_status=$(rp_api wallet status || echo '{"walletInitialized":false}')
wallet_initialized=$(echo "$wallet_status" | grep -o '"walletInitialized":[^,]*' | cut -d':' -f2 | tr -d ' ')

if [[ "$wallet_initialized" != "true" ]]; then
    echo "🦊 Para importar sua wallet MetaMask, digite a seed phrase (12/24 palavras):"
    echo "   Ou pressione ENTER para criar uma nova wallet"
    echo ""
    read -p "Seed phrase (opcional): " mnemonic_phrase
    echo ""
    
    if [ -n "$mnemonic_phrase" ]; then
        echo "🔄 Importando wallet da MetaMask..."
        if rp_cli wallet recover --mnemonic "$mnemonic_phrase"; then
            echo "✅ Wallet importada com sucesso!"
        else
            echo "❌ Erro ao importar. Verifique a seed phrase."
            exit 1
        fi
    else
        echo "🆕 Criando nova wallet..."
        if rp_cli wallet init; then
            echo "✅ Nova wallet criada!"
            echo "⚠️  IMPORTANTE: Anote sua seed phrase em local seguro!"
        else
            echo "❌ Erro ao criar wallet."
            exit 1
        fi
    fi
else
    echo "✅ Wallet já configurada!"
fi

echo ""

# 4. Verificar sincronização
echo "4️⃣  Verificando sincronização..."
echo "==============================="

echo "🔍 Verificando status dos clientes..."
if sync_status=$(rp_api node sync 2>/dev/null); then
    echo "✅ Clientes conectados!"
    echo ""
    
    # Mostrar status resumido
    if echo "$sync_status" | grep -q '"ecSynced":true' && echo "$sync_status" | grep -q '"bcSynced":true'; then
        echo "🎉 Ambos os clientes estão sincronizados!"
        echo ""
        echo "📝 Próximos passos:"
        echo "   1. Obter ETH de teste da Hoodi"
        echo "   2. Registrar nó: rocketpool-cli node register"
        echo "   3. Monitorar: http://localhost:3000 (Grafana)"
    else
        echo "⏳ Clientes ainda sincronizando..."
        echo "   Aguarde a sincronização completa antes de registrar o nó"
        echo ""
        echo "📊 Monitor: http://localhost:3000 (admin/admin123)"
    fi
else
    echo "⚠️  Problema na comunicação com clientes"
    echo "   Verifique logs: docker logs geth-hoodi"
    echo "                  docker logs lighthouse-hoodi"
fi

echo ""
echo "✅ Configuração inicial concluída!"
echo ""
echo "🔍 Comandos úteis:"
echo "   - Status: docker exec rocketpool-node-hoodi rocketpool api node status"
echo "   - Wallet: docker exec rocketpool-node-hoodi rocketpool api wallet status"
echo "   - Sync: docker exec rocketpool-node-hoodi rocketpool api node sync"
echo ""
echo "🌐 Recursos:"
echo "   - Explorer: https://explorer.hoodi.ethpandaops.io/"
echo "   - Grafana: http://localhost:3000"
echo ""

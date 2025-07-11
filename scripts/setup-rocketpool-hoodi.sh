#!/bin/bash
# Script para configurar o Rocket Pool na testnet Hoodi
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

echo "📋 Este script irá guiá-lo pela configuração inicial do Rocket Pool na Hoodi:"
echo "   1. Verificar status do nó"
echo "   2. Criar/importar wallet"
echo "   3. Registrar nó na rede"
echo "   4. Configurar taxa de comissão"
echo ""

# Função para executar comandos no container
rp_exec() {
    docker exec -it rocketpool-node-hoodi rocketpool "$@"
}

# 1. Verificar status do nó
echo "1️⃣  Verificando status do nó..."
echo "================================"
rp_exec node status
echo ""

# 2. Verificar se já existe uma wallet
echo "2️⃣  Verificando wallet..."
echo "========================"
if rp_exec wallet status 2>/dev/null | grep -q "No wallet found"; then
    echo "🆕 Nenhuma wallet encontrada. Vamos criar uma nova."
    echo ""
    echo "Escolha uma opção:"
    echo "a) Criar nova wallet"
    echo "b) Importar wallet existente"
    echo ""
    read -p "Digite sua escolha (a/b): " wallet_choice
    
    case $wallet_choice in
        a|A)
            echo "🔐 Criando nova wallet..."
            rp_exec wallet init
            ;;
        b|B)
            echo "📥 Importando wallet existente..."
            rp_exec wallet recover
            ;;
        *)
            echo "❌ Opção inválida!"
            exit 1
            ;;
    esac
else
    echo "✅ Wallet já existe!"
    rp_exec wallet status
fi

echo ""

# 3. Verificar sincronização antes de registrar
echo "3️⃣  Verificando sincronização..."
echo "==============================="
rp_exec node sync
echo ""

read -p "Os clientes estão sincronizados? (y/n): " synced
if [[ $synced != "y" && $synced != "Y" ]]; then
    echo "⏱️  Aguarde a sincronização completa antes de registrar o nó."
    echo "   Execute este script novamente quando estiver sincronizado."
    exit 0
fi

# 4. Registrar nó (se ainda não estiver registrado)
echo "4️⃣  Verificando registro do nó..."
echo "==============================="
if rp_exec node status | grep -q "The node is not registered"; then
    echo "📝 Registrando nó na rede Hoodi..."
    echo ""
    echo "⚠️  Você precisará de ETH de teste da Hoodi para pagar as taxas de gas."
    echo "   Faucet recomendado: Solicite na comunidade EthPandaOps"
    echo ""
    read -p "Continuar com o registro? (y/n): " register_choice
    
    if [[ $register_choice == "y" || $register_choice == "Y" ]]; then
        rp_exec node register
    else
        echo "⏸️  Registro cancelado. Execute este script novamente quando quiser registrar."
        exit 0
    fi
else
    echo "✅ Nó já está registrado!"
fi

echo ""

# 5. Configurar taxa de comissão (se ainda não configurada)
echo "5️⃣  Configurando taxa de comissão..."
echo "===================================="
echo "💡 Recomendação para testnet: 10-15%"
echo ""
read -p "Deseja configurar a taxa de comissão agora? (y/n): " commission_choice

if [[ $commission_choice == "y" || $commission_choice == "Y" ]]; then
    read -p "Digite a taxa de comissão desejada (ex: 15 para 15%): " commission_rate
    rp_exec node set-commission-rate $commission_rate
fi

echo ""
echo "✅ Configuração inicial concluída!"
echo ""
echo "🔍 Comandos úteis para monitoramento:"
echo "   - Status geral: docker exec -it rocketpool-node-hoodi rocketpool node status"
echo "   - Status wallet: docker exec -it rocketpool-node-hoodi rocketpool wallet status"
echo "   - Sincronização: docker exec -it rocketpool-node-hoodi rocketpool node sync"
echo "   - Recompensas: docker exec -it rocketpool-node-hoodi rocketpool node rewards"
echo ""
echo "🌐 Recursos da Hoodi:"
echo "   - Explorer: https://explorer.hoodi.ethpandaops.io/"
echo "   - Checkpoint: https://checkpoint-sync.hoodi.ethpandaops.io"
echo "   - Grafana: http://localhost:3000 (admin/admin123)"
echo ""
echo "📚 Próximos passos:"
echo "   1. Aguardar sincronização completa"
echo "   2. Obter ETH de teste para staking"
echo "   3. Configurar validadores (se aplicável)"
echo "   4. Monitorar performance via Grafana"
echo ""

#!/bin/bash
# Script de diagnóstico para Testnet Hoodi
# Diagnostic script for Hoodi testnet

set -e

echo "🔍 Diagnóstico Rocket Pool Node - Testnet Hoodi"
echo "=============================================="

# Configurar diretório
cd "$(dirname "$0")/.."

# Verificar se os containers estão rodando
echo "📊 Status dos containers:"
echo "========================"
if docker compose -f docker-compose-hoodi.yml ps | grep -q "Up"; then
    docker compose -f docker-compose-hoodi.yml ps
else
    echo "❌ Nenhum container rodando. Execute ./scripts/start-hoodi.sh primeiro."
    exit 1
fi

echo ""
echo "🔍 Diagnóstico detalhado:"
echo "========================"

# Verificar Geth
echo ""
echo "🔗 Geth (Execution Client) - Status:"
if docker exec geth-hoodi geth attach --exec "eth.syncing" > /tmp/geth_sync.json 2>/dev/null; then
    sync_status=$(cat /tmp/geth_sync.json)
    if [ "$sync_status" = "false" ]; then
        echo "✅ Geth: Totalmente sincronizado"
    else
        echo "🔄 Geth: Sincronizando..."
        current_block=$(docker exec geth-hoodi geth attach --exec "eth.blockNumber" 2>/dev/null || echo "0")
        echo "   Bloco atual: $current_block"
    fi
else
    echo "❌ Geth: Não responsivo"
fi

# Verificar peers do Geth
echo ""
echo "👥 Geth - Peers conectados:"
peer_count=$(docker exec geth-hoodi geth attach --exec "net.peerCount" 2>/dev/null || echo "0")
echo "   Peers: $peer_count"
if [ "$peer_count" -lt 5 ]; then
    echo "⚠️  Baixo número de peers. Verifique conectividade de rede."
fi

# Verificar Lighthouse
echo ""
echo "🏮 Lighthouse (Consensus Client) - Status:"
if curl -s http://localhost:5052/eth/v1/node/health > /dev/null 2>&1; then
    echo "✅ Lighthouse: API responsiva"
    
    # Verificar sync status
    sync_info=$(curl -s http://localhost:5052/eth/v1/node/syncing 2>/dev/null || echo '{"data":{"is_syncing":true}}')
    is_syncing=$(echo $sync_info | jq -r '.data.is_syncing' 2>/dev/null || echo "true")
    
    if [ "$is_syncing" = "false" ]; then
        echo "✅ Lighthouse: Totalmente sincronizado"
    else
        echo "🔄 Lighthouse: Sincronizando..."
    fi
    
    # Verificar peers do Lighthouse
    peers_info=$(curl -s http://localhost:5052/eth/v1/node/peer_count 2>/dev/null || echo '{"data":{"connected":"0"}}')
    connected_peers=$(echo $peers_info | jq -r '.data.connected' 2>/dev/null || echo "0")
    echo "   Peers conectados: $connected_peers"
    
    if [ "$connected_peers" -lt 5 ]; then
        echo "⚠️  Baixo número de peers. Verifique conectividade de rede."
    fi
else
    echo "❌ Lighthouse: API não responsiva"
fi

# Verificar MEV-Boost
echo ""
echo "⚡ MEV-Boost - Status:"
if curl -s http://localhost:18550/eth/v1/builder/status > /dev/null 2>&1; then
    echo "✅ MEV-Boost: Responsivo"
else
    echo "❌ MEV-Boost: Não responsivo"
fi

# Verificar uso de disco
echo ""
echo "💾 Uso de disco:"
echo "==============="
if [ -d "execution-data-hoodi" ]; then
    exec_size=$(du -sh execution-data-hoodi 2>/dev/null || echo "0B")
    echo "   Execution data: $exec_size"
fi

if [ -d "consensus-data-hoodi" ]; then
    cons_size=$(du -sh consensus-data-hoodi 2>/dev/null || echo "0B")
    echo "   Consensus data: $cons_size"
fi

# Verificar logs recentes para erros
echo ""
echo "📝 Últimos logs (erros/warnings):"
echo "================================="
echo "Geth errors:"
docker compose -f docker-compose-hoodi.yml logs --tail=20 geth 2>/dev/null | grep -i "error\|fatal\|panic" | tail -5 || echo "   Nenhum erro recente"

echo ""
echo "Lighthouse errors:"
docker compose -f docker-compose-hoodi.yml logs --tail=20 lighthouse 2>/dev/null | grep -i "error\|fatal\|panic\|warn" | tail -5 || echo "   Nenhum erro recente"

# Verificar conectividade de rede
echo ""
echo "🌐 Teste de conectividade:"
echo "========================="

# Teste ping para checkpoint sync
if ping -c 1 checkpoint-sync.hoodi.ethpandaops.io > /dev/null 2>&1; then
    echo "✅ Checkpoint sync server: Acessível"
else
    echo "❌ Checkpoint sync server: Inacessível"
fi

# Teste de porta P2P
echo ""
echo "🔌 Portas P2P (requer port forwarding no roteador):"
if netstat -tuln | grep -q ":30303"; then
    echo "✅ Geth P2P (30303): Listening"
else
    echo "❌ Geth P2P (30303): Não está listening"
fi

if netstat -tuln | grep -q ":9000"; then
    echo "✅ Lighthouse P2P (9000): Listening"
else
    echo "❌ Lighthouse P2P (9000): Não está listening"
fi

echo ""
echo "🎯 Recomendações:"
echo "================"
echo "1. Monitore o progresso de sync via Grafana: http://localhost:3000"
echo "2. Configuração de port forwarding é essencial para peers P2P"
echo "3. Aguarde sync completo antes de validar (pode levar horas)"
echo "4. Monitor recursos do sistema (CPU, RAM, disco)"
echo ""
echo "📊 URLs úteis:"
echo "   - Grafana: http://localhost:3000"
echo "   - Prometheus: http://localhost:9090"
echo "   - Lighthouse API: http://localhost:5052/eth/v1/node/health"
echo ""

# Cleanup
rm -f /tmp/geth_sync.json

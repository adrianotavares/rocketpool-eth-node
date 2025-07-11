#!/bin/bash

# ====================================================
# Script: Diagnóstico Completo Geth Holesky
# Descrição: Verifica estado de sincronização do Geth
# Autor: Lighthouse Holesky Optimization
# Data: $(date +"%Y-%m-%d")
# ====================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
CONTAINER_NAME="geth"
LOG_FILE="logs/geth-sync-$(date +%Y%m%d-%H%M%S).log"

# Criar diretório de logs
mkdir -p logs

echo -e "${BLUE}🔍 Diagnóstico Completo - Geth Holesky${NC}"
echo "========================================"

# Função para log
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Função para conversão hex para decimal
hex_to_decimal() {
    printf "%d\n" $1 2>/dev/null || echo "0"
}

# Função para formatação de bytes
format_bytes() {
    local bytes=$1
    if [ $bytes -gt 1073741824 ]; then
        echo "$(echo "scale=2; $bytes / 1073741824" | bc)GB"
    elif [ $bytes -gt 1048576 ]; then
        echo "$(echo "scale=2; $bytes / 1048576" | bc)MB"
    elif [ $bytes -gt 1024 ]; then
        echo "$(echo "scale=2; $bytes / 1024" | bc)KB"
    else
        echo "${bytes}B"
    fi
}

# 1. Verificar se container está rodando
log_message "Verificando status do container Geth..."
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}❌ Container $CONTAINER_NAME não está rodando${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Container Geth rodando${NC}"

# 2. Verificar recursos do sistema
log_message "Verificando uso de recursos..."
STATS=$(docker stats geth --no-stream --format "{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}")
CPU_USAGE=$(echo "$STATS" | cut -f1)
MEM_USAGE=$(echo "$STATS" | cut -f2)
NET_IO=$(echo "$STATS" | cut -f3)
BLOCK_IO=$(echo "$STATS" | cut -f4)

echo -e "${BLUE}📊 Recursos do Sistema:${NC}"
echo "  CPU: $CPU_USAGE"
echo "  RAM: $MEM_USAGE"
echo "  Network I/O: $NET_IO"
echo "  Disk I/O: $BLOCK_IO"

# 3. Verificar peers
log_message "Verificando peers..."
PEER_COUNT_HEX=$(curl -s -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "0x0")
PEER_COUNT=$(hex_to_decimal "$PEER_COUNT_HEX")

echo -e "${BLUE}👥 Peers Conectados: ${GREEN}$PEER_COUNT${NC}"

if [ "$PEER_COUNT" -gt 10 ]; then
    echo -e "${GREEN}✅ Boa conectividade (>10 peers)${NC}"
elif [ "$PEER_COUNT" -gt 5 ]; then
    echo -e "${YELLOW}⚠️ Conectividade moderada (5-10 peers)${NC}"
else
    echo -e "${RED}❌ Conectividade baixa (<5 peers)${NC}"
fi

# 4. Verificar sincronização
log_message "Verificando sincronização..."
SYNC_STATUS=$(curl -s -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "false")

echo -e "${BLUE}🔄 Status de Sincronização:${NC}"

if [ "$SYNC_STATUS" = "false" ]; then
    echo -e "${GREEN}✅ Sincronização completa${NC}"
    
    # Verificar bloco atual
    BLOCK_NUMBER_HEX=$(curl -s -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "0x0")
    BLOCK_NUMBER=$(hex_to_decimal "$BLOCK_NUMBER_HEX")
    
    echo -e "${BLUE}📦 Bloco Atual: ${GREEN}$BLOCK_NUMBER${NC}"
    
else
    echo -e "${YELLOW}⚠️ Sincronização em progresso${NC}"
    
    # Extrair informações de sincronização
    CURRENT_BLOCK_HEX=$(echo "$SYNC_STATUS" | jq -r '.currentBlock' 2>/dev/null || echo "0x0")
    HIGHEST_BLOCK_HEX=$(echo "$SYNC_STATUS" | jq -r '.highestBlock' 2>/dev/null || echo "0x0")
    
    CURRENT_BLOCK=$(hex_to_decimal "$CURRENT_BLOCK_HEX")
    HIGHEST_BLOCK=$(hex_to_decimal "$HIGHEST_BLOCK_HEX")
    
    if [ "$HIGHEST_BLOCK" -gt 0 ]; then
        SYNC_PROGRESS=$(echo "scale=2; $CURRENT_BLOCK * 100 / $HIGHEST_BLOCK" | bc)
        BLOCKS_BEHIND=$((HIGHEST_BLOCK - CURRENT_BLOCK))
        
        echo -e "${BLUE}📊 Progresso: ${YELLOW}${SYNC_PROGRESS}%${NC}"
        echo -e "${BLUE}📦 Bloco Atual: ${GREEN}$CURRENT_BLOCK${NC}"
        echo -e "${BLUE}📦 Bloco Mais Alto: ${GREEN}$HIGHEST_BLOCK${NC}"
        echo -e "${BLUE}📉 Blocos Atrás: ${YELLOW}$BLOCKS_BEHIND${NC}"
    else
        echo -e "${RED}❌ Não foi possível obter informações de sincronização${NC}"
    fi
    
    # Verificar informações de state sync
    SYNCED_ACCOUNTS_HEX=$(echo "$SYNC_STATUS" | jq -r '.syncedAccounts' 2>/dev/null || echo "0x0")
    SYNCED_ACCOUNTS=$(hex_to_decimal "$SYNCED_ACCOUNTS_HEX")
    
    if [ "$SYNCED_ACCOUNTS" -gt 0 ]; then
        echo -e "${BLUE}💾 Contas Sincronizadas: ${GREEN}$(printf "%'d" $SYNCED_ACCOUNTS)${NC}"
    fi
fi

# 5. Verificar logs recentes
log_message "Analisando logs recentes..."
echo -e "${BLUE}📋 Logs Recentes (últimos 5 minutos):${NC}"

# Verificar tipos de log
SYNC_LOGS=$(docker logs geth --since 5m | grep -i "sync" | wc -l)
ERROR_LOGS=$(docker logs geth --since 5m | grep -i "error\|failed" | wc -l)
WARN_LOGS=$(docker logs geth --since 5m | grep -i "warn" | wc -l)

echo -e "${BLUE}  Logs de Sync: ${GREEN}$SYNC_LOGS${NC}"
echo -e "${BLUE}  Logs de Error: ${RED}$ERROR_LOGS${NC}"
echo -e "${BLUE}  Logs de Warning: ${YELLOW}$WARN_LOGS${NC}"

# Mostrar últimos logs importantes
echo -e "${BLUE}🔍 Últimos Logs Importantes:${NC}"
docker logs geth --tail 10 | grep -E "(INFO|WARN|ERROR)" | tail -5

# 6. Verificar conectividade de rede
log_message "Verificando conectividade de rede..."
echo -e "${BLUE}🌐 Conectividade de Rede:${NC}"

# Testar portas
if nc -z localhost 8545 2>/dev/null; then
    echo -e "${GREEN}✅ Porta 8545 (HTTP RPC): OK${NC}"
else
    echo -e "${RED}❌ Porta 8545 (HTTP RPC): FALHA${NC}"
fi

if nc -z localhost 8546 2>/dev/null; then
    echo -e "${GREEN}✅ Porta 8546 (WebSocket): OK${NC}"
else
    echo -e "${RED}❌ Porta 8546 (WebSocket): FALHA${NC}"
fi

if nc -z localhost 8551 2>/dev/null; then
    echo -e "${GREEN}✅ Porta 8551 (Auth RPC): OK${NC}"
else
    echo -e "${RED}❌ Porta 8551 (Auth RPC): FALHA${NC}"
fi

# 7. Verificar espaço em disco
log_message "Verificando espaço em disco..."
DISK_USAGE=$(df -h ./execution-data-holesky 2>/dev/null | tail -1 | awk '{print $3 " / " $2 " (" $5 ")"}' || echo "N/A")
echo -e "${BLUE}💾 Uso do Disco: ${GREEN}$DISK_USAGE${NC}"

# 8. Resumo e diagnóstico
echo ""
echo -e "${BLUE}📋 RESUMO DO DIAGNÓSTICO${NC}"
echo "========================"
echo -e "Container: ${GREEN}Rodando${NC}"
echo -e "Peers: ${GREEN}$PEER_COUNT${NC}"
echo -e "CPU: ${GREEN}$CPU_USAGE${NC}"
echo -e "RAM: ${GREEN}$MEM_USAGE${NC}"

if [ "$SYNC_STATUS" = "false" ]; then
    echo -e "Sincronização: ${GREEN}Completa${NC}"
else
    echo -e "Sincronização: ${YELLOW}Em progresso${NC}"
fi

echo -e "Logs Error: ${RED}$ERROR_LOGS${NC}"
echo -e "Logs Warning: ${YELLOW}$WARN_LOGS${NC}"

# 9. Recomendações
echo ""
echo -e "${BLUE}🎯 RECOMENDAÇÕES${NC}"
echo "================"

if [ "$SYNC_STATUS" != "false" ]; then
    echo -e "1. ${YELLOW}⚠️ Aguarde a sincronização completa${NC}"
    echo -e "   - Processo normal para testnet Holesky"
    echo -e "   - Pode demorar várias horas"
fi

if [ "$PEER_COUNT" -lt 10 ]; then
    echo -e "2. ${YELLOW}⚠️ Considere port forwarding${NC}"
    echo -e "   - Porta 30303 TCP/UDP"
    echo -e "   - Melhora conectividade P2P"
fi

if [ "$ERROR_LOGS" -gt 5 ]; then
    echo -e "3. ${RED}❌ Investigue erros nos logs${NC}"
    echo -e "   - Execute: docker logs geth | grep ERROR"
fi

echo ""
echo -e "${BLUE}📊 MONITORAMENTO CONTÍNUO${NC}"
echo "========================="
echo "• Sync Status: curl -s -H 'Content-Type: application/json' -X POST --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_syncing\",\"params\":[],\"id\":1}' http://localhost:8545 | jq"
echo "• Peers: curl -s -H 'Content-Type: application/json' -X POST --data '{\"jsonrpc\":\"2.0\",\"method\":\"net_peerCount\",\"params\":[],\"id\":1}' http://localhost:8545 | jq"
echo "• Logs: docker logs geth --tail 20"

log_message "Diagnóstico concluído - Peers: $PEER_COUNT, Sync: $SYNC_STATUS"

echo ""
echo -e "${GREEN}✅ Diagnóstico concluído! Log salvo em: $LOG_FILE${NC}"

#!/bin/bash

# Monitor específico para peers do Lighthouse na Holesky
# Script para análise detalhada da conectividade P2P

set -e

LIGHTHOUSE_API="http://localhost:5052"
LOG_FILE="/tmp/lighthouse-peers-$(date +%Y%m%d).log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===================================${NC}"
echo -e "${BLUE}   LIGHTHOUSE PEER MONITORING      ${NC}"
echo -e "${BLUE}===================================${NC}"
echo -e "Data: $(date)"
echo -e "Log: $LOG_FILE"
echo

# Função para verificar se o Lighthouse está rodando
check_lighthouse() {
    if ! curl -s $LIGHTHOUSE_API/eth/v1/node/health > /dev/null 2>&1; then
        echo -e "${RED}❌ Lighthouse não está acessível em $LIGHTHOUSE_API${NC}"
        echo -e "${YELLOW}Verifique se o container está rodando: docker ps | grep lighthouse${NC}"
        exit 1
    fi
}

# Função para obter contagem de peers
get_peer_count() {
    local peer_data=$(curl -s $LIGHTHOUSE_API/eth/v1/node/peer_count)
    local connected=$(echo "$peer_data" | jq -r '.data.connected')
    local connecting=$(echo "$peer_data" | jq -r '.data.connecting')
    local disconnected=$(echo "$peer_data" | jq -r '.data.disconnected')
    local total=$((connected + connecting + disconnected))
    
    echo -e "${BLUE}📊 PEER COUNT SUMMARY${NC}"
    echo -e "  Connected:    ${GREEN}$connected${NC}"
    echo -e "  Connecting:   ${YELLOW}$connecting${NC}"
    echo -e "  Disconnected: ${RED}$disconnected${NC}"
    echo -e "  Total Known:  $total"
    echo
    
    # Log timestamped data
    echo "$(date): Connected=$connected, Connecting=$connecting, Disconnected=$disconnected" >> $LOG_FILE
}

# Função para obter detalhes dos peers conectados
get_connected_peers() {
    echo -e "${BLUE}🔗 CONNECTED PEERS DETAILS${NC}"
    
    local connected_peers=$(curl -s $LIGHTHOUSE_API/eth/v1/node/peers | jq -r '.data[] | select(.state == "connected")')
    
    if [ -z "$connected_peers" ]; then
        echo -e "${RED}  Nenhum peer conectado no momento${NC}"
        return
    fi
    
    echo "$connected_peers" | jq -r '
        "  ID: " + .peer_id[0:20] + "..." +
        " | Direction: " + .direction +
        " | Address: " + .last_seen_p2p_address
    ' | while read -r line; do
        echo -e "  $line"
    done
    echo
}

# Função para análise de conectividade
analyze_connectivity() {
    echo -e "${BLUE}📡 CONNECTIVITY ANALYSIS${NC}"
    
    # Verificar se as portas estão abertas
    local tcp_port=$(netstat -tlnp 2>/dev/null | grep :9000 | head -1)
    local udp_port=$(netstat -ulnp 2>/dev/null | grep :9000 | head -1)
    
    if [ -n "$tcp_port" ]; then
        echo -e "  TCP Port 9000: ${GREEN}✅ Open${NC}"
    else
        echo -e "  TCP Port 9000: ${RED}❌ Closed${NC}"
    fi
    
    if [ -n "$udp_port" ]; then
        echo -e "  UDP Port 9000: ${GREEN}✅ Open${NC}"
    else
        echo -e "  UDP Port 9000: ${RED}❌ Closed${NC}"
    fi
    
    # Verificar UPnP nos logs
    local upnp_error=$(docker logs lighthouse 2>&1 | grep -i "upnp" | tail -1)
    if [ -n "$upnp_error" ]; then
        echo -e "  UPnP Status: ${YELLOW}⚠️ Not supported${NC}"
        echo -e "    $upnp_error"
    fi
    echo
}

# Função para verificar status de sincronização
check_sync_status() {
    echo -e "${BLUE}⚡ SYNC STATUS${NC}"
    
    local sync_data=$(curl -s $LIGHTHOUSE_API/eth/v1/node/syncing)
    local is_syncing=$(echo "$sync_data" | jq -r '.data.is_syncing')
    
    if [ "$is_syncing" = "false" ]; then
        echo -e "  Status: ${GREEN}✅ Synchronized${NC}"
    else
        echo -e "  Status: ${YELLOW}🔄 Syncing${NC}"
        echo "$sync_data" | jq -r '.data | 
            "  Head Slot: " + (.head_slot // "unknown") +
            " | Sync Distance: " + (.sync_distance // "unknown")'
    fi
    echo
}

# Função para verificar logs recentes relacionados a peers
check_recent_logs() {
    echo -e "${BLUE}📋 RECENT PEER LOGS${NC}"
    
    local peer_logs=$(docker logs lighthouse --tail=10 2>&1 | grep -i "peer\|connection" | tail -5)
    
    if [ -n "$peer_logs" ]; then
        echo "$peer_logs" | while read -r line; do
            if echo "$line" | grep -q "Low peer count"; then
                echo -e "  ${YELLOW}⚠️ $line${NC}"
            elif echo "$line" | grep -q "peers:"; then
                echo -e "  ${GREEN}ℹ️ $line${NC}"
            else
                echo -e "  $line"
            fi
        done
    else
        echo -e "  ${GREEN}Nenhum log recente sobre peers${NC}"
    fi
    echo
}

# Função para verificar discovery
check_discovery() {
    echo -e "${BLUE}🔍 DISCOVERY STATUS${NC}"
    
    # Verificar ENR nos logs
    local enr_log=$(docker logs lighthouse 2>&1 | grep "ENR Initialised" | tail -1)
    if [ -n "$enr_log" ]; then
        echo -e "  ENR: ${GREEN}✅ Initialized${NC}"
        local enr=$(echo "$enr_log" | grep -o "enr:[^,]*")
        echo -e "    Latest ENR: ${enr:0:50}..."
    else
        echo -e "  ENR: ${RED}❌ Not found${NC}"
    fi
    
    # Verificar discovery port
    local discovery_log=$(docker logs lighthouse 2>&1 | grep -i "discovery port" | tail -1)
    if [ -n "$discovery_log" ]; then
        echo -e "  Discovery: ${YELLOW}⚠️ $discovery_log${NC}"
    fi
    echo
}

# Função para recomendações baseadas no status atual
provide_recommendations() {
    echo -e "${BLUE}💡 RECOMMENDATIONS${NC}"
    
    local connected_count=$(curl -s $LIGHTHOUSE_API/eth/v1/node/peer_count | jq -r '.data.connected')
    
    if [ "$connected_count" -lt 5 ]; then
        echo -e "  ${RED}📌 Baixa contagem de peers ($connected_count)${NC}"
        echo -e "    • Verificar configuração de firewall/router"
        echo -e "    • Considerar adicionar bootstrap nodes"
        echo -e "    • Verificar se portas 9000 TCP/UDP estão abertas"
        echo -e "    • Para testnet Holesky, 5-15 peers são adequados"
        echo
    elif [ "$connected_count" -lt 10 ]; then
        echo -e "  ${YELLOW}📌 Contagem de peers adequada ($connected_count)${NC}"
        echo -e "    • Status normal para testnet Holesky"
        echo -e "    • Monitorar estabilidade das conexões"
        echo
    else
        echo -e "  ${GREEN}📌 Boa contagem de peers ($connected_count)${NC}"
        echo -e "    • Conectividade excelente para testnet"
        echo
    fi
    
    # Verificar se há backfill sync issues
    local backfill_issues=$(docker logs lighthouse --tail=20 2>&1 | grep -c "insufficient_synced_peers")
    if [ "$backfill_issues" -gt 0 ]; then
        echo -e "  ${YELLOW}📌 Backfill sync pausado ($backfill_issues vezes)${NC}"
        echo -e "    • Comportamento esperado com poucos peers"
        echo -e "    • Sincronização principal não afetada"
        echo
    fi
}

# Função principal de monitoramento
main() {
    check_lighthouse
    get_peer_count
    get_connected_peers
    analyze_connectivity
    check_sync_status
    check_recent_logs
    check_discovery
    provide_recommendations
    
    echo -e "${BLUE}===================================${NC}"
    echo -e "${GREEN}✅ Monitoramento concluído${NC}"
    echo -e "📊 Dados salvos em: $LOG_FILE"
    echo
    
    # Opção para monitoramento contínuo
    if [ "$1" = "--continuous" ]; then
        echo -e "${YELLOW}🔄 Modo contínuo ativo (atualizando a cada 30s)${NC}"
        echo -e "   Pressione Ctrl+C para parar"
        echo
        while true; do
            sleep 30
            echo -e "\n$(date): Atualizando..."
            get_peer_count
            get_connected_peers
        done
    fi
}

# Executar monitoramento
main "$@"

#!/bin/bash

# Script simplificado para monitorar o status do Rocket Pool Holesky

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== ROCKET POOL HOLESKY STATUS ===${NC}"
echo -e "${BLUE}Data/Hora:${NC} $(date)"
echo ""

# Containers
echo -e "${CYAN}📦 CONTAINERS:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(geth|lighthouse|rocketpool|prometheus|grafana|node-exporter)" | while read -r line; do
    if [ "$line" != "NAMES	STATUS" ] && [ -n "$line" ]; then
        name=$(echo "$line" | awk '{print $1}')
        status=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
        
        if [[ "$status" == "Up"* ]]; then
            echo -e "${GREEN}✅ $name:${NC} $status"
        else
            echo -e "${RED}❌ $name:${NC} $status"
        fi
    fi
done
echo ""

# Sincronização do Geth
echo -e "${CYAN}⚡ SINCRONIZAÇÃO:${NC}"
GETH_LOG=$(docker logs geth --tail 3 2>&1 | grep "Syncing:" | tail -1)
if [ -n "$GETH_LOG" ]; then
    GETH_SYNC=$(echo "$GETH_LOG" | grep -o 'synced=[0-9]*\.[0-9]*%' | sed 's/synced=//')
    GETH_ETA=$(echo "$GETH_LOG" | grep -o 'eta=[0-9a-z.]*' | sed 's/eta=//')
    
    if [ -n "$GETH_SYNC" ]; then
        echo -e "${YELLOW}🔄 Geth Sync:${NC} $GETH_SYNC (ETA: $GETH_ETA)"
    else
        echo -e "${RED}❌ Geth Sync:${NC} Status não disponível"
    fi
else
    echo -e "${RED}❌ Geth Sync:${NC} Logs não disponíveis"
fi

# Lighthouse
if docker logs lighthouse --tail 20 2>&1 | grep -q "Block production enabled"; then
    echo -e "${GREEN}✅ Lighthouse:${NC} Conectado ao Geth"
else
    echo -e "${YELLOW}⏳ Lighthouse:${NC} Aguardando Geth sincronizar"
fi
echo ""

# Prometheus targets
echo -e "${CYAN}📊 PROMETHEUS TARGETS:${NC}"
if command -v curl >/dev/null 2>&1; then
    curl -s http://localhost:9090/api/v1/targets 2>/dev/null | jq -r '.data.activeTargets[] | "\(.labels.job) - \(.health)"' 2>/dev/null | while IFS=' - ' read -r job health; do
        if [ "$health" = "up" ]; then
            echo -e "${GREEN}✅ $job${NC}"
        else
            echo -e "${RED}❌ $job${NC}"
        fi
    done || echo -e "${YELLOW}⚠️  Prometheus não acessível${NC}"
else
    echo -e "${YELLOW}⚠️  curl não disponível${NC}"
fi
echo ""

# Dashboards
echo -e "${CYAN}📈 DASHBOARDS:${NC}"
HOLESKY_COUNT=$(find /Users/adrianotavares/dev/rocketpool-eth-node/grafana/provisioning/dashboards/Holesky -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
ETHEREUM_COUNT=$(find /Users/adrianotavares/dev/rocketpool-eth-node/grafana/provisioning/dashboards/Ethereum -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
RECOMMENDED_COUNT=$(find /Users/adrianotavares/dev/rocketpool-eth-node/grafana/provisioning/dashboards/Recommended -name "*.json" 2>/dev/null | wc -l | tr -d ' ')

echo -e "${GREEN}✅ Holesky:${NC} $HOLESKY_COUNT dashboards"
echo -e "${GREEN}✅ Ethereum:${NC} $ETHEREUM_COUNT dashboards"
echo -e "${GREEN}✅ Recomendados:${NC} $RECOMMENDED_COUNT dashboards"
echo -e "${BLUE}📊 Total:${NC} $((HOLESKY_COUNT + ETHEREUM_COUNT + RECOMMENDED_COUNT)) dashboards"
echo ""

# URLs
echo -e "${CYAN}🌐 SERVIÇOS:${NC}"
echo -e "${GREEN}• Grafana:${NC} http://localhost:3000"
echo -e "${GREEN}• Prometheus:${NC} http://localhost:9090"
echo -e "${GREEN}• Rocket Pool:${NC} http://localhost:8000"
echo ""

# Status final
if [ -n "$GETH_SYNC" ]; then
    SYNC_NUM=$(echo "$GETH_SYNC" | sed 's/%//' | cut -d. -f1)
    if [ "$SYNC_NUM" -ge 100 ] 2>/dev/null; then
        echo -e "${GREEN}🎉 Status: Tudo sincronizado! Dashboards totalmente funcionais.${NC}"
    elif [ "$SYNC_NUM" -gt 95 ] 2>/dev/null; then
        echo -e "${YELLOW}🚀 Status: Quase pronto! Dashboards do Lighthouse em breve.${NC}"
    else
        echo -e "${YELLOW}⏳ Status: Aguardando sincronização. ETA: $GETH_ETA${NC}"
    fi
else
    echo -e "${RED}❌ Status: Verificar logs do Geth${NC}"
fi

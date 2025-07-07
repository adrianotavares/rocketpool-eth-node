#!/bin/bash

# Status completo da infraestrutura Holesky
# Script para verificar o estado de todos os serviços

# Mudar para o diretório raiz do projeto
cd "$(dirname "$0")/../.."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Status da Infraestrutura Rocket Pool Holesky${NC}"
echo "=============================================="
echo

# 1. Status dos containers
echo -e "${YELLOW}Status dos Containers:${NC}"
docker-compose -f docker-compose-holesky.yml ps
echo

# 2. Status da sincronização
echo -e "${YELLOW}Status da Sincronização:${NC}"

# Geth status
echo -e "${BLUE}Geth (Execution Layer):${NC}"
GETH_SYNCING=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result')

if [ "$GETH_SYNCING" = "false" ]; then
    echo -e "  Status: ${GREEN}Sincronizado${NC}"
else
    CURRENT_BLOCK=$(echo $GETH_SYNCING | jq -r '.currentBlock' | xargs printf "%d")
    HIGHEST_BLOCK=$(echo $GETH_SYNCING | jq -r '.knownStates' | xargs printf "%d" 2>/dev/null || echo $GETH_SYNCING | jq -r '.highestBlock' | xargs printf "%d")
    PROGRESS=$(echo "scale=2; $CURRENT_BLOCK * 100 / $HIGHEST_BLOCK" | bc 2>/dev/null || echo "calculando...")
    echo -e "  Status: ${YELLOW}Sincronizando${NC}"
    echo -e "  Progresso: $CURRENT_BLOCK / $HIGHEST_BLOCK blocks (${PROGRESS}%)"
fi

# Lighthouse status
echo -e "${BLUE}Lighthouse (Consensus Layer):${NC}"
LIGHTHOUSE_STATUS=$(curl -s http://localhost:5052/eth/v1/node/health -w "%{http_code}")
HTTP_CODE="${LIGHTHOUSE_STATUS: -3}"

case $HTTP_CODE in
    "200")
        echo -e "  Status: ${GREEN}Sincronizado${NC}"
        ;;
    "206")
        echo -e "  Status: ${YELLOW}Sincronizando${NC}"
        # Pegar info de sincronização dos logs
        SYNC_INFO=$(docker logs consensus-client-holesky 2>&1 | grep "distance:" | tail -1 | grep -o "distance: [^,]*")
        if [ ! -z "$SYNC_INFO" ]; then
            echo -e "  $SYNC_INFO"
        fi
        ;;
    *)
        echo -e "  Status: ${RED}Não responsivo${NC}"
        ;;
esac
echo

# 3. Status do monitoramento
echo -e "${YELLOW}Status do Monitoramento:${NC}"

# Prometheus
PROM_STATUS=$(curl -s http://localhost:9090/-/healthy 2>/dev/null && echo "OK" || echo "FAIL")
if [ "$PROM_STATUS" = "OK" ]; then
    echo -e "  Prometheus: ${GREEN}Online${NC} (http://localhost:9090)"
else
    echo -e "  Prometheus: ${RED}Offline${NC}"
fi

# Grafana
GRAFANA_STATUS=$(curl -s http://localhost:3000/api/health 2>/dev/null | jq -r '.database' 2>/dev/null || echo "FAIL")
if [ "$GRAFANA_STATUS" = "ok" ]; then
    echo -e "  Grafana: ${GREEN}Online${NC} (http://localhost:3000)"
    echo -e "    Login: admin/admin"
else
    echo -e "  Grafana: ${RED}Offline${NC}"
fi

# Targets do Prometheus
echo -e "${BLUE}Targets do Prometheus:${NC}"
TARGETS=$(curl -s "http://localhost:9090/api/v1/query?query=up" | jq -r '.data.result[] | "\(.metric.job): \(.value[1])"' 2>/dev/null)
if [ ! -z "$TARGETS" ]; then
    echo "$TARGETS" | while read line; do
        JOB=$(echo $line | cut -d: -f1)
        STATUS=$(echo $line | cut -d: -f2 | tr -d ' ')
        if [ "$STATUS" = "1" ]; then
            echo -e "  $JOB: ${GREEN}Up${NC}"
        else
            echo -e "  $JOB: ${RED}Down${NC}"
        fi
    done
else
    echo -e "  ${RED}Não foi possível obter status dos targets${NC}"
fi
echo

# 4. Informações de rede
echo -e "${YELLOW}Informações de Rede:${NC}"
echo -e "${BLUE}Portas dos serviços:${NC}"
echo "  Geth RPC: 8545"
echo "  Geth Engine: 8551" 
echo "  Geth Metrics: 6060"
echo "  Lighthouse HTTP: 5052"
echo "  Lighthouse Metrics: 5054"
echo "  Prometheus: 9090"
echo "  Grafana: 3000"
echo "  Node Exporter: 9100"
echo "  Rocket Pool: 8000"
echo

# 5. Uso de espaço
echo -e "${YELLOW}Uso de Espaço:${NC}"
echo -e "${BLUE}Volumes Docker:${NC}"
df -h | grep -E "(holesky|execution-data|consensus-data)" || echo "  Volumes não encontrados no df"

echo -e "${BLUE}Tamanho dos diretórios:${NC}"
if [ -d "./execution-data-holesky" ]; then
    EXEC_SIZE=$(du -sh ./execution-data-holesky 2>/dev/null | cut -f1)
    echo "  Execution data: $EXEC_SIZE"
fi
if [ -d "./consensus-data-holesky" ]; then
    CONS_SIZE=$(du -sh ./consensus-data-holesky 2>/dev/null | cut -f1)
    echo "  Consensus data: $CONS_SIZE"
fi
echo

echo -e "${GREEN}Para monitoramento contínuo, use: ./monitor-holesky.sh watch${NC}"
echo -e "${GREEN}Dashboards: http://localhost:3000 (admin/admin)${NC}"
echo -e "${GREEN}Prometheus: http://localhost:9090${NC}"

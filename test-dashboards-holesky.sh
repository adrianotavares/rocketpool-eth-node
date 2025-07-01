#!/bin/bash

# Script para testar dashboards e métricas Holesky
# Verifica se todas as métricas dos dashboards estão disponíveis

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Teste de Métricas dos Dashboards Holesky${NC}"
echo "=============================================="
echo

# Função para testar uma métrica
test_metric() {
    local metric="$1"
    local description="$2"
    
    response=$(curl -s "http://localhost:9090/api/v1/query?query=${metric}" 2>/dev/null)
    result=$(echo "$response" | jq -r '.data.result | length' 2>/dev/null)
    
    if [ "$result" = "0" ] || [ "$result" = "null" ] || [ -z "$result" ]; then
        echo -e "  ${RED}❌ ${description}: Sem dados${NC}"
        return 1
    else
        value=$(echo "$response" | jq -r '.data.result[0].value[1]' 2>/dev/null)
        if [ "$value" = "null" ] || [ -z "$value" ]; then
            echo -e "  ${YELLOW}⚠️  ${description}: Disponível mas sem valor${NC}"
        else
            echo -e "  ${GREEN}✅ ${description}: ${value}${NC}"
        fi
        return 0
    fi
}

# Teste métricas do Geth Holesky
echo -e "${YELLOW}📊 Métricas do Geth (Execution Client):${NC}"
test_metric 'up{job="geth-holesky"}' "Service Status"
test_metric 'chain_head_header{job="geth-holesky"}' "Current Block Header"
test_metric 'chain_head_finalized{job="geth-holesky"}' "Finalized Block" 
test_metric 'chain_head_block{job="geth-holesky"}' "Chain Head Block"
test_metric 'p2p_peers{job="geth-holesky"}' "Connected Peers"
test_metric 'chain_head_gas_used{job="geth-holesky"}' "Gas Used"
test_metric 'chain_head_gas_limit{job="geth-holesky"}' "Gas Limit"
test_metric 'txpool_pending{job="geth-holesky"}' "Pending Transactions"
test_metric 'txpool_queued{job="geth-holesky"}' "Queued Transactions"
test_metric 'eth_syncing{job="geth-holesky"}' "Sync Status"
echo

# Teste métricas do Lighthouse Holesky  
echo -e "${YELLOW}📊 Métricas do Lighthouse (Consensus Client):${NC}"
test_metric 'up{job="lighthouse-holesky"}' "Service Status"
test_metric 'beacon_slot{job="lighthouse-holesky"}' "Current Slot"
test_metric 'beacon_finalized_slot{job="lighthouse-holesky"}' "Finalized Slot"
test_metric 'beacon_justified_slot{job="lighthouse-holesky"}' "Justified Slot"
test_metric 'beacon_current_epoch{job="lighthouse-holesky"}' "Current Epoch"
test_metric 'beacon_finalized_epoch{job="lighthouse-holesky"}' "Finalized Epoch"
test_metric 'beacon_justified_epoch{job="lighthouse-holesky"}' "Justified Epoch"
test_metric 'libp2p_peers{job="lighthouse-holesky"}' "Connected Peers"
test_metric 'beacon_sync_status{job="lighthouse-holesky"}' "Sync Status"
test_metric 'beacon_attestation_processing_successes{job="lighthouse-holesky"}' "Successful Attestations"
test_metric 'beacon_attestation_processing_failures{job="lighthouse-holesky"}' "Failed Attestations"
echo

# Teste conectividade com Prometheus
echo -e "${YELLOW}🔗 Conectividade:${NC}"
if curl -s http://localhost:9090/-/healthy >/dev/null 2>&1; then
    echo -e "  ${GREEN}✅ Prometheus: Online${NC}"
else
    echo -e "  ${RED}❌ Prometheus: Offline${NC}"
fi

if curl -s http://localhost:3000/api/health >/dev/null 2>&1; then
    echo -e "  ${GREEN}✅ Grafana: Online${NC}"
else
    echo -e "  ${RED}❌ Grafana: Offline${NC}"
fi

# Teste targets no Prometheus
echo -e "${YELLOW}🎯 Status dos Targets:${NC}"
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | select(.labels.job | contains("holesky")) | "\(.labels.job): \(.health)"' 2>/dev/null | while read line; do
    job=$(echo $line | cut -d: -f1)
    health=$(echo $line | cut -d: -f2 | xargs)
    if [ "$health" = "up" ]; then
        echo -e "  ${GREEN}✅ $job: UP${NC}"
    else
        echo -e "  ${RED}❌ $job: DOWN${NC}"
    fi
done

echo
echo -e "${BLUE}📊 Dashboards disponíveis em:${NC}"
echo -e "  ${GREEN}Grafana: http://localhost:3000${NC}"
echo -e "  ${GREEN}Login: admin/admin${NC}"
echo -e "  ${GREEN}Pasta: Ethereum${NC}"
echo
echo -e "${BLUE}📈 Dashboards Holesky:${NC}"
echo -e "  ${GREEN}• Geth Holesky Testnet Monitoring${NC}"
echo -e "  ${GREEN}• Lighthouse Holesky Testnet Monitoring${NC}"

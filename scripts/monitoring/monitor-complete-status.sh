#!/bin/bash

# Script para monitorar o status completo do ambiente Rocket Pool Holesky
# Incluindo sincronização, dashboards e métricas

set -e

# Mudar para o diretório raiz do projeto
cd "$(dirname "$0")/../.."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para imprimir headers
print_header() {
    echo -e "\n${CYAN}================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}================================================${NC}"
}

# Função para imprimir status
print_status() {
    local service=$1
    local status=$2
    local extra_info=$3
    
    if [ "$status" = "UP" ]; then
        echo -e "${GREEN}✅ $service: $status${NC} $extra_info"
    elif [ "$status" = "DOWN" ]; then
        echo -e "${RED}❌ $service: $status${NC} $extra_info"
    else
        echo -e "${YELLOW}⚠️  $service: $status${NC} $extra_info"
    fi
}

# Função para obter sync status do Geth
get_geth_sync_status() {
    docker logs geth --tail 3 2>&1 | grep "Syncing:" | tail -1 | grep -o 'synced=[0-9]*\.[0-9]*%' | sed 's/synced=//' || echo "N/A"
}

# Função para obter ETA do Geth
get_geth_eta() {
    docker logs geth --tail 3 2>&1 | grep "Syncing:" | tail -1 | grep -o 'eta=[0-9a-z.]*' | sed 's/eta=//' || echo "N/A"
}

# Função para verificar se o Lighthouse está pronto
check_lighthouse_ready() {
    if docker logs lighthouse --tail 20 2>&1 | grep -q "Block production enabled"; then
        echo "READY"
    else
        echo "WAITING"
    fi
}

# Função para verificar targets do Prometheus
check_prometheus_targets() {
    curl -s http://localhost:9090/api/v1/targets 2>/dev/null | jq -r '.data.activeTargets[] | "\(.labels.job):\(.health)"' 2>/dev/null || echo "ERROR: Could not connect to Prometheus"
}

# Função para contar dashboards disponíveis
count_dashboards() {
    local dir=$1
    if [ -d "$dir" ]; then
        find "$dir" -name "*.json" | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

print_header "ROCKET POOL HOLESKY - STATUS MONITOR"

# Data e hora atual
echo -e "${BLUE}🕐 Data/Hora:${NC} $(date)"
echo -e "${BLUE}💻 Sistema:${NC} $(uname -s) $(uname -m)"

print_header "CONTAINERS DOCKER"

# Verificar status dos containers
docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -E "(geth|lighthouse|rocketpool-node-holesky|prometheus-holesky|grafana-holesky|node-exporter-holesky)" | while read -r line; do
    if [ "$line" != "NAMES	STATUS" ] && [ -n "$line" ]; then
        container_name=$(echo "$line" | awk '{print $1}')
        container_status=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
        
        if [[ "$container_status" == "Up"* ]]; then
            print_status "$container_name" "UP" "($container_status)"
        else
            print_status "$container_name" "DOWN" "($container_status)"
        fi
    fi
done

print_header "SINCRONIZAÇÃO"

# Status do Geth
geth_sync=$(get_geth_sync_status)
geth_eta=$(get_geth_eta)
if [ "$geth_sync" != "N/A" ]; then
    sync_percent=$(echo "$geth_sync" | sed 's/%//' | cut -d. -f1)
    if [ "$sync_percent" -ge 99 ] 2>/dev/null; then
        print_status "Geth Sync" "$geth_sync" "(ETA: $geth_eta) - 🎉 Quase pronto!"
    elif [ "$sync_percent" -gt 95 ] 2>/dev/null; then
        print_status "Geth Sync" "$geth_sync" "(ETA: $geth_eta) - 🚀 Quase lá!"
    else
        print_status "Geth Sync" "$geth_sync" "(ETA: $geth_eta)"
    fi
else
    print_status "Geth Sync" "UNKNOWN" "(Verificar logs)"
fi

# Status do Lighthouse
lighthouse_status=$(check_lighthouse_ready)
if [ "$lighthouse_status" = "READY" ]; then
    print_status "Lighthouse" "READY" "✅ Conectado ao Geth"
else
    print_status "Lighthouse" "WAITING" "⏳ Aguardando Geth sincronizar"
fi

print_header "MÉTRICAS E MONITORAMENTO"

# Verificar Prometheus targets
echo -e "${BLUE}📊 Prometheus Targets:${NC}"
check_prometheus_targets | while IFS= read -r target; do
    if [ -n "$target" ]; then
        job=$(echo "$target" | cut -d':' -f1)
        health=$(echo "$target" | cut -d':' -f2)
        
        if [ "$health" = "up" ]; then
            print_status "$job" "UP" ""
        else
            print_status "$job" "DOWN" ""
        fi
    fi
done

print_header "DASHBOARDS GRAFANA"

# Contar dashboards
original_count=$(count_dashboards "grafana/provisioning/dashboards/Holesky")
ethereum_count=$(count_dashboards "grafana/provisioning/dashboards/Ethereum")
recommended_count=$(count_dashboards "grafana/provisioning/dashboards/Recommended")

echo -e "${BLUE}📈 Dashboards Disponíveis:${NC}"
echo -e "   ${GREEN}✅ Originais (Holesky):${NC} $original_count dashboards"
echo -e "   ${GREEN}✅ Ethereum:${NC} $ethereum_count dashboards"
echo -e "   ${GREEN}✅ Recomendados:${NC} $recommended_count dashboards"
echo -e "   ${PURPLE}📊 Total:${NC} $((original_count + ethereum_count + recommended_count)) dashboards"

print_header "RECURSOS DO SISTEMA"

# CPU Load Average
if command -v uptime >/dev/null 2>&1; then
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')
    echo -e "${BLUE}💻 CPU Load Average:${NC} $load_avg"
fi

# Memória disponível
if command -v free >/dev/null 2>&1; then
    memory_info=$(free -h | awk 'NR==2{printf "Used: %s, Available: %s, Usage: %.2f%%", $3, $7, ($3/$2)*100}')
    echo -e "${BLUE}🧠 Memória:${NC} $memory_info"
elif command -v vm_stat >/dev/null 2>&1; then
    # macOS
    memory_info=$(vm_stat | awk '
        /Pages free/ { free = $3 }
        /Pages active/ { active = $3 }
        /Pages inactive/ { inactive = $3 }
        /Pages wired/ { wired = $3 }
        END {
            total = (free + active + inactive + wired) * 4096 / 1024 / 1024 / 1024
            used = (active + inactive + wired) * 4096 / 1024 / 1024 / 1024
            printf "Used: %.1fGB, Total: %.1fGB, Usage: %.1f%%", used, total, (used/total)*100
        }
    ')
    echo -e "${BLUE}🧠 Memória:${NC} $memory_info"
fi

# Espaço em disco
disk_info=$(df -h . | awk 'NR==2{printf "Used: %s, Available: %s, Usage: %s", $3, $4, $5}')
echo -e "${BLUE}💾 Disco:${NC} $disk_info"

print_header "ACESSO AOS SERVIÇOS"

echo -e "${BLUE}🌐 URLs dos Serviços:${NC}"
echo -e "   ${GREEN}Grafana:${NC} http://localhost:3000"
echo -e "   ${GREEN}Prometheus:${NC} http://localhost:9090"
echo -e "   ${GREEN}Rocket Pool Node:${NC} http://localhost:8000"

print_header "PRÓXIMOS PASSOS"

# Verificar se Geth está próximo de 100%
if [ "$geth_sync" != "N/A" ]; then
    sync_percent=$(echo "$geth_sync" | sed 's/%//' | sed 's/\..*//')
    if [ "$sync_percent" -ge 100 ] 2>/dev/null; then
        echo -e "${GREEN}🎉 Geth está sincronizado! Lighthouse deve estar expondo métricas agora.${NC}"
        echo -e "${YELLOW}📊 Verifique os dashboards do Grafana para métricas do Lighthouse.${NC}"
    elif [ "$sync_percent" -gt 95 ] 2>/dev/null; then
        echo -e "${YELLOW}⏳ Geth quase sincronizado ($geth_sync). ETA: $geth_eta${NC}"
        echo -e "${YELLOW}📊 Lighthouse começará a expor métricas em breve.${NC}"
    else
        echo -e "${YELLOW}⏳ Aguardando Geth sincronizar ($geth_sync). ETA: $geth_eta${NC}"
        echo -e "${YELLOW}📊 Dashboards do Lighthouse ficarão disponíveis após sincronização.${NC}"
    fi
else
    echo -e "${RED}❌ Não foi possível determinar o status de sincronização do Geth.${NC}"
fi

echo -e "\n${CYAN}💡 Dica: Execute este script novamente para acompanhar o progresso!${NC}"
echo -e "${CYAN}📋 Comando: ./monitor-complete-status.sh${NC}"

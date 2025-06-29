#!/bin/bash

# =============================================================================
# Monitor SSD - Rocket Pool Node
# =============================================================================
# Script para monitorar o SSD externo e o status do Rocket Pool Node
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Arquivo de configuração
ENV_FILE=".env.ssd"

# Carregar configurações se o arquivo existir
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo -e "${RED}[ERROR]${NC} Arquivo $ENV_FILE não encontrado. Execute setup-ssd.sh primeiro."
    exit 1
fi

# Funções auxiliares
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${CYAN}   Rocket Pool SSD Monitor - $(date)${NC}"
    echo -e "${CYAN}============================================================${NC}"
    echo
}

check_ssd_mounted() {
    if [ ! -d "$SSD_BASE_PATH" ]; then
        log_error "SSD não encontrado em $SSD_BASE_PATH"
        echo "Verifique se o SSD está conectado e montado corretamente."
        return 1
    fi
    
    log_success "SSD montado em: $SSD_BASE_PATH"
    return 0
}

check_disk_space() {
    echo -e "${CYAN}ESPAÇO EM DISCO${NC}"
    echo "===================="
    
    if command -v df &> /dev/null; then
        # Informações gerais do SSD
        df -h "$SSD_BASE_PATH" | head -1
        DISK_INFO=$(df -h "$SSD_BASE_PATH" | tail -1)
        echo "$DISK_INFO"
        
        # Extrair dados para análise
        TOTAL=$(echo "$DISK_INFO" | awk '{print $2}')
        USED=$(echo "$DISK_INFO" | awk '{print $3}')
        AVAILABLE=$(echo "$DISK_INFO" | awk '{print $4}')
        PERCENT_USED=$(echo "$DISK_INFO" | awk '{print $5}' | tr -d '%')
        
        echo
        echo "Total: $TOTAL | Usado: $USED | Disponível: $AVAILABLE | Uso: $PERCENT_USED%"
        
        # Alertas baseados no uso
        if [ "$PERCENT_USED" -ge 90 ]; then
            log_error "Espaço crítico! Uso: $PERCENT_USED%"
        elif [ "$PERCENT_USED" -ge 80 ]; then
            log_warning "Espaço baixo. Uso: $PERCENT_USED%"
        else
            log_success "Espaço suficiente. Uso: $PERCENT_USED%"
        fi
    else
        log_warning "Comando 'df' não disponível para verificar espaço"
    fi
    
    echo
}

check_data_directories() {
    echo -e "${CYAN}DIRETÓRIOS DE DADOS${NC}"
    echo "========================="
    
    DIRS=(
        "$EXECUTION_DATA_PATH:Execution (Geth)"
        "$CONSENSUS_DATA_PATH:Consensus (Lighthouse)"
        "$ROCKETPOOL_DATA_PATH:Rocket Pool"
        "$PROMETHEUS_DATA_PATH:Prometheus"
        "$GRAFANA_DATA_PATH:Grafana"
    )
    
    for dir_info in "${DIRS[@]}"; do
        IFS=':' read -r dir_path dir_name <<< "$dir_info"
        
        if [ -d "$dir_path" ]; then
            SIZE=$(du -sh "$dir_path" 2>/dev/null | awk '{print $1}' || echo "Unknown")
            log_success "$dir_name: $SIZE"
        else
            log_warning "$dir_name: Diretório não encontrado"
        fi
    done
    echo
}

check_docker_containers() {
    echo -e "${CYAN}STATUS DOS CONTAINERS${NC}"
    echo "==========================="
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker não encontrado"
        return 1
    fi
    
    CONTAINERS=("execution-client" "consensus-client" "rocketpool-node" "prometheus" "grafana")
    
    for container in "${CONTAINERS[@]}"; do
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container"; then
            STATUS=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$container" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}')
            log_success "$container: $STATUS"
        else
            log_error "$container: Não está executando"
        fi
    done
    echo
}

check_sync_status() {
    echo -e "${CYAN}STATUS DE SINCRONIZAÇÃO${NC}"
    echo "============================="
    
    # Verificar Geth
    if curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        http://localhost:8545 > /tmp/geth_sync 2>/dev/null; then
        
        SYNC_RESULT=$(cat /tmp/geth_sync | jq -r '.result' 2>/dev/null || echo "error")
        
        if [ "$SYNC_RESULT" = "false" ]; then
            log_success "Geth: Totalmente sincronizado"
        elif [ "$SYNC_RESULT" = "error" ] || [ "$SYNC_RESULT" = "null" ]; then
            log_warning "Geth: Não foi possível verificar status"
        else
            CURRENT=$(echo "$SYNC_RESULT" | jq -r '.currentBlock' 2>/dev/null || echo "unknown")
            HIGHEST=$(echo "$SYNC_RESULT" | jq -r '.highestBlock' 2>/dev/null || echo "unknown")
            log_warning "Geth: Sincronizando... Bloco $CURRENT de $HIGHEST"
        fi
        
        rm -f /tmp/geth_sync
    else
        log_error "Geth: Não está respondendo na porta 8545"
    fi
    
    # Verificar número de peers
    if curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        http://localhost:8545 > /tmp/geth_peers 2>/dev/null; then
        
        PEER_COUNT=$(cat /tmp/geth_peers | jq -r '.result' 2>/dev/null | xargs printf "%d" 2>/dev/null || echo "0")
        
        if [ "$PEER_COUNT" -gt 0 ]; then
            log_success "Geth Peers: $PEER_COUNT conectados"
        else
            log_warning "Geth Peers: Nenhum peer conectado"
        fi
        
        rm -f /tmp/geth_peers
    fi
    
    echo
}

check_system_resources() {
    echo -e "${CYAN}RECURSOS DO SISTEMA${NC}"
    echo "========================"
    
    # CPU Load Average
    if command -v uptime &> /dev/null; then
        LOAD=$(uptime | awk -F'load average:' '{print $2}' | xargs)
        echo "CPU Load Average: $LOAD"
    fi
    
    # Memória
    if command -v free &> /dev/null; then
        free -h | head -2
    elif command -v vm_stat &> /dev/null; then
        # macOS
        VM_STAT=$(vm_stat)
        PAGES_FREE=$(echo "$VM_STAT" | grep "Pages free" | awk '{print $3}' | tr -d '.')
        PAGES_ACTIVE=$(echo "$VM_STAT" | grep "Pages active" | awk '{print $3}' | tr -d '.')
        PAGES_INACTIVE=$(echo "$VM_STAT" | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
        
        # Cada página = 4KB no macOS
        FREE_MB=$((PAGES_FREE * 4 / 1024))
        ACTIVE_MB=$((PAGES_ACTIVE * 4 / 1024))
        INACTIVE_MB=$((PAGES_INACTIVE * 4 / 1024))
        
        echo "Memória Livre: ${FREE_MB}MB | Ativa: ${ACTIVE_MB}MB | Inativa: ${INACTIVE_MB}MB"
    fi
    
    echo
}

check_network_connectivity() {
    echo -e "${CYAN}CONECTIVIDADE DE REDE${NC}"
    echo "=========================="
    
    # Testar conectividade básica
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        log_success "Conectividade de internet: OK"
    else
        log_error "Conectividade de internet: FALHOU"
    fi
    
    # Testar portas dos serviços
    PORTS=(
        "3000:Grafana"
        "9090:Prometheus"
        "8545:Geth RPC"
    )
    
    for port_info in "${PORTS[@]}"; do
        IFS=':' read -r port service <<< "$port_info"
        
        if curl -s --connect-timeout 3 "http://localhost:$port" > /dev/null 2>&1; then
            log_success "$service (porta $port): Acessível"
        else
            log_warning "$service (porta $port): Não acessível"
        fi
    done
    
    echo
}

show_useful_commands() {
    echo -e "${CYAN}COMANDOS ÚTEIS${NC}"
    echo "==================="
    echo
    echo "# Ver logs em tempo real:"
    echo "docker-compose -f docker-compose.ssd.yml logs -f"
    echo
    echo "# Ver logs específicos:"
    echo "docker logs execution-client"
    echo "docker logs consensus-client"
    echo
    echo "# Reiniciar um serviço:"
    echo "docker-compose -f docker-compose.ssd.yml restart execution-client"
    echo
    echo "# Verificar sincronização detalhada:"
    echo "curl -X POST -H \"Content-Type: application/json\" \\"
    echo "  --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_syncing\",\"params\":[],\"id\":1}' \\"
    echo "  http://localhost:8545"
    echo
    echo "# Backup rápido:"
    echo "tar -czf \"\$SSD_BASE_PATH/backups/backup-\$(date +%Y%m%d-%H%M%S).tar.gz\" \\"
    echo "  -C \"\$SSD_BASE_PATH/ethereum-data\" \\"
    echo "  execution-data/geth/keystore rocketpool-data/.rocketpool"
    echo
}

watch_mode() {
    while true; do
        clear
        print_header
        check_ssd_mounted && {
            check_disk_space
            check_docker_containers
            check_sync_status
            check_system_resources
        }
        
        echo -e "${BLUE}Próxima atualização em 30 segundos... (Ctrl+C para sair)${NC}"
        sleep 30
    done
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    case "${1:-}" in
        "watch")
            watch_mode
            ;;
        "space")
            print_header
            check_ssd_mounted && check_disk_space
            ;;
        "containers")
            print_header
            check_docker_containers
            ;;
        "sync")
            print_header
            check_sync_status
            ;;
        "help"|"-h"|"--help")
            echo "Uso: $0 [opção]"
            echo
            echo "Opções:"
            echo "  (nenhuma)  Executar verificação completa uma vez"
            echo "  watch      Monitoramento contínuo (atualiza a cada 30s)"
            echo "  space      Verificar apenas espaço em disco"
            echo "  containers Verificar apenas status dos containers"
            echo "  sync       Verificar apenas status de sincronização"
            echo "  help       Mostrar esta ajuda"
            ;;
        *)
            print_header
            check_ssd_mounted && {
                check_disk_space
                check_data_directories
                check_docker_containers
                check_sync_status
                check_system_resources
                check_network_connectivity
                show_useful_commands
            }
            ;;
    esac
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

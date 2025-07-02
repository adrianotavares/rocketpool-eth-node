#!/bin/bash

# =============================================================================
# Monitor Holesky - Rocket Pool Node (Testnet)
# =============================================================================
# Script para monitorar o status dos containers e serviços da testnet Holesky
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
ENV_FILE=".env.holesky"

# Carregar configurações se o arquivo existir
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo -e "${RED}[ERROR]${NC} Arquivo $ENV_FILE não encontrado. Execute setup-holesky.sh primeiro."
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
    echo -e "${CYAN}   Rocket Pool Holesky Testnet Monitor - $(date)${NC}"
    echo -e "${CYAN}============================================================${NC}"
    echo
}

# Verificar se docker-compose está disponível
if ! command -v docker-compose &> /dev/null; then
    log_error "docker-compose não está instalado."
    exit 1
fi

# Verificar se os arquivos de configuração existem
if [[ ! -f "docker-compose-holesky.yml" ]]; then
    log_error "Arquivo docker-compose-holesky.yml não encontrado!"
    exit 1
fi

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
    
    CONTAINERS=("eth1-holesky" "eth2-holesky" "rocketpool-node-holesky" "prometheus-holesky" "grafana-holesky" "node-exporter-holesky")
    
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
        http://localhost:8545 > /tmp/geth_sync_holesky 2>/dev/null; then
        
        SYNC_RESULT=$(cat /tmp/geth_sync_holesky | jq -r '.result' 2>/dev/null || echo "error")
        
        if [ "$SYNC_RESULT" = "false" ]; then
            log_success "Geth: Totalmente sincronizado"
        elif [ "$SYNC_RESULT" = "error" ] || [ "$SYNC_RESULT" = "null" ]; then
            log_warning "Geth: Não foi possível verificar status"
        else
            CURRENT=$(echo "$SYNC_RESULT" | jq -r '.currentBlock' 2>/dev/null || echo "unknown")
            HIGHEST=$(echo "$SYNC_RESULT" | jq -r '.highestBlock' 2>/dev/null || echo "unknown")
            log_warning "Geth: Sincronizando... Bloco $CURRENT de $HIGHEST"
        fi
        
        rm -f /tmp/geth_sync_holesky
    else
        log_error "Geth: Não está respondendo na porta 8545"
    fi
    
    # Verificar Chain ID (Holesky = 17000 = 0x4268)
    if curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
        http://localhost:8545 > /tmp/geth_chain_holesky 2>/dev/null; then
        
        CHAIN_ID=$(cat /tmp/geth_chain_holesky | jq -r '.result' 2>/dev/null || echo "error")
        
        if [ "$CHAIN_ID" = "0x4268" ]; then
            log_success "Geth: Conectado à Holesky (Chain ID: 17000)"
        elif [ "$CHAIN_ID" != "error" ] && [ "$CHAIN_ID" != "null" ]; then
            log_warning "Geth: Chain ID incorreto: $CHAIN_ID (esperado: 0x4268)"
        fi
        
        rm -f /tmp/geth_chain_holesky
    fi
    
    # Verificar número de peers
    if curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        http://localhost:8545 > /tmp/geth_peers_holesky 2>/dev/null; then
        
        PEER_COUNT=$(cat /tmp/geth_peers_holesky | jq -r '.result' 2>/dev/null | xargs printf "%d" 2>/dev/null || echo "0")
        
        if [ "$PEER_COUNT" -gt 0 ]; then
            log_success "Geth Peers: $PEER_COUNT conectados"
        else
            log_warning "Geth Peers: Nenhum peer conectado"
        fi
        
        rm -f /tmp/geth_peers_holesky
    fi
    
    # Verificar Lighthouse
    if curl -s "http://localhost:5052/eth/v1/node/syncing" > /tmp/lighthouse_sync_holesky 2>/dev/null; then
        IS_SYNCING=$(cat /tmp/lighthouse_sync_holesky | jq -r '.data.is_syncing' 2>/dev/null || echo "error")
        
        if [ "$IS_SYNCING" = "false" ]; then
            log_success "Lighthouse: Totalmente sincronizado"
        elif [ "$IS_SYNCING" = "true" ]; then
            log_warning "Lighthouse: Sincronizando..."
        else
            log_warning "Lighthouse: Status de sincronização desconhecido"
        fi
        
        rm -f /tmp/lighthouse_sync_holesky
    else
        log_error "Lighthouse: Não está respondendo na porta 5052"
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
    
    # Uso de memória Docker específico para containers Holesky
    echo
    echo "Uso de Memória dos Containers Holesky:"
    if docker ps --filter name=holesky --format "{{.Names}}" | grep -q .; then
        docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}" \
            $(docker ps --filter name=holesky --format "{{.Names}}" 2>/dev/null) 2>/dev/null || \
            echo "Erro ao obter estatísticas dos containers"
    else
        echo "Nenhum container Holesky em execução"
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
    
    # Testar portas dos serviços da testnet
    PORTS=(
        "3000:Grafana"
        "9090:Prometheus"
        "8545:Geth RPC"
        "5052:Lighthouse API"
        "5054:Lighthouse Metrics"
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

check_rocketpool_status() {
    echo -e "${CYAN}STATUS DO ROCKET POOL${NC}"
    echo "========================"
    
    # Verificar se o container está rodando
    if docker ps --format "{{.Names}}" | grep -q "rocketpool-node-holesky"; then
        log_success "Container Rocket Pool: Executando"
        
        # Verificar se o comando rocketpool funciona
        if docker exec rocketpool-node-holesky rocketpool --version > /dev/null 2>&1; then
            VERSION=$(docker exec rocketpool-node-holesky rocketpool --version 2>/dev/null | head -1)
            log_success "Rocket Pool CLI: Funcionando ($VERSION)"
        else
            log_warning "Rocket Pool CLI: Não está respondendo"
        fi
        
        # Verificar status do node (com timeout manual)

        docker exec rocketpool-node-holesky rocketpool api node status > /tmp/rp_status_holesky 2> /dev/null &
        EXEC_PID=$!
        sleep 10
        if kill -0 $EXEC_PID 2>/dev/null; then
            kill $EXEC_PID 2>/dev/null
            log_warning "Rocket Pool: Timeout ao verificar status do node"
        elif [ -f /tmp/rp_status_holesky ]; then
            # Verificar se a resposta é JSON válida e interpretar
            if jq -e . /tmp/rp_status_holesky > /dev/null 2>&1; then
                STATUS=$(jq -r '.status' /tmp/rp_status_holesky 2>/dev/null)
                if [ "$STATUS" = "success" ]; then
                    # Verificar wallet
                    WALLET_INIT=$(jq -r '.walletInitialized' /tmp/rp_status_holesky 2>/dev/null)
                    NODE_REGISTERED=$(jq -r '.registered' /tmp/rp_status_holesky 2>/dev/null)
                    
                    if [ "$WALLET_INIT" = "false" ]; then
                        log_warning "Rocket Pool: Wallet não inicializada"
                        echo "  Use: docker exec -it rocketpool-node-holesky rocketpool api wallet init"
                    elif [ "$NODE_REGISTERED" = "true" ]; then
                        log_success "Rocket Pool: Node registrado"
                    else
                        log_info "Rocket Pool: Node status obtido com sucesso"
                    fi
                else
                    ERROR_MSG=$(jq -r '.error' /tmp/rp_status_holesky 2>/dev/null)
                    log_warning "Rocket Pool: $ERROR_MSG"
                fi
            else
                # Fallback para respostas não-JSON (versões antigas)
                if grep -q "The node wallet has not been initialized" /tmp/rp_status_holesky; then
                    log_warning "Rocket Pool: Wallet não inicializada"
                    echo "  Use: docker exec -it rocketpool-node-holesky rocketpool api wallet init"
                elif grep -q "node is registered" /tmp/rp_status_holesky; then
                    log_success "Rocket Pool: Node registrado"
                else
                    log_info "Rocket Pool: Status do node disponível"
                fi
            fi
            rm -f /tmp/rp_status_holesky
        else
            log_warning "Rocket Pool: Não foi possível verificar status do node"
        fi
        
        # Verificar conectividade com execution client (simplificado)
        log_info "Rocket Pool: Para verificar sincronização use:"
        echo "  docker exec rocketpool-node-holesky rocketpool api node sync"
        
    else
        log_error "Container Rocket Pool: Não está executando"
        echo "  Use: docker-compose -f docker-compose-holesky.yml up -d rocketpool-node"
    fi
    
    echo
}

show_useful_commands() {
    echo -e "${CYAN}COMANDOS ÚTEIS - TESTNET HOLESKY${NC}"
    echo "===================================="
    echo
    echo "# Ver logs em tempo real:"
    echo "docker-compose -f docker-compose-holesky.yml --env-file .env.holesky logs -f"
    echo
    echo "# Ver logs específicos:"
    echo "docker logs eth1-holesky"
    echo "docker logs eth2-holesky"
    echo "docker logs rocketpool-node-holesky"
    echo
    echo "# Reiniciar um serviço:"
    echo "docker-compose -f docker-compose-holesky.yml --env-file .env.holesky restart eth1"
    echo "docker-compose -f docker-compose-holesky.yml --env-file .env.holesky restart eth2"
    echo "docker-compose -f docker-compose-holesky.yml --env-file .env.holesky restart rocketpool-node"
    echo
    echo "# Acessar Rocket Pool CLI:"
    echo "docker exec -it rocketpool-node-holesky /bin/bash"
    echo
    echo "# Verificar sincronização detalhada:"
    echo "curl -X POST -H \"Content-Type: application/json\" \\"
    echo "  --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_syncing\",\"params\":[],\"id\":1}' \\"
    echo "  http://localhost:8545"
    echo
    echo "# URLs úteis da testnet:"
    echo "# Faucet: https://holesky-faucet.pk910.de/"
    echo "# Explorer: https://holesky.etherscan.io/"
    echo "# Beaconcha.in: https://holesky.beaconcha.in/"
    echo
    echo "# Comandos Rocket Pool básicos (dentro do container):"
    echo "docker exec -it rocketpool-node-holesky rocketpool api wallet init"
    echo "docker exec -it rocketpool-node-holesky rocketpool api wallet status"
    echo "docker exec -it rocketpool-node-holesky rocketpool api node status"
    echo "docker exec -it rocketpool-node-holesky rocketpool api node register"
    echo "docker exec -it rocketpool-node-holesky rocketpool api node sync"
    echo "docker exec -it rocketpool-node-holesky rocketpool api minipool status"
    echo
}

watch_mode() {
    while true; do
        clear
        print_header
        check_data_directories
        check_docker_containers
        check_sync_status
        check_rocketpool_status
        check_system_resources
        check_network_connectivity
        
        echo -e "${BLUE}Próxima atualização em 30 segundos... (Ctrl+C para sair)${NC}"
        sleep 30
    done
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    case "${1:-}" in
        "watch"|"-w")
            watch_mode
            ;;
        "space"|"-sp")
            print_header
            check_data_directories
            ;;
        "containers"|"-c")
            print_header
            check_docker_containers
            ;;
        "sync"|"-s")
            print_header
            check_sync_status
            ;;
        "rocketpool"|"-rp")
            print_header
            check_rocketpool_status
            ;;
        "help"|"-h"|"--help")
            echo "Uso: $0 [opção]"
            echo
            echo "Opções:"
            echo "  (nenhuma)      Executar verificação completa uma vez"
            echo "  watch      -w  Monitoramento contínuo (atualiza a cada 30s)"
            echo "  space      -sp Verificar apenas diretórios de dados"
            echo "  containers -c  Verificar apenas status dos containers"
            echo "  sync       -s  Verificar apenas status de sincronização"
            echo "  rocketpool -rp Verificar apenas status do Rocket Pool"
            echo "  help       -h --help Mostrar esta ajuda"
            echo
            echo "Exemplos:"
            echo "  $0                 # Verificação completa"
            echo "  $0 watch           # Monitoramento contínuo"
            echo "  $0 sync            # Apenas sincronização"
            echo "  $0 rocketpool      # Apenas Rocket Pool"
            ;;
        *)
            print_header
            check_data_directories
            check_docker_containers
            check_sync_status
            check_rocketpool_status
            check_system_resources
            check_network_connectivity
            show_useful_commands
            ;;
    esac
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

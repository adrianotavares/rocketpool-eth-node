#!/bin/bash

# =============================================================================
# Monitor Holesky - Rocket Pool Node (Testnet)
# =============================================================================
# Script para monitorar o status dos containers e serviços da testnet Holesky
# =============================================================================

set -e

# Mudar para o diretório raiz do projeto
cd "$(dirname "$0")/../.."

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

check_lighthouse_sync() {
    echo -e "${CYAN}STATUS DA SINCRONIZAÇÃO DO LIGHTHOUSE (BEACON CHAIN)${NC}"
    echo "======================================================"

    # Verificar se o container do Lighthouse está executando
    if ! docker ps --format "{{.Names}}" | grep -q "lighthouse"; then
        log_warning "Container do Lighthouse não está em execução."
        echo
        return
    fi

    # Faz a chamada para a API de syncing do Lighthouse
    # Usamos -s para modo silencioso e -m 10 para um timeout de 10 segundos
    SYNC_DATA=$(curl -s -m 10 http://localhost:5052/eth/v1/node/syncing)

    # Verificar se obtivemos uma resposta válida
    if [ -z "$SYNC_DATA" ]; then
        log_warning "Não foi possível obter dados de sincronização do Lighthouse."
        # Verificar se o endpoint está acessível
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5052/eth/v1/node/syncing)
        if [ "$HTTP_STATUS" -eq 200 ]; then
            log_success "Lighthouse Beacon Chain está 100% sincronizado."
        else
            log_error "Falha ao contatar o endpoint de sincronização do Lighthouse (HTTP Status: $HTTP_STATUS)."
        fi
        echo
        return
    fi

    # Verificar se o Lighthouse está sincronizado
    IS_SYNCING=$(echo "$SYNC_DATA" | jq -r '.data.is_syncing // "unknown"')
    if [ "$IS_SYNCING" = "false" ]; then
        log_success "Lighthouse Beacon Chain está 100% sincronizado."
        echo
        return
    fi

    # Extrair dados usando jq
    HEAD_SLOT=$(echo "$SYNC_DATA" | jq -r '.data.head_slot // "0"')
    SYNC_DISTANCE=$(echo "$SYNC_DATA" | jq -r '.data.sync_distance // "0"')
    
    # Se sync_distance não estiver disponível, tentar o campo sync_distance_slots
    if [ "$SYNC_DISTANCE" = "0" ] || [ "$SYNC_DISTANCE" = "null" ]; then
        SYNC_DISTANCE=$(echo "$SYNC_DATA" | jq -r '.data.sync_distance_slots // "0"')
    fi

    # Debug - mostrar os valores extraídos
    log_info "Dados brutos: head_slot=$HEAD_SLOT, sync_distance=$SYNC_DISTANCE"

    # Verificar se os dados são válidos
    if ! [[ "$HEAD_SLOT" =~ ^[0-9]+$ ]] || ! [[ "$SYNC_DISTANCE" =~ ^[0-9]+$ ]]; then
        log_warning "Dados inválidos recebidos do Lighthouse. Formato da resposta:"
        echo "$SYNC_DATA" | jq '.'
        echo
        return
    fi

    # Se já estiver sincronizado
    if [ "$SYNC_DISTANCE" -eq 0 ]; then
        log_success "Lighthouse Beacon Chain está 100% sincronizado."
        echo
        return
    fi

    # O slot de destino é o slot atual mais a distância
    TARGET_SLOT=$((HEAD_SLOT + SYNC_DISTANCE))

    # Evitar divisão por zero se o target_slot for 0
    if [ "$TARGET_SLOT" -eq 0 ]; then
        log_warning "Slot de destino é 0, não é possível calcular o progresso."
        echo
        return
    fi

    # Salvar o timestamp e o head_slot atual para cálculo da velocidade
    TEMP_FILE="/tmp/lighthouse_sync_progress"
    CURRENT_TIME=$(date +%s)

    # Calcula o percentual
    # Usamos `bc` para cálculos com ponto flutuante
    if ! command -v bc &> /dev/null; then
        # Fallback para cálculo aproximado sem bc
        PERCENTAGE=$(awk "BEGIN {print ($HEAD_SLOT / $TARGET_SLOT) * 100}")
        PERCENTAGE_FORMATTED=$(printf "%.2f" $PERCENTAGE)
    else
        PERCENTAGE=$(echo "scale=4; ($HEAD_SLOT / $TARGET_SLOT) * 100" | bc)
        PERCENTAGE_FORMATTED=$(printf "%.2f" $PERCENTAGE)
    fi

    # Estimativa de tempo (ETA)
    ETA_STRING="Calculando..."
    SPEED_INFO=""
    
    # Calculamos o ETA baseado em uma estimativa padrão se não houver arquivo
    # ou baseado nos dados anteriores se o arquivo existir
    
    # Taxa média de slots por segundo na rede Ethereum (12 segundos por slot em média)
    DEFAULT_SLOTS_PER_SEC=0.083
    SLOTS_PER_SEC=$DEFAULT_SLOTS_PER_SEC
    
    if [ -f "$TEMP_FILE" ]; then
        # Ler dados anteriores
        if read -r PREV_TIME PREV_SLOT < "$TEMP_FILE"; then
            # Calcular a velocidade de sincronização (slots por segundo)
            TIME_DIFF=$((CURRENT_TIME - PREV_TIME))
            
            # Se passou tempo suficiente e os slots aumentaram, calcular a velocidade real
            if [ "$TIME_DIFF" -gt 30 ]; then  # Reduzido para 30 segundos para cálculo mais rápido
                SLOT_DIFF=$((HEAD_SLOT - PREV_SLOT))
                
                if [ "$SLOT_DIFF" -gt 0 ] && [ "$TIME_DIFF" -gt 0 ]; then
                    # Slots por segundo
                    if command -v bc &> /dev/null; then
                        SLOTS_PER_SEC=$(echo "scale=6; $SLOT_DIFF / $TIME_DIFF" | bc)
                    else
                        SLOTS_PER_SEC=$(awk "BEGIN {print $SLOT_DIFF / $TIME_DIFF}")
                    fi
                    
                    # Verificar se a taxa está dentro de limites razoáveis (0.01 a 100 slots/segundo)
                    # Se for muito baixa ou alta, usar o valor padrão
                    if (( $(echo "$SLOTS_PER_SEC < 0.01" | bc -l) )) || (( $(echo "$SLOTS_PER_SEC > 100" | bc -l) )); then
                        log_warning "Taxa de sincronização fora do intervalo normal: $SLOTS_PER_SEC slots/segundo, usando estimativa padrão"
                        SLOTS_PER_SEC=$DEFAULT_SLOTS_PER_SEC
                    fi
                fi
            fi
        fi
    fi
    
    # Calcular ETA com base na taxa de slots por segundo
    if command -v bc &> /dev/null; then
        ETA_SECONDS=$(echo "scale=0; $SYNC_DISTANCE / $SLOTS_PER_SEC" | bc)
    else
        ETA_SECONDS=$(awk "BEGIN {print int($SYNC_DISTANCE / $SLOTS_PER_SEC)}")
    fi
    
    # Converter para formato legível
    ETA_DAYS=$((ETA_SECONDS / 86400))
    ETA_HOURS=$(( (ETA_SECONDS % 86400) / 3600 ))
    ETA_MINUTES=$(( (ETA_SECONDS % 3600) / 60 ))
    
    # Construir string de ETA
    ETA_STRING=""
    if [ "$ETA_DAYS" -gt 0 ]; then
        ETA_STRING="${ETA_DAYS}d "
    fi
    if [ "$ETA_HOURS" -gt 0 ] || [ "$ETA_DAYS" -gt 0 ]; then
        ETA_STRING="${ETA_STRING}${ETA_HOURS}h "
    fi
    ETA_STRING="${ETA_STRING}${ETA_MINUTES}m"
    
    SPEED_INFO="Velocidade: $(printf "%.2f" $SLOTS_PER_SEC) slots/segundo"
    
    # Salvar dados atuais para próxima execução
    echo "$CURRENT_TIME $HEAD_SLOT" > "$TEMP_FILE"
    
    # Exibir as informações
    log_info "Progresso da sincronização: ${PERCENTAGE_FORMATTED}%"
    log_info "Slot Atual: $HEAD_SLOT / $TARGET_SLOT"
    log_info "Distância: $SYNC_DISTANCE slots restantes"
    [ -n "$SPEED_INFO" ] && log_info "$SPEED_INFO"
    log_info "ETA: $ETA_STRING"
    echo
}

check_docker_containers() {
    echo -e "${CYAN}STATUS DOS CONTAINERS${NC}"
    echo "==========================="
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker não encontrado"
        return 1
    fi
    
    CONTAINERS=("geth" "lighthouse" "rocketpool-node-holesky" "prometheus-holesky" "grafana-holesky" "node-exporter-holesky")
    
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

# Função para obter informações de sincronização via logs
get_geth_sync_info() {
    local geth_log=$(docker logs geth --tail 5 2>&1 | grep "Syncing:" | tail -1 2>/dev/null)
    if [ -n "$geth_log" ]; then
        local sync_percent=$(echo "$geth_log" | grep -o 'synced=[0-9]*\.[0-9]*%' | sed 's/synced=//')
        local eta=$(echo "$geth_log" | grep -o 'eta=[0-9a-z.]*' | sed 's/eta=//')
        
        if [ -n "$sync_percent" ] && [ -n "$eta" ]; then
            echo "SYNCING:$sync_percent:$eta"
        else
            echo "UNAVAILABLE"
        fi
    else
        echo "UNAVAILABLE"
    fi
}

check_sync_status() {
    echo -e "${CYAN}STATUS DE SINCRONIZAÇÃO${NC}"
    echo "============================="
    
    # Verificar Geth
    if curl -s --max-time 10 -X POST -H "Content-Type: application/json" \
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
            
            # Converter hex para decimal se possível
            if [[ "$CURRENT" =~ ^0x[0-9a-fA-F]+$ ]]; then
                CURRENT_DEC=$(printf "%d" "$CURRENT" 2>/dev/null || echo "unknown")
                CURRENT="$CURRENT_DEC"
            fi
            if [[ "$HIGHEST" =~ ^0x[0-9a-fA-F]+$ ]]; then
                HIGHEST_DEC=$(printf "%d" "$HIGHEST" 2>/dev/null || echo "unknown")
                HIGHEST="$HIGHEST_DEC"
            fi
            
            log_warning "Geth: Sincronizando... Bloco $CURRENT de $HIGHEST"
        fi
        
        rm -f /tmp/geth_sync_holesky
    else
        # Verificar se o Geth está iniciando
        if docker ps --filter name=geth --format "{{.Status}}" | grep -q "Up"; then
            log_warning "Geth: Iniciando... (porta 8545 ainda não acessível)"
        else
            log_error "Geth: Container não está executando"
        fi
    fi
    
    # Verificar Chain ID (Holesky = 17000 = 0x4268)
    if curl -s --max-time 10 -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
        http://localhost:8545 > /tmp/geth_chain_holesky 2>/dev/null; then
        
        CHAIN_ID=$(cat /tmp/geth_chain_holesky | jq -r '.result' 2>/dev/null || echo "error")
        
        if [ "$CHAIN_ID" = "0x4268" ]; then
            log_success "Geth: Conectado à Holesky (Chain ID: 17000)"
        elif [ "$CHAIN_ID" != "error" ] && [ "$CHAIN_ID" != "null" ]; then
            CHAIN_ID_DEC=$(printf "%d" "$CHAIN_ID" 2>/dev/null || echo "unknown")
            log_warning "Geth: Chain ID incorreto: $CHAIN_ID ($CHAIN_ID_DEC) - esperado: 0x4268 (17000)"
        fi
        
        rm -f /tmp/geth_chain_holesky
    fi
    
    # Verificar número de peers
    if curl -s --max-time 10 -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        http://localhost:8545 > /tmp/geth_peers_holesky 2>/dev/null; then
        
        PEER_COUNT_HEX=$(cat /tmp/geth_peers_holesky | jq -r '.result' 2>/dev/null || echo "0x0")
        PEER_COUNT=$(printf "%d" "$PEER_COUNT_HEX" 2>/dev/null || echo "0")
        
        if [ "$PEER_COUNT" -gt 0 ]; then
            log_success "Geth Peers: $PEER_COUNT conectados"
        else
            log_warning "Geth Peers: Nenhum peer conectado"
        fi
        
        rm -f /tmp/geth_peers_holesky
    fi
    
    # Verificar Lighthouse
    if curl -s --max-time 10 "http://localhost:5052/eth/v1/node/syncing" > /tmp/lighthouse_sync_holesky 2>/dev/null; then
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
        # Verificar se o Lighthouse está iniciando
        if docker ps --filter name=lighthouse --format "{{.Status}}" | grep -q "Up"; then
            log_warning "Lighthouse: Iniciando... (porta 5052 ainda não acessível)"
        else
            log_error "Lighthouse: Container não está executando"
        fi
    fi
    
    # Obter informações de sincronização do Geth via logs
    SYNC_INFO=$(get_geth_sync_info)
    if [ "$SYNC_INFO" != "UNAVAILABLE" ]; then
        IFS=':' read -r sync_status sync_percent eta <<< "$SYNC_INFO"
        log_info "Geth Sync: $sync_status | Progresso: $sync_percent | ETA: $eta"
    else
        log_warning "Geth Sync: Informações de progresso não disponíveis"
    fi
    
    echo
}

check_system_resources() {
    echo -e "${CYAN}RECURSOS DO SISTEMA${NC}"
    echo "========================"
    
    # CPU Load Average - Versão corrigida e robusta
    if command -v uptime &> /dev/null; then
        UPTIME_OUTPUT=$(uptime)
        
        # Método 1: Regex para macOS (load averages: X.XX Y.YY Z.ZZ)
        if [[ "$UPTIME_OUTPUT" =~ load[[:space:]]+averages:[[:space:]]*([0-9.]+)[[:space:]]+([0-9.]+)[[:space:]]+([0-9.]+) ]]; then
            LOAD_1MIN="${BASH_REMATCH[1]}"
            LOAD_5MIN="${BASH_REMATCH[2]}"
            LOAD_15MIN="${BASH_REMATCH[3]}"
            echo "CPU Load Average: $LOAD_1MIN $LOAD_5MIN $LOAD_15MIN (1min 5min 15min)"
        
        # Método 2: Regex para Linux (load average: X.XX, Y.YY, Z.ZZ)
        elif [[ "$UPTIME_OUTPUT" =~ load[[:space:]]+average:[[:space:]]*([0-9.]+),[[:space:]]*([0-9.]+),[[:space:]]*([0-9.]+) ]]; then
            LOAD_1MIN="${BASH_REMATCH[1]}"
            LOAD_5MIN="${BASH_REMATCH[2]}"
            LOAD_15MIN="${BASH_REMATCH[3]}"
            echo "CPU Load Average: $LOAD_1MIN $LOAD_5MIN $LOAD_15MIN (1min 5min 15min)"
        
        # Método 3: Fallback usando awk - mais robusto
        else
            # Tentar extrair os números usando awk
            LOAD_VALUES=$(echo "$UPTIME_OUTPUT" | awk '{
                for(i=1; i<=NF; i++) {
                    if($i ~ /^[0-9]+\.[0-9]+$/) {
                        loads[++count] = $i
                    } else if($i ~ /^[0-9]+\.[0-9]+,$/) {
                        loads[++count] = substr($i, 1, length($i)-1)
                    }
                }
                if(count >= 3) {
                    print loads[count-2], loads[count-1], loads[count]
                }
            }')
            
            if [[ -n "$LOAD_VALUES" ]]; then
                echo "CPU Load Average: $LOAD_VALUES (1min 5min 15min)"
            else
                # Último fallback - pegar a parte após "load"
                LOAD_PART=$(echo "$UPTIME_OUTPUT" | sed -n 's/.*load[^:]*[:[:space:]]*\([0-9.,[:space:]]*\).*/\1/p' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                if [[ -n "$LOAD_PART" ]]; then
                    echo "CPU Load Average: $LOAD_PART"
                else
                    echo "CPU Load Average: N/A (formato não reconhecido)"
                    echo "  Debug: $UPTIME_OUTPUT"
                fi
            fi
        fi
    else
        echo "CPU Load Average: N/A (uptime não disponível)"
    fi
    
    # Memória - Informações detalhadas
    echo
    if command -v free &> /dev/null; then
        # Linux
        echo "Memória do Sistema:"
        free -h | head -2
    elif command -v vm_stat &> /dev/null; then
        # macOS
        echo "Memória do Sistema (macOS):"
        VM_STAT=$(vm_stat)
        PAGES_FREE=$(echo "$VM_STAT" | grep "Pages free" | awk '{print $3}' | tr -d '.')
        PAGES_ACTIVE=$(echo "$VM_STAT" | grep "Pages active" | awk '{print $3}' | tr -d '.')
        PAGES_INACTIVE=$(echo "$VM_STAT" | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
        PAGES_WIRED=$(echo "$VM_STAT" | grep "Pages wired down" | awk '{print $4}' | tr -d '.')
        
        # Cada página = 4KB no macOS
        if [[ -n "$PAGES_FREE" && "$PAGES_FREE" -gt 0 ]]; then
            FREE_MB=$((PAGES_FREE * 4 / 1024))
            ACTIVE_MB=$((PAGES_ACTIVE * 4 / 1024))
            INACTIVE_MB=$((PAGES_INACTIVE * 4 / 1024))
            WIRED_MB=$((PAGES_WIRED * 4 / 1024))
            
            echo "  Livre: ${FREE_MB}MB | Ativa: ${ACTIVE_MB}MB | Inativa: ${INACTIVE_MB}MB | Wired: ${WIRED_MB}MB"
        else
            echo "  Erro ao obter estatísticas de memória"
        fi
    else
        echo "Memória: N/A (comandos não disponíveis)"
    fi
    
    # Uso de memória e CPU dos containers Docker - Versão melhorada
    echo
    echo "Uso de Recursos dos Containers Holesky:"
    echo "---------------------------------------"
    
    # Lista completa dos containers relevantes para Holesky
    HOLESKY_CONTAINERS=(
        "geth"
        "lighthouse" 
        "rocketpool-node-holesky"
        "prometheus-holesky"
        "grafana-holesky"
        "node-exporter-holesky"
    )
    
    # Verificar quais containers estão rodando
    RUNNING_CONTAINERS=()
    for container in "${HOLESKY_CONTAINERS[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
            RUNNING_CONTAINERS+=("$container")
        fi
    done
    
    if [ ${#RUNNING_CONTAINERS[@]} -gt 0 ]; then
        # Cabeçalho personalizado
        printf "%-25s %-20s %-8s %-8s\n" "CONTAINER" "MEMÓRIA" "CPU%" "STATUS"
        printf "%-25s %-20s %-8s %-8s\n" "-------------------------" "--------------------" "--------" "--------"
        
        # Obter stats de cada container individualmente para melhor formatação
        for container in "${RUNNING_CONTAINERS[@]}"; do
            # Obter stats do container específico
            STATS=$(docker stats --no-stream --format "{{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}" "$container" 2>/dev/null)
            
            if [[ -n "$STATS" ]]; then
                # Extrair campos usando IFS
                IFS=$'\t' read -r name mem cpu <<< "$STATS"
                
                # Limpar espaços extras
                name=$(echo "$name" | xargs)
                mem=$(echo "$mem" | xargs)
                cpu=$(echo "$cpu" | xargs)
                
                # Formatar saída
                printf "%-25s %-20s %-8s %-8s\n" "$name" "$mem" "$cpu" "Running"
            fi
        done
        
        # Estatísticas resumidas
        echo
        echo "Containers em execução: ${#RUNNING_CONTAINERS[@]}/${#HOLESKY_CONTAINERS[@]}"
        
        # Containers parados
        STOPPED_CONTAINERS=()
        for container in "${HOLESKY_CONTAINERS[@]}"; do
            if ! docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
                STOPPED_CONTAINERS+=("$container")
            fi
        done
        
        if [ ${#STOPPED_CONTAINERS[@]} -gt 0 ]; then
            echo "Containers parados: ${STOPPED_CONTAINERS[*]}"
        fi
    else
        echo "Nenhum container Holesky em execução"
        echo "Containers esperados: ${HOLESKY_CONTAINERS[*]}"
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
    echo "docker logs geth"
    echo "docker logs lighthouse"
    echo "docker logs rocketpool-node-holesky"
    echo
    echo "# Reiniciar um serviço:"
    echo "docker-compose -f docker-compose-holesky.yml --env-file .env.holesky restart geth"
    echo "docker-compose -f docker-compose-holesky.yml --env-file .env.holesky restart lighthouse"
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
        check_lighthouse_sync
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
            check_lighthouse_sync
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
            check_lighthouse_sync
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

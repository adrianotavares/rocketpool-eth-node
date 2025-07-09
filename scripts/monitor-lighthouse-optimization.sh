#!/bin/bash

# Script: monitor-lighthouse-optimization.sh
# Objetivo: Monitorar o progresso das otimizações do Lighthouse
# Criado em: 8 de julho de 2025

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar API do Lighthouse
check_lighthouse_api() {
    local endpoint="$1"
    curl -s --max-time 10 "$endpoint" 2>/dev/null
}

# Função para obter dados da API
get_lighthouse_data() {
    local health=$(check_lighthouse_api "http://localhost:5052/eth/v1/node/health")
    local peers=$(check_lighthouse_api "http://localhost:5052/eth/v1/node/peer_count")
    local sync=$(check_lighthouse_api "http://localhost:5052/eth/v1/node/syncing")
    local version=$(check_lighthouse_api "http://localhost:5052/eth/v1/node/version")
    
    echo "health:$health"
    echo "peers:$peers"
    echo "sync:$sync"
    echo "version:$version"
}

# Função para mostrar status completo
show_full_status() {
    echo
    echo "========================================"
    echo "  MONITOR LIGHTHOUSE OPTIMIZATION"
    echo "========================================"
    echo
    echo "Data/Hora: $(date)"
    echo
    
    # Status dos containers
    log_info "Status dos Containers:"
    docker ps --filter "name=lighthouse" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || {
        log_error "Não foi possível verificar containers"
        return 1
    }
    
    echo
    
    # Verificar API
    log_info "Verificando API do Lighthouse..."
    
    local data=$(get_lighthouse_data)
    local health=$(echo "$data" | grep "health:" | cut -d: -f2)
    local peers=$(echo "$data" | grep "peers:" | cut -d: -f2)
    local sync=$(echo "$data" | grep "sync:" | cut -d: -f2)
    local version=$(echo "$data" | grep "version:" | cut -d: -f2)
    
    if [ -n "$health" ] && [ "$health" != "null" ]; then
        log_success "API está respondendo"
        
        # Extrair informações usando jq se disponível
        if command -v jq >/dev/null 2>&1; then
            if [ -n "$peers" ]; then
                local connected_peers=$(echo "$peers" | jq -r '.data.connected // "N/A"' 2>/dev/null || echo "N/A")
                local connecting_peers=$(echo "$peers" | jq -r '.data.connecting // "N/A"' 2>/dev/null || echo "N/A")
                local disconnected_peers=$(echo "$peers" | jq -r '.data.disconnected // "N/A"' 2>/dev/null || echo "N/A")
                
                echo "  Peers conectados: $connected_peers"
                echo "  Peers conectando: $connecting_peers"
                echo "  Peers desconectados: $disconnected_peers"
            fi
            
            if [ -n "$sync" ]; then
                local is_syncing=$(echo "$sync" | jq -r '.data.is_syncing // "N/A"' 2>/dev/null || echo "N/A")
                local head_slot=$(echo "$sync" | jq -r '.data.head_slot // "N/A"' 2>/dev/null || echo "N/A")
                local sync_distance=$(echo "$sync" | jq -r '.data.sync_distance // "N/A"' 2>/dev/null || echo "N/A")
                
                echo "  Sincronizando: $is_syncing"
                echo "  Slot atual: $head_slot"
                echo "  Distância: $sync_distance"
            fi
            
            if [ -n "$version" ]; then
                local lighthouse_version=$(echo "$version" | jq -r '.data.version // "N/A"' 2>/dev/null || echo "N/A")
                echo "  Versão: $lighthouse_version"
            fi
        else
            log_warning "jq não está disponível - dados brutos:"
            echo "  Peers: $peers"
            echo "  Sync: $sync"
        fi
    else
        log_error "API não está respondendo"
    fi
    
    echo
    
    # Verificar otimizações aplicadas
    log_info "Otimizações Aplicadas:"
    
    if grep -q "block-cache-size" docker-compose-holesky.yml 2>/dev/null; then
        log_success "Nível 1 (Básico) - APLICADO"
    else
        log_warning "Nível 1 (Básico) - NÃO APLICADO"
    fi
    
    if grep -q "target-peers" docker-compose-holesky.yml 2>/dev/null; then
        log_success "Nível 2 (Intermediário) - APLICADO"
    else
        log_warning "Nível 2 (Intermediário) - NÃO APLICADO"
    fi
    
    if grep -q "disable-backfill-rate-limiting" docker-compose-holesky.yml 2>/dev/null; then
        log_success "Nível 3 (Avançado) - APLICADO"
    else
        log_warning "Nível 3 (Avançado) - NÃO APLICADO"
    fi
    
    echo
    
    # Recursos do sistema
    log_info "Recursos do Sistema:"
    if command -v docker >/dev/null 2>&1; then
        local stats=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null | grep -E "(lighthouse|geth)" || echo "N/A")
        if [ "$stats" != "N/A" ]; then
            echo "$stats"
        else
            log_warning "Não foi possível obter estatísticas dos containers"
        fi
    fi
    
    echo
}

# Função para monitoramento contínuo
continuous_monitor() {
    local interval=${1:-60}
    
    echo "Iniciando monitoramento contínuo (intervalo: ${interval}s)"
    echo "Pressione Ctrl+C para parar"
    echo
    
    while true; do
        show_full_status
        echo "Próxima verificação em ${interval}s..."
        echo "========================================"
        sleep $interval
    done
}

# Função para salvar log
save_log() {
    local log_file="lighthouse-optimization-$(date +%Y%m%d_%H%M%S).log"
    show_full_status > "$log_file"
    log_success "Log salvo em: $log_file"
}

# Função para mostrar logs do Lighthouse
show_lighthouse_logs() {
    local lines=${1:-50}
    log_info "Últimos $lines logs do Lighthouse:"
    docker logs lighthouse --tail $lines
}

# Menu principal
show_menu() {
    echo
    echo "=========================================="
    echo "  MONITOR LIGHTHOUSE OPTIMIZATION"
    echo "=========================================="
    echo
    echo "1. Verificar Status Atual"
    echo "2. Monitoramento Contínuo (60s)"
    echo "3. Monitoramento Contínuo (30s)"
    echo "4. Mostrar Logs do Lighthouse"
    echo "5. Salvar Log Atual"
    echo "6. Sair"
    echo
    read -p "Selecione uma opção (1-6): " choice
}

# Função principal
main() {
    # Detectar diretório do projeto
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_dir="$(dirname "$script_dir")"
    
    # Mudar para o diretório do projeto
    cd "$project_dir"
    
    # Verificar se está no projeto correto
    if [ ! -f "docker-compose-holesky.yml" ]; then
        log_error "Arquivo docker-compose-holesky.yml não encontrado em $project_dir!"
        exit 1
    fi
    
    # Se argumentos foram passados, executar diretamente
    if [ $# -gt 0 ]; then
        case $1 in
            "status")
                show_full_status
                ;;
            "logs")
                show_lighthouse_logs ${2:-50}
                ;;
            "continuous")
                continuous_monitor ${2:-60}
                ;;
            "save")
                save_log
                ;;
            *)
                echo "Uso: $0 [status|logs|continuous|save]"
                exit 1
                ;;
        esac
        exit 0
    fi
    
    # Menu interativo
    while true; do
        show_menu
        
        case $choice in
            1)
                show_full_status
                ;;
            2)
                continuous_monitor 60
                ;;
            3)
                continuous_monitor 30
                ;;
            4)
                show_lighthouse_logs
                ;;
            5)
                save_log
                ;;
            6)
                log_info "Saindo..."
                exit 0
                ;;
            *)
                log_error "Opção inválida!"
                ;;
        esac
        
        echo
        read -p "Pressione Enter para continuar..."
    done
}

# Executar
main "$@"

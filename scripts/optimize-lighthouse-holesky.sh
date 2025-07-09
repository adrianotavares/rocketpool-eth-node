#!/bin/bash

# Script: optimize-lighthouse-holesky.sh
# Objetivo: Aplicar otimizações específicas no Lighthouse para Holesky
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

# Função para criar backup
create_backup() {
    if [ -f "docker-compose-holesky.yml" ]; then
        local backup_name="docker-compose-holesky.yml.backup.$(date +%Y%m%d_%H%M%S)"
        cp docker-compose-holesky.yml "$backup_name"
        log_success "Backup criado: $backup_name"
    else
        log_error "Arquivo docker-compose-holesky.yml não encontrado!"
        exit 1
    fi
}

# Função para aplicar otimizações nível 1
apply_level1() {
    log_info "Aplicando otimizações Nível 1 (Básico) para Holesky..."
    
    # Fazer backup
    create_backup
    
    # Verificar se otimizações já foram aplicadas
    if grep -q "block-cache-size" docker-compose-holesky.yml; then
        log_warning "Otimizações Nível 1 já foram aplicadas!"
        log_info "Use o rollback para restaurar o estado original primeiro."
        return 0
    fi
    
    # Aplicar otimizações básicas
    sed -i '' 's/--checkpoint-sync-url=https:\/\/holesky\.checkpoint\.sigp\.io/--checkpoint-sync-url=https:\/\/holesky.checkpoint.sigp.io\
      --block-cache-size=10\
      --historic-state-cache-size=4\
      --auto-compact-db=true/' docker-compose-holesky.yml
    
    log_success "Otimizações Nível 1 aplicadas com sucesso!"
}

# Função para aplicar otimizações nível 2
apply_level2() {
    log_info "Aplicando otimizações Nível 2 (Intermediário) para Holesky..."
    
    # Verificar se nível 1 já foi aplicado
    if ! grep -q "block-cache-size" docker-compose-holesky.yml; then
        log_info "Aplicando Nível 1 primeiro..."
        apply_level1
    fi
    
    # Verificar se nível 2 já foi aplicado
    if grep -q "target-peers" docker-compose-holesky.yml; then
        log_warning "Otimizações Nível 2 já foram aplicadas!"
        return 0
    fi
    
    # Adicionar otimizações nível 2
    sed -i '' 's/--auto-compact-db=true/--auto-compact-db=true\
      --target-peers=80\
      --subscribe-all-subnets\
      --import-all-attestations\
      --quic-port=9001/' docker-compose-holesky.yml
    
    # Adicionar porta QUIC se não existir
    if ! grep -q "9001:9001/udp" docker-compose-holesky.yml; then
        sed -i '' '/- "9000:9000\/udp"/a\
      - "9001:9001/udp"    # QUIC' docker-compose-holesky.yml
    fi
    
    log_success "Otimizações Nível 2 aplicadas com sucesso!"
}

# Função para aplicar otimizações nível 3
apply_level3() {
    log_info "Aplicando otimizações Nível 3 (Avançado) para Holesky..."
    
    log_warning "ATENÇÃO: Otimizações Nível 3 são mais agressivas!"
    read -p "Deseja continuar? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operação cancelada."
        return 0
    fi
    
    # Verificar se nível 2 já foi aplicado
    if ! grep -q "target-peers" docker-compose-holesky.yml; then
        log_info "Aplicando Nível 2 primeiro..."
        apply_level2
    fi
    
    # Verificar se nível 3 já foi aplicado
    if grep -q "disable-backfill-rate-limiting" docker-compose-holesky.yml; then
        log_warning "Otimizações Nível 3 já foram aplicadas!"
        return 0
    fi
    
    # Adicionar otimizações nível 3
    sed -i '' 's/--quic-port=9001/--quic-port=9001\
      --disable-backfill-rate-limiting\
      --prune-payloads=true\
      --prune-blobs=true\
      --epochs-per-blob-prune=128/' docker-compose-holesky.yml
    
    log_success "Otimizações Nível 3 aplicadas com sucesso!"
}

# Função para reiniciar serviços
restart_services() {
    log_info "Reiniciando serviços Holesky..."
    
    docker-compose -f docker-compose-holesky.yml down
    sleep 5
    docker-compose -f docker-compose-holesky.yml up -d
    
    log_success "Serviços reiniciados!"
}

# Função para verificar status
check_status() {
    log_info "Verificando status do Lighthouse..."
    
    sleep 10
    
    # Verificar se container está rodando
    if docker ps --format "{{.Names}}" | grep -q "lighthouse"; then
        log_success "Container Lighthouse está rodando"
    else
        log_error "Container Lighthouse não está rodando"
        return 1
    fi
    
    # Verificar API
    local retries=0
    while [ $retries -lt 5 ]; do
        if curl -s --max-time 10 http://localhost:5052/eth/v1/node/health >/dev/null 2>&1; then
            log_success "API do Lighthouse está respondendo"
            break
        else
            log_info "Aguardando API... ($((retries+1))/5)"
            sleep 15
            retries=$((retries+1))
        fi
    done
    
    if [ $retries -eq 5 ]; then
        log_warning "API ainda não está respondendo, mas pode estar inicializando"
    fi
    
    # Mostrar informações básicas
    local peers=$(curl -s --max-time 10 http://localhost:5052/eth/v1/node/peer_count 2>/dev/null | jq -r '.data.connected // "N/A"' 2>/dev/null || echo "N/A")
    local sync_status=$(curl -s --max-time 10 http://localhost:5052/eth/v1/node/syncing 2>/dev/null | jq -r '.data.is_syncing // "N/A"' 2>/dev/null || echo "N/A")
    
    log_info "Peers conectados: $peers"
    log_info "Sincronizando: $sync_status"
}

# Função para mostrar logs
show_logs() {
    log_info "Últimos logs do Lighthouse:"
    docker logs lighthouse --tail 30
}

# Função para rollback
rollback() {
    log_info "Fazendo rollback..."
    
    local latest_backup=$(ls -t docker-compose-holesky.yml.backup.* 2>/dev/null | head -1)
    
    if [ -n "$latest_backup" ]; then
        log_info "Restaurando: $latest_backup"
        cp "$latest_backup" docker-compose-holesky.yml
        restart_services
        log_success "Rollback concluído!"
    else
        log_error "Nenhum backup encontrado!"
        return 1
    fi
}

# Menu principal
show_menu() {
    echo
    echo "=========================================="
    echo "  OTIMIZADOR LIGHTHOUSE HOLESKY"
    echo "=========================================="
    echo
    echo "1. Aplicar Otimizações Nível 1 (Básico)"
    echo "2. Aplicar Otimizações Nível 2 (Intermediário)"
    echo "3. Aplicar Otimizações Nível 3 (Avançado)"
    echo "4. Reiniciar Serviços"
    echo "5. Verificar Status"
    echo "6. Mostrar Logs"
    echo "7. Rollback (Restaurar Backup)"
    echo "8. Sair"
    echo
    read -p "Selecione uma opção (1-8): " choice
}

# Função principal
main() {
    # Detectar diretório do projeto automaticamente
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_dir="$(dirname "$script_dir")"
    
    # Mudar para o diretório do projeto
    cd "$project_dir"
    
    log_info "Diretório do projeto: $project_dir"
    
    # Verificar se arquivo existe
    if [ ! -f "docker-compose-holesky.yml" ]; then
        log_error "Arquivo docker-compose-holesky.yml não encontrado em $project_dir!"
        log_error "Verificando estrutura do diretório..."
        ls -la docker-compose*.yml 2>/dev/null || log_error "Nenhum arquivo docker-compose encontrado"
        exit 1
    fi
    
    # Verificar se container está rodando
    if ! docker ps --format "{{.Names}}" | grep -q "lighthouse"; then
        log_warning "Container Lighthouse não está rodando!"
        log_info "Iniciando serviços primeiro..."
        docker-compose -f docker-compose-holesky.yml up -d
        sleep 10
    fi
    
    while true; do
        show_menu
        
        case $choice in
            1)
                apply_level1
                restart_services
                check_status
                ;;
            2)
                apply_level2
                restart_services
                check_status
                ;;
            3)
                apply_level3
                restart_services
                check_status
                ;;
            4)
                restart_services
                check_status
                ;;
            5)
                check_status
                ;;
            6)
                show_logs
                ;;
            7)
                rollback
                ;;
            8)
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

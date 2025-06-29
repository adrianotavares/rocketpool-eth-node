#!/bin/bash

# =============================================================================
# Rocket Pool SSD Setup Script
# =============================================================================
# Este script configura automaticamente o ambiente SSD externo para o 
# Rocket Pool Ethereum Node, mantendo os arquivos originais intactos.
# =============================================================================

set -e  # Exit on any error

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
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

print_banner() {
    echo
    echo "============================================================"
    echo "   Rocket Pool Ethereum Node - Configuração SSD Externo"
    echo "============================================================"
    echo
}

check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker não encontrado. Instale o Docker primeiro."
        exit 1
    fi
    
    # Verificar Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose não encontrado. Instale o Docker Compose primeiro."
        exit 1
    fi
    
    # Verificar se estamos no diretório correto
    if [ ! -f "docker-compose.yml" ]; then
        log_error "Arquivo docker-compose.yml não encontrado. Execute este script no diretório do projeto."
        exit 1
    fi
    
    log_success "Pré-requisitos verificados!"
}

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        DEFAULT_SSD_PATH="/Volumes/EthereumNode"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="Linux"
        DEFAULT_SSD_PATH="/mnt/ethereum-ssd"
    else
        OS="Windows/Other"
        DEFAULT_SSD_PATH="/c/EthereumNode"
    fi
    
    log_info "Sistema operacional detectado: $OS"
}

get_ssd_path() {
    echo
    log_info "Configuração do SSD Externo"
    echo "----------------------------------------"
    echo "Sistema detectado: $OS"
    echo "Caminho padrão: $DEFAULT_SSD_PATH"
    echo
    
    while true; do
        read -p "Caminho do SSD externo [$DEFAULT_SSD_PATH]: " SSD_PATH
        SSD_PATH="${SSD_PATH:-$DEFAULT_SSD_PATH}"
        
        if [ -d "$SSD_PATH" ]; then
            log_success "SSD encontrado em: $SSD_PATH"
            break
        else
            log_warning "Diretório não encontrado: $SSD_PATH"
            echo "Opções:"
            echo "1. Verificar se o SSD está conectado e montado"
            echo "2. Criar o diretório manualmente"
            echo "3. Tentar outro caminho"
            echo
            read -p "Deseja criar o diretório? (y/n): " create_dir
            if [[ $create_dir =~ ^[Yy]$ ]]; then
                if mkdir -p "$SSD_PATH" 2>/dev/null; then
                    log_success "Diretório criado: $SSD_PATH"
                    break
                else
                    log_error "Não foi possível criar o diretório. Verifique as permissões."
                    echo
                fi
            fi
        fi
    done
}

check_ssd_space() {
    log_info "Verificando espaço disponível no SSD..."
    
    if command -v df &> /dev/null; then
        AVAILABLE_SPACE=$(df -h "$SSD_PATH" 2>/dev/null | awk 'NR==2{print $4}' || echo "Unknown")
        TOTAL_SPACE=$(df -h "$SSD_PATH" 2>/dev/null | awk 'NR==2{print $2}' || echo "Unknown")
        
        echo "Espaço total: $TOTAL_SPACE"
        echo "Espaço disponível: $AVAILABLE_SPACE"
        
        # Verificar se tem pelo menos 900GB disponíveis (aproximado)
        AVAILABLE_GB=$(df "$SSD_PATH" 2>/dev/null | awk 'NR==2{print int($4/1024/1024)}' || echo "0")
        if [ "$AVAILABLE_GB" -lt 900 ]; then
            log_warning "Espaço disponível pode ser insuficiente para sincronização completa."
            log_warning "Recomendado: 900GB+ disponíveis. Atual: ${AVAILABLE_GB}GB"
            echo
            read -p "Deseja continuar mesmo assim? (y/n): " continue_anyway
            if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
                log_error "Setup cancelado pelo usuário."
                exit 1
            fi
        else
            log_success "Espaço suficiente disponível: ${AVAILABLE_GB}GB"
        fi
    else
        log_warning "Não foi possível verificar o espaço disponível."
    fi
}

create_directory_structure() {
    log_info "Criando estrutura de diretórios..."
    
    # Criar diretórios principais
    DIRS=(
        "$SSD_PATH/ethereum-data"
        "$SSD_PATH/ethereum-data/execution-data"
        "$SSD_PATH/ethereum-data/consensus-data"
        "$SSD_PATH/ethereum-data/rocketpool-data"
        "$SSD_PATH/ethereum-data/prometheus-data"
        "$SSD_PATH/ethereum-data/grafana-data"
        "$SSD_PATH/backups"
        "$SSD_PATH/logs"
    )
    
    for dir in "${DIRS[@]}"; do
        if mkdir -p "$dir"; then
            log_success "Criado: $dir"
        else
            log_error "Falha ao criar: $dir"
            exit 1
        fi
    done
    
    # Definir permissões adequadas
    if chmod -R 755 "$SSD_PATH/ethereum-data" && chmod -R 755 "$SSD_PATH/backups"; then
        log_success "Permissões definidas corretamente"
    else
        log_warning "Não foi possível definir todas as permissões. Pode ser necessário ajuste manual."
    fi
}

update_env_file() {
    log_info "Atualizando arquivo de configuração .env.ssd..."
    
    # Backup do arquivo original se existir
    if [ -f ".env.ssd" ]; then
        cp ".env.ssd" ".env.ssd.backup.$(date +%Y%m%d-%H%M%S)"
        log_info "Backup criado do arquivo .env.ssd existente"
    fi
    
    # Atualizar variáveis no arquivo .env.ssd
    sed -i.bak "s|^SSD_BASE_PATH=.*|SSD_BASE_PATH=$SSD_PATH|" .env.ssd
    sed -i.bak "s|^SYSTEM_OS=.*|SYSTEM_OS=$OS|" .env.ssd
    sed -i.bak "s|^SETUP_DATE=.*|SETUP_DATE=$(date)|" .env.ssd
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        sed -i.bak "s|^DOCKER_VERSION=.*|DOCKER_VERSION=$DOCKER_VERSION|" .env.ssd
    fi
    
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
        sed -i.bak "s|^COMPOSE_VERSION=.*|COMPOSE_VERSION=$COMPOSE_VERSION|" .env.ssd
    fi
    
    # Limpar arquivos temporários
    rm -f .env.ssd.bak
    
    log_success "Arquivo .env.ssd atualizado com sucesso!"
}

create_monitoring_script() {
    log_info "Criando script de monitoramento..."
    
    if [ ! -f "monitor-ssd.sh" ]; then
        log_warning "Script monitor-ssd.sh não encontrado. Será necessário criá-lo separadamente."
    else
        chmod +x monitor-ssd.sh
        log_success "Script de monitoramento configurado"
    fi
}

show_next_steps() {
    echo
    log_success "Configuração concluída com sucesso!"
    echo
    echo "Estrutura criada em: $SSD_PATH"
    echo "Arquivo de configuração: .env.ssd"
    echo "Docker Compose para SSD: docker-compose.ssd.yml"
    echo
    echo "PRÓXIMOS PASSOS:"
    echo "===================="
    echo
    echo "1. Iniciar os serviços:"
    echo "   docker-compose -f docker-compose.ssd.yml --env-file .env.ssd up -d"
    echo
    echo "2. Verificar status dos containers:"
    echo "   docker ps"
    echo
    echo "3. Acompanhar logs da sincronização:"
    echo "   docker-compose -f docker-compose.ssd.yml logs -f"
    echo
    echo "4. Monitorar espaço do SSD:"
    echo "   ./monitor-ssd.sh"
    echo
    echo "5. Acessar interfaces web:"
    echo "   - Grafana: http://localhost:3000 (admin/admin)"
    echo "   - Prometheus: http://localhost:9090"
    echo
    echo "📋 COMANDOS ÚTEIS:"
    echo "=================="
    echo
    echo "# Parar serviços"
    echo "docker-compose -f docker-compose.ssd.yml down"
    echo
    echo "# Ver logs específicos"
    echo "docker logs execution-client"
    echo "docker logs consensus-client"
    echo
    echo "# Verificar sincronização"
    echo "curl -X POST -H \"Content-Type: application/json\" \\"
    echo "  --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_syncing\",\"params\":[],\"id\":1}' \\"
    echo "  http://localhost:8545"
    echo
    echo "IMPORTANTE:"
    echo "==============="
    echo "- A sincronização inicial pode levar 4-8 horas"
    echo "- Mantenha o SSD sempre conectado durante a operação"
    echo "- Configure backups regulares dos dados importantes"
    echo "- Monitore o espaço disponível regularmente"
    echo
    log_info "Para mais informações, consulte: SSD-CONFIG.md"
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    print_banner
    
    check_prerequisites
    detect_os
    get_ssd_path
    check_ssd_space
    create_directory_structure
    update_env_file
    create_monitoring_script
    show_next_steps
    
    echo
    log_success "Setup concluído! Execute os comandos acima para iniciar o seu Rocket Pool Node."
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

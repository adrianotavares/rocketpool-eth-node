#!/bin/bash

# Setup do Rocket Pool Node para Testnet Holesky
# Este script configura automaticamente o ambiente para a testnet Holesky

set -e  # Sair em caso de erro

# Mudar para o diretório raiz do projeto
cd "$(dirname "$0")/../.."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Banner
echo "=================================================="
echo "🚀 Rocket Pool Holesky Testnet Setup"
echo "=================================================="
echo ""

# Verificar se Docker está rodando
if ! docker info >/dev/null 2>&1; then
    error "Docker não está rodando. Por favor, inicie o Docker e tente novamente."
    exit 1
fi

log "Docker está rodando ✓"

# Verificar se docker-compose está disponível
if ! command -v docker-compose &> /dev/null; then
    error "docker-compose não está instalado."
    exit 1
fi

log "docker-compose está disponível ✓"

# Verificar se os arquivos necessários existem
required_files=("docker-compose-holesky.yml" ".env.holesky" "prometheus-holesky.yml")
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        error "Arquivo necessário não encontrado: $file"
        exit 1
    fi
done

log "Todos os arquivos necessários estão presentes ✓"

# Verificar arquivo .env.holesky
if [[ ! -f ".env.holesky" ]]; then
    error "Arquivo .env.holesky não encontrado!"
    exit 1
fi

# Carregar variáveis de ambiente
source .env.holesky

# Verificar se SSD_MOUNT_PATH está definido e existe
if [[ -n "$SSD_MOUNT_PATH" ]]; then
    if [[ ! -d "$SSD_MOUNT_PATH" ]]; then
        warn "SSD mount path não encontrado: $SSD_MOUNT_PATH"
        warn "Usando armazenamento local ao invés de SSD externo"
        
        # Usar caminhos locais como fallback
        export EXECUTION_DATA_PATH="./execution-data-holesky"
        export CONSENSUS_DATA_PATH="./consensus-data-holesky"
        export ROCKETPOOL_DATA_PATH="./rocketpool-holesky"
        export PROMETHEUS_DATA_PATH="./prometheus-data-holesky"
        export GRAFANA_DATA_PATH="./grafana-data-holesky"
        export ALERTMANAGER_DATA_PATH="./alertmanager-data-holesky"
    else
        log "SSD externo encontrado: $SSD_MOUNT_PATH ✓"
    fi
fi

# Criar diretórios necessários
log "Criando diretórios de dados..."

directories=(
    "$EXECUTION_DATA_PATH"
    "$CONSENSUS_DATA_PATH"
    "$ROCKETPOOL_DATA_PATH"
    "$PROMETHEUS_DATA_PATH"
    "$GRAFANA_DATA_PATH"
    "$ALERTMANAGER_DATA_PATH"
    "./grafana/provisioning/dashboards"
    "./grafana/provisioning/datasources"
    "./alerts"
    "./alertmanager"
)

for dir in "${directories[@]}"; do
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log "Criado diretório: $dir"
    fi
done

# Verificar espaço em disco
if [[ -n "$SSD_MOUNT_PATH" && -d "$SSD_MOUNT_PATH" ]]; then
    available_space=$(df "$SSD_MOUNT_PATH" | awk 'NR==2 {print $4}')
    available_gb=$((available_space / 1024 / 1024))
    
    if [[ $available_gb -lt 100 ]]; then
        warn "Pouco espaço disponível: ${available_gb}GB (recomendado: 200GB+ para testnet)"
    else
        log "Espaço disponível: ${available_gb}GB ✓"
    fi
fi

# Verificar se há containers rodando que possam conflitar
conflicting_containers=$(docker ps --format "{{.Names}}" | grep -E "(geth|lighthouse|rocketpool|prometheus|grafana)" | grep -v holesky || true)

if [[ -n "$conflicting_containers" ]]; then
    warn "Containers que podem conflitar estão rodando:"
    echo "$conflicting_containers"
    
    read -p "Deseja parar estes containers? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$conflicting_containers" | xargs -r docker stop
        log "Containers parados"
    else
        warn "Continuando com containers conflitantes rodando..."
    fi
fi

# Verificar portas
log "Verificando disponibilidade de portas..."

ports=(30303 9000 8545 8551 5052 6060 5054 9090 3000 9100 9093 8000)
busy_ports=()

for port in "${ports[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null; then
        busy_ports+=($port)
    fi
done

if [[ ${#busy_ports[@]} -gt 0 ]]; then
    warn "Portas ocupadas: ${busy_ports[*]}"
    warn "Isso pode causar conflitos. Considere parar os serviços que estão usando essas portas."
fi

# Mostrar configuração
echo ""
info "=== CONFIGURAÇÃO HOLESKY TESTNET ==="
info "Execution Data: $EXECUTION_DATA_PATH"
info "Consensus Data: $CONSENSUS_DATA_PATH"
info "Rocket Pool Data: $ROCKETPOOL_DATA_PATH"
info "Network: Holesky (Chain ID: 17000)"
info "Checkpoint URL: https://holesky.checkpoint.sigp.io"
info "=================================="
echo ""

# Confirmar início
read -p "Iniciar o nó Rocket Pool na testnet Holesky? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Setup cancelado pelo usuário."
    exit 0
fi

# Parar qualquer configuração anterior do Holesky
if docker-compose -f docker-compose-holesky.yml ps -q | grep -q .; then
    log "Parando configuração anterior do Holesky..."
    docker-compose -f docker-compose-holesky.yml --env-file .env.holesky down
fi

# Iniciar os serviços
log "Iniciando serviços da testnet Holesky..."
docker-compose -f docker-compose-holesky.yml --env-file .env.holesky up -d

# Aguardar um pouco para os containers iniciarem
sleep 10

# Verificar status dos containers
log "Verificando status dos containers..."
docker-compose -f docker-compose-holesky.yml ps

# Verificar conectividade
log "Verificando conectividade dos serviços..."

# Testar Geth
if curl -s -f -X POST -H "Content-Type: application/json" \
   --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
   http://localhost:8545 >/dev/null 2>&1; then
    log "Geth está respondendo ✓"
else
    warn "Geth ainda não está respondendo (normal durante inicialização)"
fi

# Testar Prometheus
if curl -s -f http://localhost:9090/-/healthy >/dev/null 2>&1; then
    log "Prometheus está saudável ✓"
else
    warn "Prometheus ainda não está respondendo"
fi

# Testar Grafana
if curl -s -f http://localhost:3000/api/health >/dev/null 2>&1; then
    log "Grafana está saudável ✓"
else
    warn "Grafana ainda não está respondendo"
fi

echo ""
log "=== SETUP CONCLUÍDO ==="
echo ""

info "🌐 URLs de Acesso:"
info "   Grafana: http://localhost:3000 (admin/admin)"
info "   Prometheus: http://localhost:9090"
info "   Geth RPC: http://localhost:8545"
info "   Lighthouse API: http://localhost:5052"
echo ""

info "📊 Comandos Úteis:"
info "   Ver logs: docker-compose -f docker-compose-holesky.yml logs -f"
info "   Status: docker-compose -f docker-compose-holesky.yml ps"
info "   Parar: docker-compose -f docker-compose-holesky.yml down"
info "   Rocket Pool CLI: docker exec -it rocketpool-node-holesky /bin/bash"
echo ""

info "🔗 Recursos da Testnet Holesky:"
info "   Faucet: https://holesky-faucet.pk910.de/"
info "   Explorer: https://holesky.etherscan.io/"
info "   Beaconcha.in: https://holesky.beaconcha.in/"
echo ""

info "⏱️  Tempo de Sincronização Estimado:"
info "   Lighthouse: 5-15 minutos (checkpoint sync)"
info "   Geth: 1-3 horas (snap sync)"
echo ""

warn "📝 PRÓXIMOS PASSOS:"
warn "1. Aguarde a sincronização dos clientes (monitore os logs)"
warn "2. Obtenha ETH de teste nos faucets listados acima"
warn "3. Configure sua carteira Rocket Pool"
warn "4. Registre-se como node operator"
echo ""

info "Para monitorar a sincronização:"
info "   docker-compose -f docker-compose-holesky.yml logs -f execution-client"
info "   docker-compose -f docker-compose-holesky.yml logs -f consensus-client"
echo ""

log "Setup da testnet Holesky iniciado com sucesso! 🚀"
echo "=================================================="

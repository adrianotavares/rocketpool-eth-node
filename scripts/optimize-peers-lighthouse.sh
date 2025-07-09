#!/bin/bash

# Script para otimizar conectividade de peers no Lighthouse Holesky
# Aplica configurações específicas para melhorar descoberta e conexão P2P

set -e

COMPOSE_FILE="/Users/adrianotavares/dev/rocketpool-eth-node/docker-compose-holesky.yml"
BACKUP_FILE="/Users/adrianotavares/dev/rocketpool-eth-node/docker-compose-holesky.yml.backup-peers-$(date +%Y%m%d-%H%M%S)"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}   LIGHTHOUSE PEER OPTIMIZATION         ${NC}"
echo -e "${BLUE}==========================================${NC}"
echo

# Função para criar backup
create_backup() {
    echo -e "${BLUE}📦 Criando backup do docker-compose...${NC}"
    cp "$COMPOSE_FILE" "$BACKUP_FILE"
    echo -e "${GREEN}✅ Backup criado: $BACKUP_FILE${NC}"
    echo
}

# Função para verificar status atual
check_current_status() {
    echo -e "${BLUE}📊 Status atual dos peers...${NC}"
    
    if curl -s http://localhost:5052/eth/v1/node/health > /dev/null 2>&1; then
        local peer_count=$(curl -s http://localhost:5052/eth/v1/node/peer_count | jq -r '.data.connected')
        echo -e "  Peers conectados: ${YELLOW}$peer_count${NC}"
        
        # Verificar UPnP
        local upnp_status=$(docker logs lighthouse 2>&1 | grep -i "upnp" | tail -1)
        if echo "$upnp_status" | grep -q "not support"; then
            echo -e "  UPnP: ${RED}❌ Não suportado${NC}"
        else
            echo -e "  UPnP: ${GREEN}✅ Funcionando${NC}"
        fi
        
        # Verificar portas
        local tcp_port=$(netstat -tlnp 2>/dev/null | grep :9000 | head -1)
        if [ -n "$tcp_port" ]; then
            echo -e "  Porta 9000/TCP: ${GREEN}✅ Aberta${NC}"
        else
            echo -e "  Porta 9000/TCP: ${RED}❌ Fechada${NC}"
        fi
        
    else
        echo -e "  ${RED}❌ Lighthouse não está acessível${NC}"
    fi
    echo
}

# Função para aplicar otimizações no docker-compose
apply_optimizations() {
    echo -e "${BLUE}🔧 Aplicando otimizações...${NC}"
    
    # Backup atual
    create_backup
    
    # Configurações otimizadas para peers
    local optimized_config="      lighthouse bn
      --network=holesky
      --datadir=/root/.lighthouse
      --http
      --http-address=0.0.0.0
      --http-port=5052
      --execution-endpoint=http://geth:8551
      --execution-jwt=/secrets/jwtsecret
      --metrics
      --metrics-address=0.0.0.0
      --metrics-port=5054
      --port=9000
      --discovery-port=9000
      --block-cache-size=10
      --historic-state-cache-size=4
      --auto-compact-db=true
      --checkpoint-sync-url=https://checkpoint-sync.holesky.ethpandaops.io
      --checkpoint-sync-url-timeout=600
      --target-peers=25
      --discovery-address=0.0.0.0
      --libp2p-addresses=/ip4/0.0.0.0/tcp/9000
      --libp2p-addresses=/ip4/0.0.0.0/udp/9000
      --subscribe-all-subnets=true
      --import-all-attestations=true
      --enr-tcp-port=9000
      --enr-udp-port=9000"
    
    # Aplicar configurações
    # Encontrar a linha do comando do lighthouse e substituir
    local start_line=$(grep -n "command: >" "$COMPOSE_FILE" | grep -A 20 lighthouse | head -1 | cut -d: -f1)
    local end_line=$(grep -n "networks:" "$COMPOSE_FILE" | grep -A 2 lighthouse | head -1 | cut -d: -f1)
    
    if [ -n "$start_line" ] && [ -n "$end_line" ]; then
        # Criar arquivo temporário com as otimizações
        head -n $((start_line)) "$COMPOSE_FILE" > /tmp/lighthouse-optimized.yml
        echo "    command: >" >> /tmp/lighthouse-optimized.yml
        echo "$optimized_config" >> /tmp/lighthouse-optimized.yml
        tail -n +$((end_line)) "$COMPOSE_FILE" >> /tmp/lighthouse-optimized.yml
        
        # Substituir arquivo original
        mv /tmp/lighthouse-optimized.yml "$COMPOSE_FILE"
        
        echo -e "${GREEN}✅ Configurações de peer otimizadas aplicadas${NC}"
        echo -e "   • Target peers: 25 (adequado para testnet)"
        echo -e "   • Discovery otimizado"
        echo -e "   • Binding em todas as interfaces"
        echo -e "   • Subnets subscription habilitada"
        echo
    else
        echo -e "${RED}❌ Erro ao localizar configuração do lighthouse${NC}"
        echo -e "   Restaurando backup..."
        cp "$BACKUP_FILE" "$COMPOSE_FILE"
        exit 1
    fi
}

# Função para verificar configuração de firewall
check_firewall_config() {
    echo -e "${BLUE}🔥 Verificando configuração de firewall...${NC}"
    
    # Verificar UFW
    if command -v ufw > /dev/null 2>&1; then
        local ufw_status=$(ufw status 2>/dev/null || echo "inactive")
        echo -e "  UFW Status: $ufw_status"
        
        if echo "$ufw_status" | grep -q "active"; then
            if echo "$ufw_status" | grep -q "9000"; then
                echo -e "  Porta 9000: ${GREEN}✅ Permitida${NC}"
            else
                echo -e "  Porta 9000: ${RED}❌ Bloqueada${NC}"
                echo -e "    ${YELLOW}💡 Execute: sudo ufw allow 9000${NC}"
            fi
        fi
    else
        echo -e "  UFW: ${YELLOW}⚠️ Não instalado${NC}"
    fi
    
    # Verificar iptables
    if command -v iptables > /dev/null 2>&1; then
        local iptables_rules=$(iptables -L INPUT -n 2>/dev/null | grep -c "9000" || echo "0")
        if [ "$iptables_rules" -gt 0 ]; then
            echo -e "  Iptables 9000: ${GREEN}✅ Regras encontradas${NC}"
        else
            echo -e "  Iptables 9000: ${YELLOW}⚠️ Nenhuma regra específica${NC}"
        fi
    fi
    echo
}

# Função para gerar bootstrap nodes da Holesky
generate_bootstrap_nodes() {
    echo -e "${BLUE}🚀 Bootstrap nodes para Holesky...${NC}"
    
    # Lista de bootstrap nodes conhecidos da Holesky
    local bootstrap_nodes=(
        "enr:-MS4QHqVWGOE4J0TzA0CcpAhQivoNGdnPvhWgBZmkq9qBvx1GpOGF1mAmzjZmqpKBBW7cZWqKJcHNzAuJaB4tIUKhbcBh2F0dG5ldHOIAAAAAAAAAACEZXRoMpDV6jKDAAAAAAGFZXNoAXNlAg"
        "enr:-MS4QFo0lxZXWUHhxF9eXF5vZKxaRo8oLpTTQBdRY1hVzIgRhgOYKEjhIgFPZoJdERlYY4TRjVXVkBxjRZfA2kDJpQcBh2F0dG5ldHOIAAAAAAAAAACEZXRoMpDV6jKDAAAAAAGFZXNoAXNlAg"
    )
    
    echo -e "  Disponíveis: ${#bootstrap_nodes[@]} bootstrap nodes"
    echo -e "  ${YELLOW}💡 Para usar, adicione ao docker-compose:${NC}"
    echo -e "    --boot-nodes=enr:-MS4QHqVWGOE4J0TzA0CcpAhQivoNGdnPvhWgBZmkq9qBvx1GpOGF1mAmzjZmqpKBBW7cZWqKJcHNzAuJaB4tIUKhbcBh2F0dG5ldHOIAAAAAAAAAACEZXRoMpDV6jKDAAAAAAGFZXNoAXNlAg"
    echo
}

# Função para aplicar configurações de rede avançadas
apply_advanced_network_config() {
    echo -e "${BLUE}🌐 Configurações avançadas de rede...${NC}"
    
    # Verificar se Docker está usando bridge customizada
    local network_info=$(docker network inspect rocketpool-eth-node_holesky-network 2>/dev/null || echo "not found")
    
    if echo "$network_info" | grep -q "not found"; then
        echo -e "  ${YELLOW}⚠️ Rede Docker não encontrada${NC}"
        echo -e "    Execute: docker-compose up -d para criar a rede"
    else
        echo -e "  ${GREEN}✅ Rede Docker configurada${NC}"
    fi
    
    # Verificar configuração de DNS
    local dns_config=$(docker inspect lighthouse 2>/dev/null | jq -r '.[0].HostConfig.Dns[]?' || echo "default")
    echo -e "  DNS: $dns_config"
    
    # Sugestões para otimização
    echo -e "  ${YELLOW}💡 Otimizações recomendadas:${NC}"
    echo -e "    • Configurar IP público no ENR se disponível"
    echo -e "    • Verificar port forwarding no router"
    echo -e "    • Considerar VPN se houver NAT restritivo"
    echo
}

# Função para restart otimizado
restart_lighthouse() {
    echo -e "${BLUE}🔄 Reiniciando Lighthouse com otimizações...${NC}"
    
    # Parar lighthouse
    echo -e "  Parando container..."
    docker-compose -f "$COMPOSE_FILE" stop lighthouse
    
    # Aguardar alguns segundos
    sleep 5
    
    # Iniciar lighthouse
    echo -e "  Iniciando container otimizado..."
    docker-compose -f "$COMPOSE_FILE" up -d lighthouse
    
    # Aguardar inicialização
    echo -e "  Aguardando inicialização..."
    sleep 10
    
    # Verificar se iniciou corretamente
    if curl -s http://localhost:5052/eth/v1/node/health > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Lighthouse reiniciado com sucesso${NC}"
    else
        echo -e "  ${RED}❌ Erro ao reiniciar Lighthouse${NC}"
        echo -e "    Verifique os logs: docker logs lighthouse"
        exit 1
    fi
    echo
}

# Função para verificar melhorias
verify_improvements() {
    echo -e "${BLUE}📈 Verificando melhorias...${NC}"
    
    # Aguardar estabilização
    sleep 30
    
    # Verificar nova contagem de peers
    local new_peer_count=$(curl -s http://localhost:5052/eth/v1/node/peer_count | jq -r '.data.connected')
    echo -e "  Peers conectados: ${GREEN}$new_peer_count${NC}"
    
    # Verificar logs para sucesso
    local recent_logs=$(docker logs lighthouse --tail=10 2>&1 | grep -i "peer\|discovery" | tail -3)
    if [ -n "$recent_logs" ]; then
        echo -e "  ${BLUE}Logs recentes:${NC}"
        echo "$recent_logs" | while read -r line; do
            echo -e "    $line"
        done
    fi
    
    # Verificar ENR
    local enr_log=$(docker logs lighthouse 2>&1 | grep "ENR Initialised" | tail -1)
    if [ -n "$enr_log" ]; then
        echo -e "  ${GREEN}✅ ENR inicializado${NC}"
    fi
    echo
}

# Função para gerar relatório de otimização
generate_optimization_report() {
    echo -e "${BLUE}📊 Relatório de Otimização${NC}"
    echo "=================================="
    echo "Data: $(date)"
    echo "Backup: $BACKUP_FILE"
    echo
    
    # Status dos peers
    if curl -s http://localhost:5052/eth/v1/node/health > /dev/null 2>&1; then
        local peer_data=$(curl -s http://localhost:5052/eth/v1/node/peer_count)
        echo "Peers conectados: $(echo "$peer_data" | jq -r '.data.connected')"
        echo "Peers conectando: $(echo "$peer_data" | jq -r '.data.connecting')"
        echo "Total descobertos: $(echo "$peer_data" | jq -r '.data.disconnected')"
    else
        echo "Lighthouse: Não acessível"
    fi
    
    echo
    echo "Otimizações aplicadas:"
    echo "• Target peers: 25 (adequado para testnet)"
    echo "• Discovery otimizado"
    echo "• Binding em todas as interfaces"
    echo "• Subnets subscription habilitada"
    echo "• Configurações P2P otimizadas"
    echo
    echo "Próximos passos:"
    echo "• Monitorar conectividade por 24h"
    echo "• Verificar estabilidade dos peers"
    echo "• Configurar firewall se necessário"
    echo "• Considerar port forwarding"
    echo "=================================="
}

# Função principal
main() {
    echo -e "${YELLOW}⚠️ Este script irá otimizar a conectividade P2P do Lighthouse${NC}"
    echo -e "${YELLOW}   Será criado um backup do docker-compose atual${NC}"
    echo
    
    read -p "Deseja continuar? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Operação cancelada${NC}"
        exit 0
    fi
    
    echo
    check_current_status
    apply_optimizations
    check_firewall_config
    generate_bootstrap_nodes
    apply_advanced_network_config
    restart_lighthouse
    verify_improvements
    generate_optimization_report
    
    echo -e "${GREEN}✅ Otimização concluída!${NC}"
    echo -e "${YELLOW}📋 Execute ./scripts/monitor-peers-lighthouse.sh para monitorar${NC}"
    echo
}

# Executar otimização
main

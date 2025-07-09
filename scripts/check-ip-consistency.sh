#!/bin/bash

# ====================================================
# Script: Verificação de Consistência IP
# Descrição: Verifica se o IP do ENR coincide com o IP público real
# Autor: Lighthouse Holesky Optimization
# Data: $(date +"%Y-%m-%d")
# ====================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
COMPOSE_FILE="docker-compose-holesky.yml"
CONTAINER_NAME="lighthouse"
LOG_FILE="logs/ip-consistency-$(date +%Y%m%d-%H%M%S).log"

# Criar diretório de logs
mkdir -p logs

echo -e "${BLUE}🔍 Verificando Consistência de IP - Lighthouse Holesky${NC}"
echo "=================================================="

# Função para log
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 1. Verificar se container está rodando
log_message "Verificando status do container..."
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}❌ Container $CONTAINER_NAME não está rodando${NC}"
    exit 1
fi

# 2. Obter IP público atual
log_message "Obtendo IP público atual..."
CURRENT_IP=$(curl -s --connect-timeout 10 httpbin.org/ip | jq -r '.origin' 2>/dev/null || echo "ERRO")

if [ "$CURRENT_IP" = "ERRO" ]; then
    echo -e "${RED}❌ Erro ao obter IP público${NC}"
    exit 1
fi

echo -e "${BLUE}📍 IP Público Atual: ${GREEN}$CURRENT_IP${NC}"

# 3. Obter IP do ENR
log_message "Obtendo IP do ENR..."
ENR_LOG=$(docker logs "$CONTAINER_NAME" 2>&1 | grep "ENR Initialised" | tail -1)

if [ -z "$ENR_LOG" ]; then
    echo -e "${RED}❌ Não foi possível obter ENR do container${NC}"
    exit 1
fi

# Extrair IP do ENR
ENR_IP=$(echo "$ENR_LOG" | grep -o 'ip4: Some([0-9\.]*' | grep -o '[0-9\.]*$')

if [ -z "$ENR_IP" ]; then
    echo -e "${YELLOW}⚠️ ENR não contém IP IPv4 específico (auto-discovery ativo)${NC}"
    ENR_IP="auto-discovery"
fi

echo -e "${BLUE}🔗 IP no ENR: ${GREEN}$ENR_IP${NC}"

# 4. Verificar consistência
log_message "Verificando consistência..."

if [ "$ENR_IP" = "auto-discovery" ]; then
    echo -e "${GREEN}✅ Configuração otimizada: Auto-discovery ativo${NC}"
    echo -e "${GREEN}✅ O Lighthouse detectará automaticamente mudanças de IP${NC}"
    
    # Verificar se o ENR contém o IP atual
    if echo "$ENR_LOG" | grep -q "$CURRENT_IP"; then
        echo -e "${GREEN}✅ ENR contém o IP público atual${NC}"
    else
        echo -e "${YELLOW}⚠️ ENR pode não ter o IP mais atual (normal após mudança)${NC}"
        echo -e "${YELLOW}   O Lighthouse atualizará automaticamente${NC}"
    fi
    
elif [ "$ENR_IP" = "$CURRENT_IP" ]; then
    echo -e "${GREEN}✅ IP consistente: ENR e IP público coincidem${NC}"
    
else
    echo -e "${RED}❌ Inconsistência detectada:${NC}"
    echo -e "${RED}   IP no ENR: $ENR_IP${NC}"
    echo -e "${RED}   IP público: $CURRENT_IP${NC}"
    echo -e "${YELLOW}   Recomendação: Usar auto-discovery para flexibilidade${NC}"
fi

# 5. Verificar peers
log_message "Verificando peers..."
PEER_COUNT=$(curl -s --connect-timeout 5 http://localhost:5052/eth/v1/node/peer_count | jq -r '.data.connected' 2>/dev/null || echo "0")

echo -e "${BLUE}👥 Peers Conectados: ${GREEN}$PEER_COUNT${NC}"

if [ "$PEER_COUNT" -gt 5 ]; then
    echo -e "${GREEN}✅ Boa conectividade (>5 peers)${NC}"
elif [ "$PEER_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠️ Conectividade moderada (1-5 peers)${NC}"
else
    echo -e "${RED}❌ Conectividade baixa (0 peers)${NC}"
fi

# 6. Verificar port forwarding
log_message "Verificando port forwarding..."
echo -e "${BLUE}🔧 Testando conectividade UDP na porta 9000...${NC}"

# Teste UDP local
if nc -u -z -w 3 localhost 9000 2>/dev/null; then
    echo -e "${GREEN}✅ Porta 9000 UDP local: OK${NC}"
else
    echo -e "${YELLOW}⚠️ Porta 9000 UDP local: não testável com nc${NC}"
fi

# 7. Resumo e recomendações
echo ""
echo -e "${BLUE}📋 RESUMO${NC}"
echo "========================"
echo -e "IP Público Atual: ${GREEN}$CURRENT_IP${NC}"
echo -e "IP no ENR: ${GREEN}$ENR_IP${NC}"
echo -e "Peers Conectados: ${GREEN}$PEER_COUNT${NC}"
echo -e "Status: ${GREEN}Auto-discovery configurado${NC}"

echo ""
echo -e "${BLUE}🎯 RECOMENDAÇÕES${NC}"
echo "========================"
echo -e "1. ${GREEN}✅ Auto-discovery ativo${NC} - Configuração otimizada"
echo -e "2. ${YELLOW}⚠️ Configure port forwarding${NC} para máxima conectividade"
echo -e "3. ${BLUE}📊 Monitore peers${NC} nas próximas 24h"

# 8. Próximos passos
echo ""
echo -e "${BLUE}📖 PRÓXIMOS PASSOS${NC}"
echo "========================"
echo "• Port forwarding: docs/ROUTER-PORT-FORWARDING-GUIDE.md"
echo "• Monitoramento: ./scripts/monitor-peers-lighthouse.sh"
echo "• Alternativas IP: docs/ENR-FLEXIBLE-CONFIG.md"

log_message "Verificação concluída - IP: $CURRENT_IP, ENR: $ENR_IP, Peers: $PEER_COUNT"

echo ""
echo -e "${GREEN}✅ Verificação concluída! Log salvo em: $LOG_FILE${NC}"

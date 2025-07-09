#!/bin/bash

# ====================================================
# Script: Configuração DDNS para Lighthouse
# Descrição: Configura Dynamic DNS como alternativa ao IP fixo
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
BACKUP_DIR="backups/ddns-config"

echo -e "${BLUE}🌐 Configurador DDNS para Lighthouse Holesky${NC}"
echo "=============================================="

# Criar diretório de backup
mkdir -p "$BACKUP_DIR"

echo -e "${YELLOW}📋 SERVIÇOS DDNS RECOMENDADOS${NC}"
echo "==============================="
echo "1. No-IP     - https://www.noip.com/"
echo "2. DuckDNS   - https://www.duckdns.org/"
echo "3. Dynu      - https://www.dynu.com/"
echo "4. FreeDNS   - https://freedns.afraid.org/"
echo ""

echo -e "${BLUE}ℹ️ PASSOS PARA CONFIGURAR DDNS:${NC}"
echo "1. Criar conta em um serviço DDNS"
echo "2. Criar hostname (ex: meu-lighthouse.ddns.net)"
echo "3. Configurar cliente DDNS no roteador/computador"
echo "4. Executar este script para aplicar no compose"
echo ""

# Solicitar hostname DDNS
echo -e "${BLUE}🔗 Digite seu hostname DDNS:${NC}"
read -p "Hostname (ex: meu-lighthouse.ddns.net): " DDNS_HOSTNAME

if [ -z "$DDNS_HOSTNAME" ]; then
    echo -e "${RED}❌ Hostname não pode estar vazio${NC}"
    exit 1
fi

# Verificar se hostname é válido
if ! echo "$DDNS_HOSTNAME" | grep -q "\."; then
    echo -e "${RED}❌ Hostname deve conter domínio (ex: host.ddns.net)${NC}"
    exit 1
fi

echo -e "${BLUE}🔍 Testando resolução DNS...${NC}"
if nslookup "$DDNS_HOSTNAME" >/dev/null 2>&1; then
    RESOLVED_IP=$(nslookup "$DDNS_HOSTNAME" | grep -A1 "Name:" | grep "Address:" | head -1 | awk '{print $2}')
    echo -e "${GREEN}✅ Hostname resolve para: $RESOLVED_IP${NC}"
else
    echo -e "${YELLOW}⚠️ Hostname não resolve ainda (configure o serviço DDNS primeiro)${NC}"
    echo -e "${YELLOW}   Continuando com a configuração...${NC}"
fi

# Backup do compose atual
echo -e "${BLUE}💾 Criando backup...${NC}"
BACKUP_FILE="$BACKUP_DIR/docker-compose-holesky-$(date +%Y%m%d-%H%M%S).yml"
cp "$COMPOSE_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✅ Backup criado: $BACKUP_FILE${NC}"

# Verificar se já existe configuração ENR
if grep -q "enr-address" "$COMPOSE_FILE"; then
    echo -e "${YELLOW}⚠️ Configuração ENR existente encontrada${NC}"
    echo -e "${YELLOW}   Será substituída pelo hostname DDNS${NC}"
    
    # Substituir enr-address existente
    sed -i.bak "s/--enr-address=[^[:space:]]*/--enr-address=$DDNS_HOSTNAME/" "$COMPOSE_FILE"
    
else
    echo -e "${BLUE}➕ Adicionando configuração DDNS...${NC}"
    
    # Adicionar enr-address após enr-udp-port
    sed -i.bak "/--enr-udp-port=9000/a\\
      --enr-address=$DDNS_HOSTNAME\\
      --disable-enr-auto-update" "$COMPOSE_FILE"
fi

# Verificar se foi aplicado
if grep -q "enr-address=$DDNS_HOSTNAME" "$COMPOSE_FILE"; then
    echo -e "${GREEN}✅ Configuração DDNS aplicada com sucesso${NC}"
else
    echo -e "${RED}❌ Erro ao aplicar configuração DDNS${NC}"
    echo -e "${YELLOW}   Restaurando backup...${NC}"
    cp "$BACKUP_FILE" "$COMPOSE_FILE"
    exit 1
fi

# Mostrar configuração aplicada
echo -e "${BLUE}📝 Configuração aplicada:${NC}"
echo "========================="
grep -A2 -B2 "enr-address=$DDNS_HOSTNAME" "$COMPOSE_FILE"
echo ""

# Guia de reinicialização
echo -e "${BLUE}🔄 PRÓXIMOS PASSOS${NC}"
echo "=================="
echo "1. Reiniciar Lighthouse:"
echo "   docker-compose -f docker-compose-holesky.yml restart lighthouse"
echo ""
echo "2. Verificar logs:"
echo "   docker logs lighthouse | grep 'ENR Initialised'"
echo ""
echo "3. Monitorar peers:"
echo "   curl -s http://localhost:5052/eth/v1/node/peer_count | jq"
echo ""

# Configuração do cliente DDNS
echo -e "${BLUE}🔧 CONFIGURAÇÃO DO CLIENTE DDNS${NC}"
echo "==============================="
echo "• Configure o cliente DDNS no seu roteador ou computador"
echo "• O cliente deve atualizar o IP automaticamente"
echo "• Teste a resolução DNS periodicamente"
echo ""

# Rollback
echo -e "${BLUE}🔙 ROLLBACK (se necessário)${NC}"
echo "========================="
echo "Para voltar ao auto-discovery:"
echo "1. Remover --enr-address e --disable-enr-auto-update"
echo "2. Ou restaurar backup: cp $BACKUP_FILE $COMPOSE_FILE"
echo "3. Reiniciar Lighthouse"
echo ""

echo -e "${YELLOW}⚠️ IMPORTANTE:${NC}"
echo "• Configure o cliente DDNS ANTES de reiniciar o Lighthouse"
echo "• Verifique se o hostname resolve para seu IP público"
echo "• Monitore a estabilidade dos peers por 24h"
echo ""

echo -e "${GREEN}✅ Configuração DDNS concluída!${NC}"
echo -e "${GREEN}   Hostname: $DDNS_HOSTNAME${NC}"
echo -e "${GREEN}   Backup: $BACKUP_FILE${NC}"

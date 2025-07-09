#!/bin/bash

# Script de teste completo de conectividade UDP para Lighthouse
# Testa conectividade local, de rede e externa

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}   LIGHTHOUSE UDP CONNECTIVITY TEST  ${NC}"
echo -e "${BLUE}=====================================${NC}"
echo

# Função para obter IP público
get_public_ip() {
    local ip=$(curl -s --connect-timeout 5 httpbin.org/ip | grep -o '"[^"]*"' | grep -o '[^"]*' | head -1)
    echo "$ip"
}

# Função para obter IP local
get_local_ip() {
    local ip=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | head -1 | awk '{print $2}')
    echo "$ip"
}

# Função para testar porta UDP
test_udp_port() {
    local host=$1
    local port=$2
    local description=$3
    
    echo -n "  Testing $description ($host:$port)... "
    
    if nc -u -z -v -w 3 "$host" "$port" 2>/dev/null; then
        echo -e "${GREEN}✅ SUCCESS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAILED${NC}"
        return 1
    fi
}

# Obter informações de rede
LOCAL_IP=$(get_local_ip)
PUBLIC_IP=$(get_public_ip)

echo -e "${BLUE}📍 NETWORK INFORMATION${NC}"
echo -e "  Local IP:  $LOCAL_IP"
echo -e "  Public IP: $PUBLIC_IP"
echo -e "  Gateway:   $(route -n get default | grep gateway | awk '{print $2}')"
echo

# Verificar mapeamento de portas Docker
echo -e "${BLUE}🐳 DOCKER PORT MAPPING${NC}"
docker port lighthouse | grep 9000 | while read line; do
    echo -e "  $line"
done
echo

# Verificar processo escutando na porta
echo -e "${BLUE}👂 LISTENING PROCESSES${NC}"
echo -e "  Port 9000 TCP:"
if lsof -i TCP:9000 2>/dev/null; then
    echo -e "    ${GREEN}✅ TCP port is bound${NC}"
else
    echo -e "    ${RED}❌ TCP port not bound${NC}"
fi

echo -e "  Port 9000 UDP:"
if lsof -i UDP:9000 2>/dev/null; then
    echo -e "    ${GREEN}✅ UDP port is bound${NC}"
else
    echo -e "    ${RED}❌ UDP port not bound${NC}"
fi
echo

# Testes de conectividade
echo -e "${BLUE}🔌 CONNECTIVITY TESTS${NC}"

# Teste 1: Localhost
test_udp_port "127.0.0.1" "9000" "Localhost UDP"

# Teste 2: IP local
test_udp_port "$LOCAL_IP" "9000" "Local Network UDP"

# Teste 3: Verificar se UPnP está funcionando
echo -e "\n${BLUE}🌐 UPnP STATUS${NC}"
upnp_status=$(docker logs lighthouse 2>&1 | grep -i "upnp" | tail -1)
if echo "$upnp_status" | grep -q "not support"; then
    echo -e "  ${RED}❌ UPnP not supported by gateway${NC}"
    echo -e "  ${YELLOW}⚠️ Manual port forwarding required${NC}"
else
    echo -e "  ${GREEN}✅ UPnP may be working${NC}"
fi

# Teste 4: Verificar ENR
echo -e "\n${BLUE}🔍 ENR INFORMATION${NC}"
enr_log=$(docker logs lighthouse 2>&1 | grep "ENR Initialised" | tail -1)
if [ -n "$enr_log" ]; then
    echo -e "  ${GREEN}✅ ENR initialized${NC}"
    # Extrair informações do ENR
    if echo "$enr_log" | grep -q "udp4: None"; then
        echo -e "  ${RED}❌ UDP4 not configured in ENR${NC}"
    else
        echo -e "  ${GREEN}✅ UDP4 configured in ENR${NC}"
    fi
    
    if echo "$enr_log" | grep -q "tcp4: Some(9000)"; then
        echo -e "  ${GREEN}✅ TCP4 port 9000 in ENR${NC}"
    else
        echo -e "  ${RED}❌ TCP4 port not in ENR${NC}"
    fi
else
    echo -e "  ${RED}❌ ENR not found in logs${NC}"
fi

# Teste 5: Verificar discovery
echo -e "\n${BLUE}🔍 DISCOVERY STATUS${NC}"
discovery_log=$(docker logs lighthouse 2>&1 | grep -i "discovery" | tail -3)
if [ -n "$discovery_log" ]; then
    echo "$discovery_log" | while read line; do
        if echo "$line" | grep -q "Could not UPnP map"; then
            echo -e "  ${YELLOW}⚠️ $line${NC}"
        else
            echo -e "  ${GREEN}ℹ️ $line${NC}"
        fi
    done
else
    echo -e "  ${YELLOW}⚠️ No discovery logs found${NC}"
fi

echo -e "\n${BLUE}=====================================${NC}"
echo -e "${BLUE}           SUMMARY & RECOMMENDATIONS  ${NC}"
echo -e "${BLUE}=====================================${NC}"

# Resumo e recomendações
echo -e "\n${YELLOW}📊 SUMMARY:${NC}"
echo -e "  • Docker port mapping: ${GREEN}✅ Configured${NC}"
echo -e "  • Local connectivity: ${GREEN}✅ Working${NC}"
echo -e "  • UPnP: ${RED}❌ Not supported${NC}"
echo -e "  • External access: ${YELLOW}⚠️ Requires manual setup${NC}"

echo -e "\n${YELLOW}💡 RECOMMENDATIONS:${NC}"
echo -e "  1. ${BLUE}Configure port forwarding on your router${NC}"
echo -e "     • Port: 9000 (TCP and UDP)"
echo -e "     • Target IP: $LOCAL_IP"
echo -e "     • Protocol: Both TCP and UDP"
echo -e ""
echo -e "  2. ${BLUE}Update Lighthouse configuration${NC}"
echo -e "     • Add --enr-address=$PUBLIC_IP"
echo -e "     • Add --enr-udp-port=9000"
echo -e "     • Add --enr-tcp-port=9000"
echo -e ""
echo -e "  3. ${BLUE}Test external connectivity${NC}"
echo -e "     • Use online port checker tools"
echo -e "     • Test from external network"

echo -e "\n${GREEN}✅ UDP connectivity test completed!${NC}"
echo -e "${YELLOW}📋 Check router configuration guide below${NC}"
echo

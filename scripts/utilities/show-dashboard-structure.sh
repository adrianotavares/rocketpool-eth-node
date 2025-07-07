#!/bin/bash

# Script para mostrar a nova estrutura de dashboards organizados por pastas

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Nova Estrutura de Dashboards Organizados${NC}"
echo "=============================================="
echo

echo -e "${YELLOW}Estrutura de Pastas:${NC}"
echo "grafana/provisioning/dashboards/"
echo "├── default.yml (configuração com foldersFromFilesStructure: true)"
echo "├── Ethereum/ (pasta para dashboards da mainnet)"
echo "│   ├── ethereum.json (dashboard geral Ethereum)"
echo "│   └── geth.json (dashboard Geth mainnet)"
echo "└── Holesky/ (pasta para dashboards da testnet)"
echo "    ├── geth-holesky.json (dashboard Geth Holesky)"
echo "    └── lighthouse-holesky.json (dashboard Lighthouse Holesky)"
echo

echo -e "${YELLOW}Resultado no Grafana:${NC}"
echo "Pasta 'Ethereum':"
echo "  - Ethereum Node Monitoring"
echo "  - Geth Server Monitoring"
echo
echo "Pasta 'Holesky':"
echo "  - Geth Holesky Testnet Monitoring"
echo "  - Lighthouse Holesky Testnet Monitoring"
echo

echo -e "${YELLOW}Configuração (default.yml):${NC}"
echo "- foldersFromFilesStructure: true"
echo "- Criação automática de pastas baseada na estrutura de diretórios"
echo "- Organização limpa e intuitiva"
echo

echo -e "${GREEN}Vantagens da Nova Estrutura:${NC}"
echo "- Separação clara entre mainnet e testnet"
echo "- Fácil navegação no Grafana"
echo "- Organização escalável para futuras testnets"
echo "- Manutenção simplificada"
echo

echo -e "${BLUE}Acesso: http://localhost:3000 (admin/admin)${NC}"
echo -e "${BLUE}Navegação: Home → Dashboards → [Ethereum/Holesky]${NC}"

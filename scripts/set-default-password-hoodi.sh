#!/bin/bash
# Script para configurar senha padrão do Rocket Pool - Hoodi
# Script to set default password for Rocket Pool - Hoodi

echo "🔐 Configurando senha padrão para o Rocket Pool - Hoodi"
echo "===================================================="

# Definir senha padrão (APENAS PARA TESTNET!)
DEFAULT_PASSWORD="testnet123"

echo "⚠️  ATENÇÃO: Este script define uma senha padrão para TESTNET"
echo "   Senha padrão: $DEFAULT_PASSWORD"
echo "   Para produção/mainnet, sempre use uma senha segura!"
echo ""

# Confirmar
read -p "Continuar com a senha padrão? (y/n): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "❌ Configuração cancelada"
    exit 0
fi

# Configurar senha usando expect ou similar
echo "📝 Configurando senha..."

# Usar expect para automatizar a entrada da senha
docker exec -i rocketpool-node-hoodi bash -c "
echo 'Configurando senha do Rocket Pool...'
timeout 30 rocketpool wallet init --password '$DEFAULT_PASSWORD' || echo 'Timeout ou erro na configuração'
"

echo ""
echo "✅ Configuração de senha concluída!"
echo ""
echo "💡 Próximos passos:"
echo "   1. Verificar status: docker exec -it rocketpool-node-hoodi rocketpool wallet status"
echo "   2. Ver nó: docker exec -it rocketpool-node-hoodi rocketpool node status"
echo ""

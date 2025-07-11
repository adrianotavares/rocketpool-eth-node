#!/bin/bash
# Script para parar a testnet Hoodi
# Stop script for Hoodi testnet

set -e

echo "⏹️  Parando Rocket Pool Node - Testnet Hoodi"
echo "============================================="

# Configurar diretório
cd "$(dirname "$0")/.."

# Verificar se o arquivo existe
if [ ! -f "docker-compose-hoodi.yml" ]; then
    echo "❌ Erro: docker-compose-hoodi.yml não encontrado!"
    exit 1
fi

# Parar os serviços
echo "� Parando containers Docker..."
docker compose -f docker-compose-hoodi.yml down

# Verificar se ainda há containers rodando
RUNNING_CONTAINERS=$(docker ps --filter name=hoodi --format "table {{.Names}}" | grep -v NAMES || true)

if [ -n "$RUNNING_CONTAINERS" ]; then
    echo "⚠️  Ainda há containers relacionados à Hoodi rodando:"
    echo "$RUNNING_CONTAINERS"
    echo ""
    echo "Para forçar a parada, execute:"
    echo "docker stop \$(docker ps --filter name=hoodi -q)"
else
    echo "✅ Todos os containers da Hoodi foram parados com sucesso!"
fi

# Mostrar espaço usado (se .env.hoodi existir)
if [ -f ".env.hoodi" ]; then
    echo ""
    echo "� Informações de armazenamento:"
    
    # Carregar variáveis de ambiente
    set -a
    source .env.hoodi
    set +a
    
    if [ -d "$SSD_MOUNT_PATH/ethereum-data-hoodi" ]; then
        echo "   📁 Dados da Hoodi estão em: $SSD_MOUNT_PATH/ethereum-data-hoodi/"
        echo "   💾 Espaço usado:"
        du -sh "$SSD_MOUNT_PATH/ethereum-data-hoodi" 2>/dev/null || echo "   (Não foi possível calcular o tamanho)"
    fi
fi

echo ""
echo "🔧 Comandos úteis:"
echo "   - Iniciar novamente: ./scripts/start-hoodi.sh"
echo "   - Ver logs: docker compose -f docker-compose-hoodi.yml logs"
echo "   - Remover tudo: docker compose -f docker-compose-hoodi.yml down -v"
echo ""

#!/bin/bash
# Script para limpar completamente os dados da testnet Hoodi
# Clean script for Hoodi testnet - USE WITH CAUTION!

set -e

echo "🗑️  Script de Limpeza - Testnet Hoodi"
echo "===================================="
echo ""
echo "⚠️  ATENÇÃO: Este script irá remover TODOS os dados da Hoodi!"
echo "   - Dados do blockchain (execution e consensus)"
echo "   - Configurações do Rocket Pool"
echo "   - Dados de monitoramento (Prometheus, Grafana)"
echo "   - Containers Docker"
echo ""

# Confirmar ação
read -p "Tem certeza que deseja continuar? Digite 'sim' para confirmar: " confirm

if [ "$confirm" != "sim" ]; then
    echo "❌ Operação cancelada."
    exit 0
fi

# Configurar diretório
cd "$(dirname "$0")/.."

# Parar containers primeiro
echo "🛑 Parando containers..."
if [ -f "docker-compose-hoodi.yml" ]; then
    docker compose -f docker-compose-hoodi.yml down -v --remove-orphans
else
    echo "   docker-compose-hoodi.yml não encontrado, continuando..."
fi

# Remover containers órfãos especificamente da Hoodi
echo "🧹 Removendo containers órfãos da Hoodi..."
docker ps -a --filter name=hoodi --format "{{.ID}}" | xargs -r docker rm -f || true

# Carregar variáveis de ambiente para encontrar os diretórios
if [ -f ".env.hoodi" ]; then
    echo "📋 Carregando configurações..."
    set -a
    source .env.hoodi
    set +a
    
    # Remover dados do SSD
    if [ -d "$SSD_MOUNT_PATH/ethereum-data-hoodi" ]; then
        echo "💾 Removendo dados do SSD: $SSD_MOUNT_PATH/ethereum-data-hoodi/"
        echo "   Isso inclui:"
        echo "   - Blockchain data (execution e consensus)"
        echo "   - Configurações do Rocket Pool (user-settings.yml)"
        echo "   - JWT secrets"
        echo "   - Dados de monitoramento"
        echo ""
        read -p "Confirma a remoção de TODOS os dados? Digite 'confirmo': " final_confirm
        
        if [ "$final_confirm" = "confirmo" ]; then
            rm -rf "$SSD_MOUNT_PATH/ethereum-data-hoodi"
            echo "   ✅ Dados do SSD removidos"
        else
            echo "   ❌ Remoção cancelada"
            exit 0
        fi
    else
        echo "   📁 Diretório do SSD não encontrado: $SSD_MOUNT_PATH/ethereum-data-hoodi"
    fi
else
    echo "⚠️  Arquivo .env.hoodi não encontrado, removendo diretórios locais..."
fi

# Remover diretórios locais (caso existam)
echo "📁 Removendo diretórios locais..."
for dir in rocketpool-hoodi execution-data-hoodi consensus-data-hoodi prometheus-data-hoodi grafana-data-hoodi alertmanager-data-hoodi; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        echo "   ✅ Removido: $dir"
    fi
done

# Remover volumes Docker órfãos
echo "🐳 Removendo volumes Docker órfãos..."
docker volume ls --filter name=hoodi --format "{{.Name}}" | xargs -r docker volume rm || true

# Remover redes Docker órfãs
echo "🌐 Removendo redes Docker órfãs..."
docker network ls --filter name=hoodi --format "{{.Name}}" | xargs -r docker network rm || true

# Limpeza final do Docker
echo "🧽 Limpeza final do Docker..."
docker system prune -f

echo ""
echo "✅ Limpeza da Testnet Hoodi concluída!"
echo ""
echo "📊 Resumo do que foi removido:"
echo "   - Containers Docker da Hoodi"
echo "   - Volumes e redes Docker"
echo "   - Dados do blockchain no SSD"
echo "   - Dados de monitoramento"
echo "   - Configurações do Rocket Pool"
echo ""
echo "💡 Para reinstalar a Hoodi:"
echo "   ./scripts/start-hoodi.sh"
echo ""
echo "⏱️  Tempo de ressincronização estimado: 1-2 horas"
echo ""

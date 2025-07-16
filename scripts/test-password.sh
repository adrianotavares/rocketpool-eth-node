#!/bin/bash
# Script de teste para configurar senha automaticamente

cd "$(dirname "$0")/.."

# Verificar se os containers estão rodando
if ! docker ps --filter name=rocketpool-node-hoodi --format "{{.Names}}" | grep -q rocketpool-node-hoodi; then
    echo "❌ Erro: Container rocketpool-node-hoodi não está rodando!"
    echo "   Execute primeiro: ./scripts/start-hoodi.sh"
    exit 1
fi

# Função para executar comandos no container
rp_exec() {
    docker exec -it rocketpool-node-hoodi rocketpool api "$@"
}

echo "🔧 Testando configuração de senha..."

# Definir senha de teste
test_password="HoodiTestPassword2025!"

# Verificar status atual
echo "📋 Status atual da wallet:"
rp_exec wallet status

echo ""
echo "🔐 Configurando senha de teste: $test_password"
rp_exec wallet set-password "$test_password"

echo ""
echo "📋 Status após configurar senha:"
rp_exec wallet status

echo ""
echo "✅ Teste concluído!"

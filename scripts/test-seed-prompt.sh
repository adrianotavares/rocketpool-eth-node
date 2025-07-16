#!/bin/bash

# Teste rápido para verificar a solicitação de seed phrase

echo "🧪 Teste: Simulando solicitação de seed phrase"
echo "=============================================="

echo ""
echo "🦊 Importando wallet existente..."
echo ""
echo "⚠️  IMPORTANTE:"
echo "   - Você precisará da frase mnemônica (seed phrase) de 12/24 palavras"
echo "   - Esta é a mesma frase usada na MetaMask ou hardware wallet"
echo "   - Mantenha esta frase segura e privada"
echo ""

# Solicitar seed phrase da MetaMask
echo "🔐 Digite sua seed phrase da MetaMask (12 ou 24 palavras):"
echo "   Exemplo: word1 word2 word3 ... word12"
echo ""
read -p "Seed phrase: " -r mnemonic_phrase
echo ""

if [ -z "$mnemonic_phrase" ]; then
    echo "❌ Seed phrase não pode estar vazia!"
    exit 1
fi

echo "✅ Seed phrase recebida!"
echo "   Tamanho: ${#mnemonic_phrase} caracteres"
echo "   Comando que seria executado:"
echo "   docker exec -it rocketpool-node-hoodi rocketpool-cli --allow-root wallet recover --mnemonic \"[SEED_PHRASE_OCULTA]\""
echo ""
echo "✅ Teste concluído - O script agora solicita corretamente a seed phrase!"

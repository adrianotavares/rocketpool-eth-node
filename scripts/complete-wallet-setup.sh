#!/bin/bash

echo "=== ROCKET POOL WALLET SETUP COMPLETO ==="
echo ""

echo "1. Verificando status da wallet..."
docker exec rocketpool-node-hoodi rocketpool api wallet status

echo ""
echo "2. Recuperando wallet com seed phrase..."
docker exec rocketpool-node-hoodi rocketpool api wallet recover "donate claw crunch guess key divorce olympic aim eyebrow win extra detect impact skull stone tube deer right novel maple aunt sphere dilemma deposit"

echo ""
echo "3. Verificando status do nó..."
docker exec rocketpool-node-hoodi rocketpool api node status

echo ""
echo "4. Verificando registro do nó..."
docker exec rocketpool-node-hoodi rocketpool api node can-register

echo ""
echo "=== INFORMAÇÕES IMPORTANTES ==="
echo "Endereço da Wallet: 0x785f318a232390af7fb37c97f454e9e665048bb3"
echo "Seed Phrase: donate claw crunch guess key divorce olympic aim eyebrow win extra detect impact skull stone tube deer right novel maple aunt sphere dilemma deposit"
echo ""
echo "PRÓXIMOS PASSOS:"
echo "1. Enviar ETH para o endereço da wallet (mínimo 2.4 ETH)"
echo "2. Comprar RPL tokens (mínimo ~2.4 ETH em RPL)"
echo "3. Registrar o nó: docker exec rocketpool-node-hoodi rocketpool api node register"
echo "4. Fazer stake de RPL: docker exec rocketpool-node-hoodi rocketpool api node stake-rpl"
echo "5. Criar minipool: docker exec rocketpool-node-hoodi rocketpool api node deposit"

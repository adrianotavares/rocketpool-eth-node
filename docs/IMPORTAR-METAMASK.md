# 🦊 Importar Wallet MetaMask para Rocket Pool

## **Objetivo**

Importar sua wallet existente da MetaMask para o Rocket Pool Hoodi, permitindo usar a mesma seed phrase e endereços.

## ⚠️ **IMPORTANTE - Segurança**

### **O que você precisa:**

- ✅ **Seed Phrase da MetaMask**: 12 ou 24 palavras
- ✅ **Ambiente seguro**: Certifique-se de que ninguém pode ver sua tela
- ✅ **Backup seguro**: Tenha sua seed phrase anotada em local seguro

### **Riscos e Cuidados:**

- 🔐 **NUNCA compartilhe** sua seed phrase com ninguém
- 🔐 **NUNCA digite** em sites ou aplicativos não confiáveis
- 🔐 **SEMPRE verifique** se está no ambiente correto (seu servidor)
- 🔐 **BACKUP obrigatório**: Tenha múltiplas cópias seguras da seed phrase

## **Como Importar**

### **Passo 1: Preparação**

```bash
# 1. Iniciar a infraestrutura Hoodi
./scripts/start-hoodi.sh

# 2. Aguardar containers estarem rodando
docker ps --filter name=hoodi
```

### **Passo 2: Executar Setup**

```bash
# Executar setup do Rocket Pool
./scripts/setup-rocketpool-hoodi.sh
```

### **Passo 3: Configurar Senha**

- O script solicitará uma senha para proteger a wallet no servidor
- Esta senha é **diferente** da senha da MetaMask
- Use uma senha forte (mínimo 8 caracteres)

### **Passo 4: Escolher Importação**

Quando aparecer as opções:

```text
Escolha uma opção:
a) Importar wallet existente (MetaMask/hardware wallet)  ← ESCOLHA ESTA
b) Criar nova wallet
```

### **Passo 5: Inserir Seed Phrase**

- O Rocket Pool solicitará sua seed phrase
- Digite as 12 ou 24 palavras **exatamente** como estão na MetaMask
- Palavras separadas por espaço
- Tudo em minúsculas
- Sem vírgulas ou pontos

Exemplo de formato:

```text
word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12
```

## **Verificação**

### **Confirmar Endereço Importado**

```bash
# Verificar status da wallet
docker exec -it rocketpool-node-hoodi rocketpool api wallet status

# Verificar endereço do nó
docker exec -it rocketpool-node-hoodi rocketpool api node status
```

### **Comparar com MetaMask**

- O endereço mostrado deve ser **exatamente igual** ao da MetaMask
- Se for diferente, algo deu errado na importação

## 💰 **Gerenciamento de Fundos**

### **Endereços da Wallet Importada**

- **Endereço principal**: Mesmo da MetaMask (Account 1)
- **Endereços derivados**: Rocket Pool pode usar outros índices
- **Compatibilidade**: Total com MetaMask e outras wallets HD

### **Transferir Fundos para Hoodi**

Você precisará de ETH de teste da Hoodi:

```bash
# Verificar endereço do nó
docker exec -it rocketpool-node-hoodi rocketpool api wallet status

# Use este endereço para receber ETH da Hoodi testnet
```

### **Faucets da Hoodi (se disponíveis)**

- Procure por faucets da testnet Hoodi
- Use o endereço mostrado no comando acima
- Ou transfira de outras fontes de ETH de teste

## **Derivation Paths**

### **MetaMask Padrão**

- **Path**: `m/44'/60'/0'/0/0`
- **Compatível**: ✅ Rocket Pool usa o mesmo padrão
- **Resultado**: Mesmo endereço da MetaMask

### **Se usar Ledger Live**

```bash
# Se sua MetaMask usa Ledger com path diferente
docker exec -it rocketpool-node-hoodi rocketpool api wallet recover --derivation-path "ledgerLive"
```

### **Se usar MyEtherWallet**

```bash
# Se usa path do MEW
docker exec -it rocketpool-node-hoodi rocketpool api wallet recover --derivation-path "mew"
```

## **Validação Final**

### **Checklist de Sucesso**

- ✅ Senha configurada: `"passwordSet":true`
- ✅ Wallet inicializada: `"walletInitialized":true`
- ✅ Endereço correto: Igual ao da MetaMask
- ✅ Logs limpos: Sem erros de configuração

### **Comandos de Verificação**

```bash
# Status completo
docker exec -it rocketpool-node-hoodi rocketpool api wallet status

# Status do nó
docker exec -it rocketpool-node-hoodi rocketpool api node status

# Verificar logs
docker logs rocketpool-node-hoodi --tail 20
```

## **Troubleshooting**

### **Endereço Diferente da MetaMask**

Possíveis causas:

- Seed phrase digitada incorretamente
- Derivation path diferente
- Índice de conta diferente

Soluções:

```bash
# Tentar recuperação com path específico
docker exec -it rocketpool-node-hoodi rocketpool api wallet search-and-recover

# Ou especificar derivation path
./scripts/setup-rocketpool-hoodi.sh  # Execute novamente
```

### **Erro na Seed Phrase**

Sintomas:

- Erro "invalid mnemonic"
- Endereço incorreto

Soluções:

- Verificar cada palavra da seed phrase
- Confirmar ordem correta
- Verificar se não há caracteres especiais
- Tentar novamente com cuidado extra

### **Problema de Permissões**

```bash
# Verificar containers
docker ps --filter name=hoodi

# Reiniciar se necessário
./scripts/stop-hoodi.sh
./scripts/start-hoodi.sh
```

## **Próximos Passos**

Após importar com sucesso:

1. **Obter ETH de teste**: Para a testnet Hoodi
2. **Registrar nó**: `./scripts/setup-rocketpool-hoodi.sh` (continuar)
3. **Configurar comissão**: Durante o setup
4. **Monitorar sincronização**: Via Grafana
5. **Backup da configuração**: Especialmente JWT secrets

## **Resumo dos Comandos**

```bash
# Fluxo completo para importar MetaMask
./scripts/start-hoodi.sh                    # Iniciar containers
./scripts/setup-rocketpool-hoodi.sh         # Setup + importar wallet
# Escolher opção "a" (importar)
# Inserir seed phrase da MetaMask
# Confirmar endereço igual ao da MetaMask
```

---

**✅ Sua wallet MetaMask estará integrada ao Rocket Pool Hoodi!** 🦊🚀

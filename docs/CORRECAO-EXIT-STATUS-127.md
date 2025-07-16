# Correções Aplicadas - Erro "exit status 127"

## **Problema Identificado**

O erro "Could not get client status: exit status 127" ocorria porque o comando `wallet recover` tentava verificar o status dos clientes (Execution e Consensus) antes deles estarem completamente sincronizados e prontos.

## **Causa Raiz**

Segundo a documentação do Rocket Pool, o comando `wallet recover` requer:

1. **Execution Client (Geth)** sincronizado e responsivo
2. **Consensus Client (Lighthouse)** sincronizado e responsivo
3. **Ambos clientes** devem estar prontos para responder às APIs

## **Soluções Implementadas**

### **1. Verificação Prévia dos Clientes**

- Adicionada verificação automática do status dos clientes ANTES de tentar configurar a wallet
- Loop de verificação com 30 tentativas e intervalos de 10 segundos
- Validação via API `rp_exec node sync` para confirmar que os clientes estão respondendo

### **2. Reorganização do Fluxo**

- **Etapa 1**: Configuração de senha
- **Etapa 2**: Verificação inicial da wallet existente
- **Etapa 3**: **NOVA** - Verificação dos clientes (CRÍTICA)
- **Etapa 4**: Configuração da wallet (com seed phrase)
- **Etapa 5**: Verificação final de sincronização
- **Etapa 6**: Registro do nó
- **Etapa 7**: Configuração de comissão

### **3. Tratamento de Erros Melhorado**

- Mensagens claras quando clientes não estão prontos
- Sugestões de troubleshooting com comandos de logs
- Validação do resultado dos comandos de wallet

### **4. Solicitação Correta da Seed Phrase**

- Prompt específico para MetaMask seed phrase (12/24 palavras)
- Validação de entrada não vazia
- Comando correto: `rp_cli wallet recover --mnemonic "$mnemonic_phrase"`

## **Como Testar**

```bash
# 1. Parar e reiniciar containers
./scripts/stop-hoodi.sh
./scripts/start-hoodi.sh

# 2. Aguardar alguns minutos para inicialização

# 3. Executar setup corrigido
./scripts/setup-rocketpool-hoodi.sh
```

## **Fluxo Corrigido**

1. ✅ **Verificação de containers rodando**
2. ✅ **Configuração de senha** (automática via JSON API)
3. ✅ **Verificação prévia de wallet**
4. ✅ **VERIFICAÇÃO DOS CLIENTES** ← **NOVA ETAPA CRÍTICA**
5. ✅ **Configuração de wallet** (com seed phrase da MetaMask)
6. ✅ **Verificação final de sincronização**
7. ✅ **Registro do nó**
8. ✅ **Configuração de comissão**

## **Benefícios**

- ❌ **Elimina erro "exit status 127"**
- ✅ **Garante que clientes estão prontos**
- ✅ **Solicita corretamente a seed phrase**
- ✅ **Fluxo robusto com tratamento de erros**
- ✅ **Mensagens informativas para o usuário**

---

🎯 A causa raiz foi identificada e corrigida: o script agora verifica se os clientes estão prontos ANTES de tentar configurar a wallet!

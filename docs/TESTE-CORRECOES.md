# Guia de Teste - Correções Aplicadas

## **O que foi corrigido**

✅ Script `setup-rocketpool-hoodi.sh` corrigido para resolver:

- **Erro "exit status 127"** durante import da wallet
- **Seed phrase não solicitada** da MetaMask
- **Verificação prévia dos clientes** antes de configurar wallet

## **Como testar as correções**

### **1. Parar e reiniciar o ambiente**

```bash
cd /Users/adrianotavares/dev/rocketpool-eth-node

# Parar containers
./scripts/stop-hoodi.sh

# Reiniciar
./scripts/start-hoodi.sh
```

### **2. Aguardar inicialização**

Aguarde **2-3 minutos** para que os containers inicializem completamente.

### **3. Executar o setup corrigido**

```bash
./scripts/setup-rocketpool-hoodi.sh
```

## **O que esperar**

### **✅ Fluxo correto:**

1. **Verificação de containers** - Confirma que estão rodando
2. **Configuração de senha** - Automática (baseada em .env)
3. **Verificação de wallet** - Checa se já existe
4. **🔥 NOVA ETAPA - Verificação dos clientes** - Aguarda sincronização
5. **Solicitação da seed phrase** - Prompt para 12/24 palavras da MetaMask
6. **Configuração da wallet** - Import da seed phrase
7. **Verificação final** - Confirma configuração
8. **Registro do nó** - Registra na testnet Holesky
9. **Configuração de comissão** - Define taxa padrão

### **📝 Mensagens esperadas:**

```text
🔍 Verificando status dos clientes Rocket Pool...
⏳ Aguardando clientes ficarem prontos... (tentativa 1/30)
✅ Clientes estão prontos!

📝 Digite a seed phrase da sua wallet MetaMask (12 ou 24 palavras):
```

## **Se algo der errado**

### **Clientes não ficam prontos (após 30 tentativas):**

```bash
# Verificar logs dos clientes
docker logs rocketpool_eth1_1
docker logs rocketpool_eth2_1

# Verificar sincronização
docker exec rocketpool_rocketpool_1 rocketpool node sync
```

### **Ainda receber "exit status 127":**

1. Verificar se containers estão rodando:

```bash
docker ps
```

   Verificar conectividade:

```bash
docker exec rocketpool_rocketpool_1 rocketpool node status
```

## **Arquivos modificados**

- ✅ `scripts/setup-rocketpool-hoodi.sh` - Script principal corrigido
- ✅ `docs/CORRECAO-EXIT-STATUS-127.md` - Documentação das correções
- ✅ `docs/TESTE-CORRECOES.md` - Este guia de teste

## **Próximos passos após teste bem-sucedido**

1. **Monitorar sincronização** com Grafana
2. **Verificar métricas** dos dashboards
3. **Acompanhar validação** na rede Holesky

---

🎯 As correções foram aplicadas com base na pesquisa da documentação oficial do Rocket Pool. O erro ocorria porque tentávamos configurar a wallet antes dos clientes estarem prontos!

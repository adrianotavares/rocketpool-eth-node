# Configuração do Rocket Pool para Testnet Holesky

Este guia explica como configurar o nó Rocket Pool para a testnet Holesky, que é uma excelente prática antes de ir para mainnet, pois permite testar tudo sem riscos financeiros.

## Por que usar Testnet?

- **Sem riscos financeiros**: Use ETH de teste gratuito
- **Aprendizado seguro**: Experimente sem consequências reais
- **Validação de setup**: Teste hardware e configurações
- **Sincronização rápida**: ~1-2 horas vs 6-12 horas na mainnet
- **Menor uso de recursos**: ~200GB vs 1TB+ na mainnet

## 1. Alterações no Docker Compose

Para configurar na testnet, você precisaria fazer as seguintes mudanças no `docker-compose.ssd.yml`:

### Execution Client (Geth)

```yaml
services:
  execution-client:
    # ...configurações existentes...
    command: >
      --holesky                        # ⚠️ Muda de --mainnet para --holesky
      --http
      --http.addr=0.0.0.0
      --http.port=8545
      --http.api=eth,net,web3,engine,admin
      --http.corsdomain="*"
      --http.vhosts="*"
      --authrpc.addr=0.0.0.0
      --authrpc.port=8551
      --authrpc.vhosts="*"
      --authrpc.jwtsecret=/root/.ethereum/geth/jwtsecret
      --syncmode=snap
      --metrics
      --metrics.addr=0.0.0.0
      --metrics.port=6060
      --maxpeers=50
      --ipcdisable
```

### Consensus Client (Lighthouse)

```yaml
services:
  consensus-client:
    # ...configurações existentes...
    command: >
      lighthouse bn
      --network holesky                # ⚠️ Muda de mainnet para holesky
      --datadir /root/.lighthouse
      --http
      --http-address 0.0.0.0
      --http-port 5052
      --metrics
      --metrics-address 0.0.0.0
      --metrics-port 5054
      --execution-endpoint http://execution-client:8551
      --execution-jwt /root/jwtsecret
      --checkpoint-sync-url https://holesky.checkpoint.sigp.io  # ⚠️ URL da testnet
      --disable-deposit-contract-sync
```

### Rocket Pool Node

```yaml
services:
  rocketpool-node:
    # ...configurações existentes...
    environment:
      - ETH1_ENDPOINT=http://execution-client:8545
      - ETH2_ENDPOINT=http://consensus-client:5052
      - ROCKET_POOL_VERSION=v1.16.0
      - ROCKET_POOL_NETWORK=holesky    # ⚠️ Adicionar esta variável
```

## 2. Configuração do user-settings.yml

O arquivo `user-settings.yml` do Rocket Pool precisaria ser configurado para testnet:

```yaml
# Rocket Pool User Settings - Testnet Holesky
smartnode:
  network: holesky                    # ⚠️ Especifica a testnet
  dataPath: /.rocketpool/data
  passwordPath: /.rocketpool/data/password
  walletPath: /.rocketpool/data/wallet
  validatorKeychainPath: /.rocketpool/data/validators

chains:
  eth1:
    provider: http://execution-client:8545
    wsProvider: ws://execution-client:8546
    chainID: 17000                    # ⚠️ Chain ID da Holesky testnet
    
  eth2:
    provider: http://consensus-client:5052
    
grafana:
  enabled: true
  hostname: grafana
  port: 3000
  
prometheus:
  enabled: true
  hostname: prometheus
  port: 9090
```

## 3. Diferenças Importantes da Testnet

### Requisitos de Hardware Reduzidos

| Componente | Mainnet | Testnet Holesky |
|------------|---------|-----------------|
| **Armazenamento** | 1TB+ | ~100-200GB |
| **RAM** | 16GB+ | 8GB mínimo |
| **Sincronização** | 6-12 horas | 1-2 horas |
| **Peers** | 50-100 | 10-30 |

### Especificações Técnicas

- **Holesky Chain ID**: 17000
- **Contratos Rocket Pool**: Endereços diferentes na testnet
- **Checkpoint Sync**: URLs específicas da testnet
- **ETH de Teste**: Disponível via faucets gratuitos

## 4. Processo de Migração para Testnet

### Passo 1: Backup da Configuração Atual

```bash
# Parar configuração atual (se estiver rodando)
docker-compose -f docker-compose.ssd.yml --env-file .env.ssd down

# Backup dos dados atuais (IMPORTANTE!)
sudo cp -r /Volumes/KINGSTON/ethereum-data /Volumes/KINGSTON/ethereum-data-mainnet-backup

# Criar snapshot da configuração
cp docker-compose.ssd.yml docker-compose.ssd.yml.mainnet.backup
```

### Passo 2: Limpar Dados para Testnet

```bash
# Limpar dados blockchain (manter configurações)
sudo rm -rf /Volumes/KINGSTON/ethereum-data/execution-data/geth/chaindata
sudo rm -rf /Volumes/KINGSTON/ethereum-data/execution-data/geth/lightchaindata
sudo rm -rf /Volumes/KINGSTON/ethereum-data/consensus-data/mainnet

# OU limpar tudo (reset completo)
sudo rm -rf /Volumes/KINGSTON/ethereum-data/execution-data/*
sudo rm -rf /Volumes/KINGSTON/ethereum-data/consensus-data/*
sudo rm -rf /Volumes/KINGSTON/ethereum-data/rocketpool/*
```

### Passo 3: Aplicar Configurações de Testnet

1. **Editar docker-compose.ssd.yml** com as mudanças acima
2. **Criar user-settings.yml** para testnet
3. **Verificar variáveis de ambiente** no .env.ssd

### Passo 4: Iniciar Sistema na Testnet

```bash
# Iniciar com configuração de testnet
docker-compose -f docker-compose.ssd.yml --env-file .env.ssd up -d

# Verificar logs
docker-compose -f docker-compose.ssd.yml --env-file .env.ssd logs -f

# Verificar status dos containers
docker ps
```

## 5. Configuração do Rocket Pool na Testnet

### Primeiros Passos

```bash
# Entrar no container do Rocket Pool
docker exec -it rocketpool-node /bin/bash

# Inicializar carteira (com senha de teste)
rocketpool wallet init

# Verificar status da rede
rocketpool network node-fee

# Verificar status do node
rocketpool node status
```

### Obter ETH de Teste

#### Faucets Disponíveis

1. **Faucet Principal Holesky**: <https://holesky-faucet.pk910.de/>
   - Até 1 ETH por dia
   - Requer resolver captcha

2. **QuickNode Faucet**: <https://faucet.quicknode.com/ethereum/holesky>
   - 0.5 ETH por request
   - Requer conta social

3. **Stakely Faucet**: <https://stakely.io/en/faucet/ethereum-holesky-testnet-eth>
   - 1 ETH por dia
   - Simples e rápido

#### Quantidade Necessária

- **Mínimo**: 32 ETH para validador
- **Recomendado**: 35-40 ETH (incluindo gas para transações)
- **Bond do Node**: 8 ETH (pode variar)

### Registrar Node Operator

```bash
# Verificar saldo
rocketpool node balance

# Registrar como node operator
rocketpool node register

# Fazer depósito do bond (normalmente 8 ETH na testnet)
rocketpool node deposit

# Verificar elegibilidade para criar validador
rocketpool node can-create-validator

# Criar validador (quando pools estiverem disponíveis)
rocketpool node deposit
```

## 6. Monitoramento na Testnet

Os dashboards do Grafana funcionam igualmente na testnet, mas você observará:

### Métricas Esperadas

- **Números menores**: Menos peers conectados (10-30 vs 50-100)
- **Blocos menores**: Menos transações por bloco
- **Sincronização rápida**: Progresso mais visível e rápido
- **Validadores**: Menor quantidade total na rede

### URLs de Monitoramento

- **Grafana**: <http://localhost:3000> (admin/admin)
- **Prometheus**: <http://localhost:9090>
- **Geth Metrics**: <http://localhost:6060/debug/metrics/prometheus>
- **Lighthouse Metrics**: <http://localhost:5054/metrics>

### **Dashboards Grafana Criados**

Foram criados dois dashboards específicos para monitorar a testnet Holesky:

#### 1. **Geth Holesky Dashboard** (`geth-holesky.json`)

- **UID**: `geth-holesky-monitoring`
- **Métricas monitoradas**:
  - Current Block Header/Height
  - Finalized Block
  - Connected Peers
  - Chain ID (17000 - Holesky)
  - Block Height Progress
  - Peer Connections Timeline
  - Memory Usage (Go runtime)
  - Transaction Pool (pending/queued)

#### 2. **Lighthouse Holesky Dashboard** (`lighthouse-holesky.json`)

- **UID**: `lighthouse-holesky-monitoring`
- **Métricas monitoradas**:
  - Head Slot
  - Finalized Epoch  
  - Connected Peers
  - Sync Status
  - Slot Progress Timeline
  - Peer Connections Timeline
  - Memory Usage (Process)
  - Attestation Performance
  - Database Size

### **Configuração das Métricas**

Os dashboards usam as seguintes configurações do Prometheus:

```yaml
# Geth Holesky
job_name: 'geth-holesky'
targets: ['execution-client-holesky:6060']
path: /debug/metrics/prometheus

# Lighthouse Holesky  
job_name: 'lighthouse-holesky'
targets: ['consensus-client-holesky:5054']
path: /metrics
```

### **Acesso aos Dashboards**

1. **Grafana**: <http://localhost:3000>
2. **Login**: admin/admin (altere na primeira vez)
3. **Dashboards**: Buscar por "Holesky" ou acessar diretamente:
   - Geth: `/d/geth-holesky-monitoring`
   - Lighthouse: `/d/lighthouse-holesky-monitoring`

### ⚠️ **Status Atual**

- ✅ **Geth**: Métricas funcionando (sincronizando bloco 0)
- 🟡 **Lighthouse**: Ainda baixando genesis state (normal na primeira vez)
- ✅ **Dashboards**: Carregados e funcionais
- ✅ **Prometheus**: Coletando métricas do Geth

### 📝 **Observações**

- Os dashboards mostrarão dados assim que os clientes terminarem a sincronização inicial
- Geth está conectado com 10 peers e sincronizando
- Lighthouse precisa terminar o download do genesis state primeiro
- Métricas serão atualizadas automaticamente a cada 15-30 segundos

## 7. Comandos Úteis na Testnet

### Verificações de Status

```bash
# Status geral do node
rocketpool node status

# Saldo de ETH na carteira
rocketpool node balance

# Status da rede testnet
rocketpool network node-fee

# Verificar validadores
rocketpool validator status

# Informações da minipool
rocketpool minipool status
```

### Logs Específicos da Testnet

```bash
# Verificar se está na rede correta
docker logs consensus-client | grep -i holesky
docker logs execution-client | grep -i holesky

# Verificar chain ID
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545

# Verificar peers conectados
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  http://localhost:8545
```

### Métricas Específicas

```bash
# Verificar chain ID no Prometheus
curl -s http://localhost:9090/api/v1/query?query=eth_chain_id

# Verificar se está sincronizando
curl -s http://localhost:9090/api/v1/query?query=eth_syncing

# Status do Lighthouse
curl -s http://localhost:5054/metrics | grep beacon_head_slot
```

## 8. Exploradores e Recursos da Testnet

### Block Explorers

- **Holesky Etherscan**: <https://holesky.etherscan.io/>
- **Holesky Beaconcha.in**: <https://holesky.beaconcha.in/>
- **Holesky Explorer**: <https://explorer.holesky.ethpandaops.io/>

### Recursos Adicionais

- **Rocket Pool Testnet Docs**: <https://docs.rocketpool.net/guides/testnet/overview>
- **Holesky Network Info**: <https://holesky.ethpandaops.io/>
- **Lighthouse Holesky Guide**: <https://lighthouse-book.sigmaprime.io/testnets.html>
- **Ethereum Holesky Specs**: <https://github.com/eth-clients/holesky>

## 9. Migração Testnet → Mainnet

Quando estiver confortável com a testnet e quiser migrar para mainnet:

### Passo 1: Validar Conhecimento

- [ ] Node sincronizou completamente na testnet
- [ ] Criou e gerenciou validadores com sucesso
- [ ] Monitoramento funcionando corretamente
- [ ] Procedures de backup/restore testados
- [ ] Configurações de alertas validadas

### Passo 2: Preparar Migração

```bash
# Parar sistema testnet
docker-compose -f docker-compose.ssd.yml --env-file .env.ssd down

# Backup completo da configuração testnet
sudo cp -r /Volumes/KINGSTON/ethereum-data /Volumes/KINGSTON/ethereum-data-testnet-backup

# Restaurar configuração original para mainnet
cp docker-compose.ssd.yml.mainnet.backup docker-compose.ssd.yml
```

### Passo 3: Limpar e Reinicializar

```bash
# Limpar dados de blockchain da testnet
sudo rm -rf /Volumes/KINGSTON/ethereum-data/execution-data/*
sudo rm -rf /Volumes/KINGSTON/ethereum-data/consensus-data/*

# Manter configurações do Rocket Pool se desejar
# sudo rm -rf /Volumes/KINGSTON/ethereum-data/rocketpool/*
```

### Passo 4: Iniciar na Mainnet

```bash
# Iniciar sincronização da mainnet
docker-compose -f docker-compose.ssd.yml --env-file .env.ssd up -d

# Acompanhar sincronização (vai demorar mais)
docker-compose -f docker-compose.ssd.yml --env-file .env.ssd logs -f
```

## 10. Troubleshooting Comum na Testnet

### Problema: Poucos Peers Conectados

```bash
# Normal na testnet ter menos peers (10-30)
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  http://localhost:8545
```

### Problema: Faucet não Funciona

- Tente faucets alternativos listados acima
- Verifique se não excedeu limite diário
- Use endereços diferentes
- Participe de comunidades Discord para distribuição manual

### Problema: Validador não Ativa

```bash
# Verificar se tem ETH suficiente
rocketpool node balance

# Verificar status da queue de ativação
rocketpool network queue

# Na testnet, ativação pode ser mais lenta devido a menos validadores
```

### Problema: Sincronização Lenta

```bash
# Verificar checkpoint sync
docker logs consensus-client | grep checkpoint

# Na testnet, mesmo sendo mais rápida, pode ter instabilidades
```

## 11. Checklist de Configuração

### Pré-Migração para Testnet

- [ ] Backup completo dos dados atuais
- [ ] Cópia de segurança do docker-compose.yml
- [ ] Verificação de espaço em disco (mínimo 200GB livres)
- [ ] Documentação dos endereços/chaves importantes

### Durante a Configuração

- [ ] Alteração correta dos parâmetros de rede
- [ ] URLs de checkpoint sync atualizadas
- [ ] Chain ID configurado (17000)
- [ ] Verificação dos logs de inicialização

### Pós-Configuração

- [ ] Containers rodando sem erros
- [ ] Sincronização progredindo
- [ ] Métricas sendo coletadas
- [ ] Dashboards funcionando
- [ ] ETH de teste obtido
- [ ] Node registrado na rede

### Validação Final

- [ ] Criação de validador bem-sucedida
- [ ] Monitoramento funcionando
- [ ] Alertas configurados
- [ ] Procedures de backup testados

## Conclusão

A testnet Holesky é uma ferramenta fundamental para:

- **Aprender** sem riscos financeiros
- **Validar** configurações de hardware
- **Testar** procedures operacionais
- **Experimentar** features do Rocket Pool

**Tempo recomendado na testnet**: 1-2 semanas operando validadores antes de migrar para mainnet.

**Próximos passos**: Após dominar a testnet, você estará preparado para operar na mainnet com confiança e conhecimento sólido.

---

**Importante**: Este guia não altera sua configuração atual. Todas as mudanças sugeridas são apenas para referência caso decida testar na Holesky testnet.

## STATUS ATUAL (Atualizado em 01/07/2025)

**✅ CONFIGURAÇÃO COMPLETA E FUNCIONANDO!**

Todos os containers da testnet Holesky estão executando corretamente:

- ✅ **execution-client-holesky** (Geth) - Sincronizando com Chain ID 17000
- ✅ **consensus-client-holesky** (Lighthouse) - Executando
- ✅ **rocketpool-node-holesky** - Funcionando (aguardando inicialização da carteira)
- ✅ **prometheus-holesky** - Coletando métricas
- ✅ **grafana-holesky** - Dashboards disponíveis
- ✅ **node-exporter-holesky** - Métricas do sistema

### Problema Resolvido: user-settings.yml

O principal problema era o formato incorreto do arquivo `user-settings.yml`. A solução foi:

1. **Baseado no template oficial**: Usar `user-settings.template.yml` como referência
2. **Formato correto**: Valores como strings dentro da seção `root`
3. **Localização correta**: `${ROCKETPOOL_DATA_PATH}/user-settings.yml`

```yaml
root:
  version: "1.16.0"
  network: "holesky"
  isNative: "false"
  executionClientMode: "external"
  consensusClientMode: "external"
  externalExecutionHttpUrl: "http://execution-client-holesky:8545"
  externalExecutionWsUrl: "ws://execution-client-holesky:8546"
  externalConsensusHttpUrl: "http://consensus-client-holesky:5052"
  enableMetrics: "true"
  enableMevBoost: "false"
```

### Próximos Passos

1. **Aguardar sincronização completa** do Geth e Lighthouse
2. **Inicializar carteira Rocket Pool**:

   ```bash
   docker exec -it rocketpool-node-holesky rocketpool wallet init
   ```

3. **Monitorar através do Grafana**: <http://localhost:3000>
4. **Obter ETH de teste** via faucets

---

# Próximos Passos - Configuração do Nó Rocket Pool

## Status Atual

- Infraestrutura configurada e funcionando
- Clientes Ethereum (Geth + Lighthouse) sincronizando
- Rocket Pool node inicializado
- Monitoramento (Prometheus + Grafana) ativo
- Wallet não configurada (próximo passo)

## 1. CONFIGURAÇÃO DA WALLET

### 1.1 Inicializar Nova Wallet

```bash
# Criar nova wallet com senha segura
docker exec -it rocketpool-node rocketpool api wallet init

# OU recuperar wallet existente (se já tiver)
docker exec -it rocketpool-node rocketpool api wallet recover
```

**IMPORTANTE**:

- Anote a frase mnemônica (seed phrase) em local seguro
- Nunca compartilhe a frase mnemônica
- Use senha forte e única
- Faça backup da frase mnemônica

### 1.2 Verificar Status da Wallet

```bash
docker exec -it rocketpool-node rocketpool api wallet status
```

## 2. AGUARDAR SINCRONIZAÇÃO COMPLETA

### 2.1 Monitorar Sincronização do Geth

```bash
# Verificar progresso de sincronização
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545

# Verificar número do bloco atual
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545
```

### 2.2 Monitorar Lighthouse

```bash
# Verificar logs do Lighthouse
docker logs consensus-client --tail 50

# Status do beacon chain
curl http://localhost:5052/eth/v1/node/syncing
```

### 2.3 Usar Script de Monitoramento

```bash
# Monitor automático (executa a cada 5 min)
./monitor-ssd.sh

# Para monitoramento contínuo
watch -n 300 ./monitor-ssd.sh
```

## 3. CONFIGURAÇÃO DO NÓ ROCKET POOL

### 3.1 Verificar Status de Sincronização

```bash
# Verificar se os clientes estão sincronizados
docker exec -it rocketpool-node rocketpool api node sync
```

### 3.2 Depositar ETH para Stake

**Requisitos**:

- Mínimo: 16 ETH (8 ETH do node + 8 ETH da pool)
- Recomendado: 32 ETH para validador completo
- RPL tokens para collateral (mínimo 10% do ETH depositado)

```bash
# Verificar endereço da wallet para enviar ETH
docker exec -it rocketpool-node rocketpool api wallet status

# Verificar saldo
docker exec -it rocketpool-node rocketpool api node balance
```

### 3.3 Adquirir RPL Tokens

```bash
# Verificar preço atual do RPL
docker exec -it rocketpool-node rocketpool api network rpl-price

# Calcular collateral necessário
docker exec -it rocketpool-node rocketpool api node calculate-rpl-stake
```

## 4. CRIAÇÃO DE MINIPOOL

### 4.1 Criar Minipool

```bash
# Criar minipool de 16 ETH
docker exec -it rocketpool-node rocketpool api minipool create-with-amount 16

# OU criar minipool de 8 ETH (LEB8)
docker exec -it rocketpool-node rocketpool api minipool create-with-amount 8
```

### 4.2 Verificar Status do Minipool

```bash
# Listar minipools
docker exec -it rocketpool-node rocketpool api minipool list

# Status detalhado
docker exec -it rocketpool-node rocketpool api minipool status
```

## 5. MONITORAMENTO CONTÍNUO

### 5.1 Dashboards Grafana

**CONFIGURAÇÃO COMPLETA:**

- **URL**: <http://localhost:3000>
- **Login**: admin/admin (altere na primeira vez)
- **Datasource Prometheus**: Configurado automaticamente
- **Dashboard Ethereum**: Importado e disponível

**PRIMEIRO ACESSO AO GRAFANA:**

1. Acesse <http://localhost:3000>
2. Login: `admin` / `admin`
3. Altere a senha quando solicitado
4. O dashboard estará disponível no menu lateral

**DASHBOARD FUNCIONANDO:**

**Problema resolvido**: Dashboard aparece no Grafana
**Erro de compatibilidade**: Dashboard com erro de cor - corrigido
**Solução alternativa**: Criar dashboard manual

**ACESSO AO GRAFANA:**

1. Acesse <http://localhost:3000>
2. Login: `admin` / `admin` (troque a senha)
3. Vá em "Dashboards" ou clique no "+" no menu
4. Selecione "Import dashboard" ou "New dashboard"

**CRIAR DASHBOARD MANUAL (RECOMENDADO):**

1. No Grafana, clique em "+" e depois "Dashboard"
2. Clique em "Add visualization"
3. Configure uma query: `up{job="consensus-client"}`
4. Salve o painel como "Consensus Status"
5. Adicione mais painéis para outras métricas

**MÉTRICAS PRINCIPAIS PARA ADICIONAR:**

- `up{job="consensus-client"}` - Status do consensus
- `up{job="execution-client"}` - Status do execution  
- `beacon_head_slot` - Sincronização do beacon
- `beacon_peer_count` - Peers conectados

**MÉTRICAS DISPONÍVEIS NO DASHBOARD:**

- **Consensus Client (Lighthouse)**: Beacon head slot, peers, sincronização
- **Execution Client (Geth)**: Informações básicas do node
- **Sistema**: CPU, memória, disco, rede
- **Rocket Pool**: Métricas específicas quando ativo

### 5.2 Prometheus - Queries Úteis

**URL**: <http://localhost:9090>

**Verificar Sincronização:**

```promql
# Slot atual do beacon
beacon_head_slot

# Peers conectados
beacon_peer_count

# Status geral dos services
up
```

**Monitorar Sistema:**

```promql
# CPU usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage  
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk usage
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100
```

### 5.3 Status Atual do Monitoramento

**CONTAINERS ATIVOS:**

- execution-client: UP (métricas básicas)
- consensus-client: UP (beacon_head_slot: 12027519)
- prometheus: UP (coletando métricas)
- grafana: UP (dashboard carregado)
- rocketpool-node: UP
- node-exporter: UP

**MÉTRICAS CONFIRMADAS:**

- Lighthouse: beacon_head_slot, beacon_peer_count, etc.
- Sistema: CPU, memória, disco, rede
- Geth: Métricas básicas (geth_info)
- Prometheus: Todas as coletas funcionando

### 5.4 Comandos de Monitoramento

```bash
# Status geral do nó
docker exec -it rocketpool-node rocketpool api node status

# Recompensas acumuladas
docker exec -it rocketpool-node rocketpool api node rewards

# Performance dos validadores
docker exec -it rocketpool-node rocketpool api minipool performance
```

### 5.5 Logs Importantes

```bash
# Logs do Rocket Pool
docker logs rocketpool-node

# Logs dos clientes
docker logs execution-client
docker logs consensus-client

# Logs em tempo real
docker-compose -f docker-compose.ssd.yml logs -f
```

## 6. MANUTENÇÃO E ATUALIZAÇÕES

### 6.1 Backup Regular

```bash
# Backup automático (já incluído no monitor-ssd.sh)
tar -czf "/Volumes/KINGSTON/ethereum-data/backups/backup-$(date +%Y%m%d-%H%M%S).tar.gz" \
  -C "/Volumes/KINGSTON/ethereum-data" \
  execution-data/geth/keystore rocketpool-data/.rocketpool
```

### 6.2 Atualizações

```bash
# Atualizar imagens Docker
docker-compose -f docker-compose.ssd.yml pull

# Reiniciar com novas imagens
docker-compose -f docker-compose.ssd.yml up -d
```

### 6.3 Verificação de Saúde

```bash
# Verificar saúde dos containers
docker-compose -f docker-compose.ssd.yml ps

# Verificar recursos do sistema
./monitor-ssd.sh
```

## 7. ALERTAS E NOTIFICAÇÕES

### 7.1 Configurar Alertas no Grafana

Configure alertas para:

- Desconexão de peers
- Falha de sincronização
- Uso alto de disco/memória
- Perda de validador

### 7.2 Monitoramento de Performance

- **Uptime do validador**: >99%
- **Attestation rate**: >95%
- **Proposal success**: 100%
- **Sync committee participação**: 100%

## CRONOGRAMA ESTIMADO

1. **Agora**: Configurar wallet (30 min)
2. **24-48h**: Aguardar sincronização completa
3. **Após sync**: Depositar ETH e RPL
4. **1-2 dias**: Criar minipool e ativar validador
5. **Ongoing**: Monitoramento diário

## RECURSOS ADICIONAIS

- **Documentação Oficial**: <https://docs.rocketpool.net/>
- **Discord da Comunidade**: <https://discord.gg/rocketpool>
- **Calculadora RPL**: <https://www.rp-metrics.com/>
- **Block Explorer**: <https://etherscan.io/>

## PRÓXIMO COMANDO A EXECUTAR

```bash
# PRÓXIMO PASSO IMEDIATO:
docker exec -it rocketpool-node rocketpool api wallet init
```

**ATENÇÃO**: Mantenha sua frase mnemônica em local MUITO SEGURO!

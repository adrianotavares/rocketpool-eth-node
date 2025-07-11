# Rocket Pool Node - Testnet Hoodi

Configuração completa para execução de um nó Rocket Pool na testnet **Hoodi** (Chain ID: 560048) com dados armazenados no SSD externo, separadamente da Holesky.

## 📋 Pré-requisitos

- Docker Engine (versão 20.10+)
- Docker Compose (versão 2.0+)
- SSD externo com 200GB+ de espaço livre
- 16GB+ RAM (8GB mínimo)
- Conexão de internet estável
- Port forwarding configurado no roteador

## �️ Separação de Dados

Esta configuração garante que os dados da Hoodi fiquem completamente separados dos dados da Holesky:

```text
/Volumes/KINGSTON/
├── ethereum-data-holesky/     # Dados da Holesky
│   ├── execution-data/
│   ├── consensus-data/
│   └── rocketpool/
└── ethereum-data-hoodi/       # Dados da Hoodi
    ├── execution-data/
    ├── consensus-data/
    ├── rocketpool/
    ├── prometheus-data/
    ├── grafana-data/
    └── alertmanager-data/
```

## �🚀 Início Rápido

### 1. Configuração Inicial

```bash
# Navegue até o diretório do projeto
cd /Users/adrianotavares/dev/rocketpool-eth-node

# Verifique se o SSD está montado
ls -la /Volumes/KINGSTON/

# Execute o script de inicialização
./scripts/start-hoodi.sh
```

**O script automaticamente:**

- Carrega variáveis do `.env.hoodi`
- Verifica se o SSD está conectado
- Cria diretórios no SSD
- Gera JWT secret
- Configura permissões
- Inicia todos os containers

### 2. Verificação do Status

```bash
# Execute o diagnóstico completo
./scripts/diagnose-hoodi.sh

# Monitore logs em tempo real
docker compose -f docker-compose-hoodi.yml logs -f
```

### 3. Acesso às Interfaces

- **Grafana**: <http://localhost:3000> (admin/admin123)
- **Prometheus**: <http://localhost:9090>
- **Geth RPC**: <http://localhost:8545>
- **Lighthouse API**: <http://localhost:5052>

## 🏗️ Arquitetura dos Serviços

### Execution Layer (Geth)

- **Rede**: Hoodi testnet (`--hoodi`)
- **Porta P2P**: 30303 (TCP/UDP)
- **RPC HTTP**: 8545
- **RPC WebSocket**: 8546
- **Auth RPC**: 8551
- **Metrics**: 6060

### Consensus Layer (Lighthouse)

- **Rede**: Hoodi (`--network=hoodi`)
- **Porta P2P**: 9000 (TCP/UDP)
- **HTTP API**: 5052
- **Metrics**: 5054
- **Checkpoint Sync**: <https://checkpoint-sync.hoodi.ethpandaops.io>

### MEV-Boost

- **Porta**: 18550
- **Relays configurados**:
  - Flashbots Hoodi
  - Bloxroute Hoodi

### Monitoramento

- **Prometheus**: 9090
- **Grafana**: 3000
- **Node Exporter**: 9100

## 🔧 Comandos Úteis

### Gerenciamento de Serviços

```bash
# Iniciar todos os serviços
./scripts/start-hoodi.sh

# Parar todos os serviços
./scripts/stop-hoodi.sh

# Reiniciar um serviço específico
docker compose -f docker-compose-hoodi.yml restart geth

# Ver status dos containers
docker compose -f docker-compose-hoodi.yml ps
```

### Logs e Diagnóstico

```bash
# Diagnóstico completo
./scripts/diagnose-hoodi.sh

# Logs de um serviço específico
docker compose -f docker-compose-hoodi.yml logs -f geth
docker compose -f docker-compose-hoodi.yml logs -f lighthouse

# Últimas 100 linhas de log
docker compose -f docker-compose-hoodi.yml logs --tail=100 geth
```

### Consultas RPC

```bash
# Status de sincronização do Geth
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545

# Número do bloco atual
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545

# Status do Lighthouse
curl http://localhost:5052/eth/v1/node/health

# Informações de sync do Lighthouse
curl http://localhost:5052/eth/v1/node/syncing
```

## 🔐 Configuração de Segurança

### JWT Secret

O JWT secret é gerado automaticamente na primeira execução em:

```text
rocketpool-hoodi/secrets/jwtsecret
```

### Port Forwarding

Configure as seguintes portas no seu roteador:

- **30303** (TCP/UDP) - Geth P2P
- **9000** (TCP/UDP) - Lighthouse P2P

## 📊 Monitoramento

### Grafana Dashboards

Acesse <http://localhost:3000> com:

- **Usuário**: admin
- **Senha**: admin123

Dashboards recomendados:

- Geth Metrics
- Lighthouse Metrics
- Node Exporter (sistema)
- MEV-Boost Status

### Métricas Prometheus

Acesse <http://localhost:9090> para consultas manuais.

Queries úteis:

```text
# Taxa de peers conectados
geth_p2p_peers
lighthouse_peers

# Status de sincronização
geth_chain_head_header
lighthouse_beacon_head_slot

# Uso de recursos
process_resident_memory_bytes
cpu_usage_percent
```

## 🛠️ Solução de Problemas

### Sync Lento

1. Verifique peers conectados (`diagnose-hoodi.sh`)
2. Confirme port forwarding
3. Verifique conectividade de internet
4. Monitor uso de disco/CPU

### Lighthouse não sincroniza

1. Verifique se Geth está sincronizado primeiro
2. Confirme checkpoint sync URL
3. Verifique logs para erros de conexão

### Poucos Peers

1. Configure port forwarding corretamente
2. Verifique firewall local
3. Confirme NAT traversal

### Uso alto de disco

1. Monitor crescimento dos dados
2. Configure retenção do Prometheus
3. Considere storage cleanup

## 📁 Estrutura de Dados

```text
├── rocketpool-hoodi/          # Configurações Rocket Pool
├── execution-data-hoodi/      # Blockchain data (Geth)
├── consensus-data-hoodi/      # Beacon chain data (Lighthouse)
├── prometheus-data-hoodi/     # Métricas históricas
└── grafana-data-hoodi/        # Dashboards e configurações
```

## 🔄 Backup e Recuperação

### Dados Críticos

```bash
# Backup do keystore e configurações
tar -czf rocketpool-hoodi-backup.tar.gz rocketpool-hoodi/

# Backup das configurações
cp .env.hoodi .env.hoodi.backup
```

### Limpeza Completa

```bash
# CUIDADO: Remove todos os dados
docker compose -f docker-compose-hoodi.yml down -v
rm -rf rocketpool-hoodi execution-data-hoodi consensus-data-hoodi
rm -rf prometheus-data-hoodi grafana-data-hoodi
```

## 📚 Recursos Adicionais

- [Documentação Oficial Rocket Pool](https://docs.rocketpool.net/)
- [Ethereum Hoodi Testnet](https://github.com/ethpandaops/hoodi-network)
- [Lighthouse Book](https://lighthouse-book.sigmaprime.io/)
- [Geth Documentation](https://geth.ethereum.org/docs/)

## 🆘 Suporte

Para problemas ou dúvidas:

1. Execute `./scripts/diagnose-hoodi.sh`
2. Verifique logs dos serviços
3. Consulte documentação oficial
4. Reporte issues com logs completos

---

**⚠️ Aviso**: Esta é uma configuração para testnet. Não use em produção sem revisão de segurança adequada.

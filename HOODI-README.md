# Testnet Hoodi - Configuração Completa

## ✅ Status da Implementação

### Arquivos Criados/Atualizados

1. **`.env.hoodi`** - Configuração completa para SSD
2. **`docker-compose-hoodi.yml`** - Orquestração de containers
3. **`prometheus-hoodi.yml`** - Configuração do Prometheus
4. **`/Volumes/KINGSTON/ethereum-data-hoodi/rocketpool/.rocketpool/user-settings.yml`** - Configuração do Rocket Pool (SSD)
5. **`scripts/start-hoodi.sh`** - Script de inicialização
6. **`scripts/stop-hoodi.sh`** - Script para parar serviços
7. **`scripts/clean-hoodi.sh`** - Script de limpeza completa
8. **`scripts/setup-rocketpool-hoodi.sh`** - Configuração inicial do Rocket Pool
9. **`docs/HOODI-SETUP-GUIDE.md`** - Documentação detalhada

## ✅ **PROBLEMA RESOLVIDO - user-settings.yml**

### 🎯 **Solução Implementada**
- **Arquivo user-settings.yml**: Corrigido e localizado em `/Volumes/KINGSTON/ethereum-data-hoodi/rocketpool/.rocketpool/`
- **Mapeamento Docker**: Fixado para `${ROCKETPOOL_DATA_PATH}/.rocketpool:/.rocketpool`
- **Sintaxe YAML**: Corrigida para ser compatível com Rocket Pool v1.16.0
- **Configuração**: Seguindo padrão da Holesky com adaptações para Hoodi

### 🔧 **Configuração Final**
```yaml
root:
  version: "1.16.0"
  network: "testnet"
  isNative: false
  executionClientMode: external
  consensusClientMode: external
  externalExecutionHttpUrl: http://geth-hoodi:8545
  externalExecutionWsUrl: ws://geth-hoodi:8546
  externalConsensusHttpUrl: http://lighthouse-hoodi:5052
  enableMetrics: true
  enableMevBoost: true
```

### ✅ **Status de Funcionamento**
- **Container rocketpool-node-hoodi**: ✅ Rodando sem erros
- **Arquivo user-settings.yml**: ✅ Encontrado e carregado
- **Configuração YAML**: ✅ Sintaxe válida
- **Mapeamento SSD**: ✅ Dados no local correto

**Agora o Rocket Pool está funcionando corretamente na testnet Hoodi!**

## 🚀 Como Usar

### Iniciar a Hoodi

```bash
./scripts/start-hoodi.sh
```

### Configurar Rocket Pool (primeira vez)

```bash
./scripts/setup-rocketpool-hoodi.sh
```

### Parar a Hoodi

```bash
./scripts/stop-hoodi.sh
```

### Limpeza Completa

```bash
./scripts/clean-hoodi.sh
```

## 📊 Estrutura de Dados

```text
/Volumes/KINGSTON/ethereum-data-hoodi/
├── execution-data/          # Geth blockchain data
├── consensus-data/          # Lighthouse beacon data
├── rocketpool/             # Rocket Pool configuration
│   ├── .rocketpool/
│   │   └── user-settings.yml  # Configuração principal do RP
│   └── secrets/
│       └── jwtsecret       # JWT authentication
├── prometheus-data/        # Metrics storage
├── grafana-data/          # Dashboard data
└── alertmanager-data/     # Alert management
```

## 🔧 Configuração de Rede

### Portas Utilizadas

- **30304**: Geth P2P (externa)
- **9001**: Lighthouse P2P (externa)
- **8545**: Geth RPC
- **5052**: Lighthouse API
- **3000**: Grafana
- **9090**: Prometheus

### URLs de Acesso

- **Grafana**: <http://localhost:3000> (admin/admin123)
- **Prometheus**: <http://localhost:9090>
- **Geth RPC**: <http://localhost:8545>
- **Lighthouse API**: <http://localhost:5052>

## 🛡️ Segurança

- JWT secret gerado automaticamente
- Permissões configuradas corretamente
- Dados isolados por testnet
- Containers com recursos limitados

## 📈 Recursos Estimados

- **Armazenamento**: 80-150GB
- **RAM**: 8-16GB
- **Sincronização**: 1-2 horas
- **Peers**: 25-50 conexões

## 🔍 Monitoramento

### Verificar Status

```bash
docker ps --filter name=hoodi
```

### Ver Logs

```bash
docker compose -f docker-compose-hoodi.yml logs -f
```

### Verificar Sincronização

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545
```

## 🎯 Próximos Passos

1. **Teste a Configuração**: Execute `./scripts/start-hoodi.sh`
2. **Configure Rocket Pool**: Execute `./scripts/setup-rocketpool-hoodi.sh`
3. **Configure Port Forwarding**: 30304 e 9001 no roteador
4. **Monitore Sincronização**: Acompanhe via Grafana
5. **Backup Configurações**: JWT secret e configurações importantes

## 🎮 Comandos do Rocket Pool

### Comandos Básicos

```bash
# Status geral do nó
docker exec -it rocketpool-node-hoodi rocketpool node status

# Status da wallet
docker exec -it rocketpool-node-hoodi rocketpool wallet status

# Verificar sincronização
docker exec -it rocketpool-node-hoodi rocketpool node sync

# Ver recompensas
docker exec -it rocketpool-node-hoodi rocketpool node rewards
```

### Configuração da Wallet

```bash
# Criar nova wallet
docker exec -it rocketpool-node-hoodi rocketpool wallet init

# Importar wallet existente
docker exec -it rocketpool-node-hoodi rocketpool wallet recover

# Backup da wallet
docker exec -it rocketpool-node-hoodi rocketpool wallet export
```

### Gerenciamento do Nó

```bash
# Registrar nó
docker exec -it rocketpool-node-hoodi rocketpool node register

# Definir taxa de comissão
docker exec -it rocketpool-node-hoodi rocketpool node set-commission-rate 15

# Ver depósitos
docker exec -it rocketpool-node-hoodi rocketpool node deposit
```

## 📞 Troubleshooting

### SSD não encontrado

```bash
ls -la /Volumes/KINGSTON/
```

### Portas em uso

```bash
lsof -i :30304
lsof -i :9001
```

### Problemas de sincronização

- Verificar conexão com internet
- Verificar port forwarding
- Consultar logs dos containers

---

**Pronto para uso!** A configuração está completa e otimizada para a testnet Hoodi.

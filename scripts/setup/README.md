# Scripts de Setup

Scripts para configuração inicial e preparação do ambiente Rocket Pool Holesky.

## Scripts Disponíveis

### `setup-holesky.sh` - Setup Principal

Configuração completa do ambiente Holesky.

- Preparação do docker-compose
- Configuração de variáveis de ambiente
- Inicialização dos containers
- Verificação de dependências

```bash
./scripts/setup/setup-holesky.sh
```

### `setup-ssd.sh` - Setup com SSD

Configuração para uso com SSD

- Configuração de armazenamento SSD
- Otimizações de performance
- Configuração de volumes

```bash
./scripts/setup/setup-ssd.sh
```

### `setup-external-ssd.sh` - Setup SSD Externo

Configuração para SSD externo

- Montagem de SSD externo
- Configuração de permissões
- Migração de dados

```bash
./scripts/setup/setup-external-ssd.sh
```

## Ordem de Execução

### Primeira Instalação

```bash
# 1. Setup básico
./scripts/setup/setup-holesky.sh

# 2. (Opcional) Setup com SSD
./scripts/setup/setup-ssd.sh

# 3. Verificar instalação
./scripts/monitoring/monitor-holesky.sh
```

### Com SSD Externo

```bash
# 1. Setup do SSD externo
./scripts/setup/setup-external-ssd.sh

# 2. Setup principal
./scripts/setup/setup-holesky.sh

# 3. Verificar instalação
./scripts/monitoring/monitor-holesky.sh
```

## Pré-requisitos

### Sistema

- Docker e Docker Compose instalados
- Pelo menos 8GB de RAM
- 500GB+ de espaço em disco
- Conexão estável à internet

### Permissões

```bash
# Tornar scripts executáveis
chmod +x scripts/setup/*.sh

# Verificar permissões Docker
docker ps
```

## Configuração

### Variáveis de Ambiente

Os scripts criam e configuram:

- `.env.holesky` - Configurações da testnet
- `user-settings-holesky.yml` - Configurações do Rocket Pool

### Portas Utilizadas

- 8545, 8546: Geth RPC
- 8551: Geth Engine API
- 5052, 5054: Lighthouse API
- 9000: Lighthouse P2P
- 3000: Grafana
- 9090: Prometheus

## 🛠️ Personalização

### Modificar Configurações

```bash
# Editar variáveis antes do setup
nano .env.holesky

# Executar setup personalizado
./scripts/setup/setup-holesky.sh
```

### Configurações Avançadas

- MEV-Boost (opcional)
- Configurações de rede
- Otimizações de performance

## Troubleshooting

### Problemas Comuns

- Portas em uso
- Falta de espaço em disco
- Permissões Docker
- Conexão à internet

### Logs de Setup

```bash
# Ver logs durante o setup
./scripts/setup/setup-holesky.sh 2>&1 | tee setup.log

# Analisar logs após o setup
grep -i error setup.log
```

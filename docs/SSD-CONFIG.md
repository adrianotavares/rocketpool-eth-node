# Configuração em SSD Externo - Rocket Pool Node

Esta documentação detalha como configurar o Rocket Pool Ethereum Node em um SSD externo de 1TB, mantendo os arquivos originais do projeto intactos.

## Por que usar SSD Externo?

- **Espaço**: A blockchain Ethereum ocupa ~800GB+ e está crescendo
- **Performance**: SSD oferece melhor performance que HDD tradicional
- **Flexibilidade**: Fácil de mover entre máquinas
- **Custo-benefício**: SSDs externos de 1TB são mais acessíveis
- **Isolamento**: Separa os dados do blockchain do sistema principal

## Estrutura do Projeto com SSD Externo

```text
# Estrutura Local (Código)
rocketpool-eth-node/
├── docker-compose.yml           # Original (não modificado)
├── docker-compose.ssd.yml       # Novo - configuração para SSD
├── .env.ssd                     # Novo - variáveis do SSD
├── setup-ssd.sh                 # Novo - script de configuração
├── monitor-ssd.sh               # Novo - script de monitoramento
├── SSD-CONFIG.md                # Este arquivo
└── README.md                    # Original (não modificado)

# Estrutura no SSD Externo
/Volumes/EthereumNode/  (macOS) ou /mnt/ethereum-ssd/  (Linux)
├── ethereum-data/
│   ├── execution-data/          # Dados do Geth
│   ├── consensus-data/          # Dados do Lighthouse  
│   ├── rocketpool/              # Dados do Rocket Pool
│   ├── prometheus-data/         # Dados do Prometheus
│   └── grafana-data/            # Dados do Grafana
└── backups/                     # Backups automáticos
```

## Pré-requisitos

- SSD externo de 1TB+ conectado
- Docker e Docker Compose instalados
- Sistema operacional: macOS ou Linux
- Conexão USB 3.0+ ou Thunderbolt (recomendado)

## Setup Rápido

1. **Clone o projeto** (se ainda não fez):

   ```bash
   git clone https://github.com/seu-usuario/rocketpool-eth-node.git
   cd rocketpool-eth-node
   ```

2. **Execute o script de configuração**:

   ```bash
   chmod +x setup-ssd.sh
   ./setup-ssd.sh
   ```

3. **Inicie com configuração SSD**:

   ```bash
   docker-compose -f docker-compose.ssd.yml --env-file .env.ssd up -d
   ```

## Configuração Manual Passo a Passo

### 1. Preparar o SSD Externo

#### macOS

```bash
# Verificar discos disponíveis
diskutil list

# Formatar o SSD (substitua diskX pelo seu disco)
sudo diskutil eraseDisk APFS "EthereumNode" /dev/diskX

# O macOS montará automaticamente em /Volumes/EthereumNode
```

#### Linux

```bash
# Verificar discos disponíveis
lsblk

# Formatar o SSD (substitua sdX1 pela sua partição)
sudo mkfs.ext4 /dev/sdX1

# Criar ponto de montagem
sudo mkdir -p /mnt/ethereum-ssd

# Montar
sudo mount /dev/sdX1 /mnt/ethereum-ssd

# Configurar montagem automática (opcional)
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdX1) /mnt/ethereum-ssd ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
```

### 2. Criar Estrutura de Diretórios

```bash
# Definir caminho do SSD (ajuste conforme seu sistema)
SSD_PATH="/Volumes/EthereumNode"  # macOS
# ou
SSD_PATH="/mnt/ethereum-ssd"      # Linux

# Criar estrutura de diretórios
mkdir -p "$SSD_PATH/ethereum-data"/{execution-data,consensus-data,rocketpool,prometheus-data,grafana-data}
mkdir -p "$SSD_PATH/backups"

# Definir permissões adequadas
chmod -R 755 "$SSD_PATH/ethereum-data"
chmod -R 755 "$SSD_PATH/backups"
```

### 3. Verificar Espaço Disponível

```bash
# Verificar espaço no SSD
df -h "$SSD_PATH"

# Deve mostrar pelo menos 900GB+ disponíveis para sincronização completa
```

## Comandos Úteis

### Gerenciar com SSD

```bash
# Iniciar com configuração SSD
docker-compose -f docker-compose.ssd.yml --env-file .env.ssd up -d

# Parar serviços
docker-compose -f docker-compose.ssd.yml down

# Ver logs
docker-compose -f docker-compose.ssd.yml logs -f

# Status dos contêineres
docker ps

# Monitorar espaço do SSD
./monitor-ssd.sh
```

### Backup e Manutenção

```bash
# Backup manual dos dados importantes
tar -czf "$SSD_PATH/backups/backup-$(date +%Y%m%d-%H%M%S).tar.gz" \
  -C "$SSD_PATH/ethereum-data" \
  execution-data/geth/keystore \
  rocketpool/.rocketpool

# Verificar saúde do SSD (macOS)
diskutil info /dev/diskX

# Verificar saúde do SSD (Linux)
sudo smartctl -a /dev/sdX
```

## Considerações de Performance

### USB vs Thunderbolt

- **USB 3.0**: Até 5 Gbps (adequado)
- **USB 3.1**: Até 10 Gbps (bom)
- **USB-C**: Até 10 Gbps (bom)
- **Thunderbolt 3/4**: Até 40 Gbps (excelente)

### Otimizações

- **Conecte diretamente**: Evite USB hubs
- **Use cabos de qualidade**: Cabos ruins limitam performance
- **Monitore temperatura**: SSDs podem throttle por calor
- **Evite fragmentação**: Mantenha 10-15% de espaço livre

## Troubleshooting

### SSD Desconectado Durante Operação

```bash
# Verificar se SSD está montado
ls -la "$SSD_PATH"

# Remontar se necessário (Linux)
sudo mount /dev/sdX1 /mnt/ethereum-ssd

# Restart dos contêineres após reconexão
docker-compose -f docker-compose.ssd.yml restart
```

### Performance Degradada

```bash
# Verificar velocidade de escrita
dd if=/dev/zero of="$SSD_PATH/test_file" bs=1M count=1000 oflag=direct

# Verificar fragmentação (Linux)
sudo e4defrag "$SSD_PATH"

# Monitorar I/O em tempo real
iostat -x 1
```

### Espaço Insuficiente

```bash
# Verificar uso do espaço por componente
du -sh "$SSD_PATH/ethereum-data"/*

# Limpar logs antigos do Docker
docker system prune -f

# Backup e limpar snapshots antigos (se aplicável)
./cleanup-old-data.sh
```

## Migração de Dados Existentes

Se você já tem dados sincronizados localmente:

```bash
# Parar contêineres
docker-compose down

# Copiar dados existentes para SSD
cp -r ./execution-data/* "$SSD_PATH/ethereum-data/execution-data/"
cp -r ./consensus-data/* "$SSD_PATH/ethereum-data/consensus-data/"
cp -r ./rocketpool/* "$SSD_PATH/ethereum-data/rocketpool/"

# Iniciar com configuração SSD
docker-compose -f docker-compose.ssd.yml --env-file .env.ssd up -d
```

## Monitoramento e Alertas

### Script de Monitoramento Automático

O arquivo `monitor-ssd.sh` fornece:

- Monitoramento de espaço em disco
- Verificação de saúde do SSD
- Alertas por email (opcional)
- Logs de performance

### Grafana Dashboard

Métricas adicionais incluídas:

- Uso de espaço do SSD
- Velocidade de I/O
- Temperatura do disco (se suportado)
- Status de montagem

## Backup Automático

### Estratégia de Backup

1. **Keystore**: Backup diário (crítico)
2. **Configurações**: Backup semanal
3. **Snapshots**: Backup mensal (opcional)

### Configuração

```bash
# Editar crontab para backups automáticos
crontab -e

# Adicionar linha para backup diário às 2:00 AM
0 2 * * * /path/to/rocketpool-eth-node/backup-essential.sh
```

## Recuperação de Desastres

### Cenário: SSD Falhou

1. **Conectar novo SSD**
2. **Restaurar from backup**:

   ```bash
   ./setup-ssd.sh  # Configurar novo SSD
   ./restore-backup.sh /path/to/backup.tar.gz
   ```

3. **Ressincronizar dados** (pode levar horas)

### Cenário: Dados Corrompidos

1. **Parar contêineres**
2. **Verificar integridade**:

   ```bash
   ./check-data-integrity.sh
   ```

3. **Restaurar from backup** ou **ressincronizar completa**

## Links Úteis

- [Rocket Pool Official Docs](https://docs.rocketpool.net/)
- [Ethereum Node Requirements](https://ethereum.org/en/developers/docs/nodes-and-clients/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [SSD Performance Guide](https://wiki.archlinux.org/title/Solid_state_drive)

## Próximos Passos

1. Execute `./setup-ssd.sh` para configuração automática
2. Monitore a sincronização inicial com `./monitor-ssd.sh`
3. Configure backups automáticos
4. Teste recuperação de desastres em ambiente de teste

---

**Nota**: Esta configuração é independente dos arquivos originais do projeto. Você pode sempre voltar à configuração original usando `docker-compose.yml` sem o sufixo `.ssd`.

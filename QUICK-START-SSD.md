# Guia de Início Rápido - SSD Externo

## Setup em 3 Passos

### 1. Conectar e Configurar SSD

```bash
# Execute o script de configuração automática
./setup-ssd.sh
```

### 2. Iniciar o Rocket Pool Node

```bash
# Iniciar todos os serviços no SSD externo
docker-compose -f docker-compose.ssd.yml --env-file .env.ssd up -d
```

### 3. Monitorar o Progresso

```bash
# Monitoramento em tempo real
./monitor-ssd.sh watch

# Ou verificação única
./monitor-ssd.sh
```

## Acessar Dashboards

| Serviço | URL | Login |
|---------|-----|-------|
| **Grafana** | <http://localhost:3000> | admin/admin |
| **Prometheus** | <http://localhost:9090> | - |

## Comandos Essenciais

```bash
# Ver logs em tempo real
docker-compose -f docker-compose.ssd.yml logs -f

# Parar todos os serviços
docker-compose -f docker-compose.ssd.yml down

# Reiniciar um serviço específico
docker-compose -f docker-compose.ssd.yml restart execution-client

# Verificar status da sincronização
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545
```

## Tempos Esperados

| Componente | Tempo | Observação |
|------------|-------|------------|
| **Lighthouse** | 5-15 min | Checkpoint sync |
| **Geth** | 2-6 horas | Snap sync |
| **Rocket Pool** | Após sync | Aguarda clientes |

## Problemas Comuns

### SSD Desconectado

```bash
# Verificar se está montado
ls -la /Volumes/EthereumNode  # macOS
ls -la /mnt/ethereum-ssd      # Linux

# Reiniciar containers após reconectar
docker-compose -f docker-compose.ssd.yml restart
```

### Espaço Insuficiente

```bash
# Verificar uso
./monitor-ssd.sh space

# Fazer backup e limpar
tar -czf backup.tar.gz execution-data/geth/keystore
docker system prune -f
```

### Performance Baixa

- Verificar conexão USB 3.0+
- Usar cabo de qualidade
- Conectar diretamente (evitar hubs)
- Monitorar temperatura do SSD

## Links Rápidos

- **Documentação Completa**: [SSD-CONFIG.md](SSD-CONFIG.md)
- **Rocket Pool Docs**: <https://docs.rocketpool.net/>
- **Troubleshooting**: <https://docs.ethstaker.cc/>

---
**Dica**: Use `./monitor-ssd.sh watch` para acompanhar o progresso da sincronização em tempo real!

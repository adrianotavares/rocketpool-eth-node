# Configuração Final do Monitoramento - Grafana e Prometheus

## Status Atual do Sistema

O sistema de monitoramento está configurado e funcionando com os seguintes componentes:

### Containers Ativos

- **execution-client (Geth)**: UP - Métricas disponíveis em :6060
- **consensus-client (Lighthouse)**: UP - Métricas disponíveis em :5054  
- **prometheus**: UP - Coleta de métricas em :9090
- **grafana**: UP - Interface web em :3000
- **rocketpool-node**: UP - Node Rocket Pool em :8000
- **node-exporter**: UP - Métricas do sistema em :9100

### URLs de Acesso

- **Grafana**: <http://localhost:3000> (admin/admin)
- **Prometheus**: <http://localhost:9090>
- **Rocket Pool**: <http://localhost:8000>

## Configuração do Grafana

### 1. Primeiro Acesso

1. Acesse <http://localhost:3000>
2. Login inicial: `admin` / `admin`
3. O sistema pedirá para trocar a senha

### 2. Datasource Prometheus

O datasource Prometheus foi configurado automaticamente em:

- URL: <http://prometheus:9090>
- Nome: Prometheus (default)

### 3. Dashboard Disponível

O dashboard `ethereum-fixed.json` foi automaticamente carregado como "Ethereum Node Monitoring v2" e está disponível no Grafana.

## Métricas Disponíveis

### Execution Client (Geth)

```text
# Principais métricas disponíveis:
- geth_chain_head_block: Bloco atual da chain
- geth_txpool_pending: Transações pendentes
- geth_p2p_peers: Número de peers conectados
- geth_chain_execution_*: Métricas de execução
```

### Consensus Client (Lighthouse)

```text
# Principais métricas disponíveis:
- beacon_head_slot: Slot atual do beacon
- beacon_finalized_epoch: Última época finalizada
- beacon_current_validators: Número de validadores
- beacon_peer_count: Peers conectados
```

### Sistema (Node Exporter)

```text
# Métricas do sistema:
- node_cpu_seconds_total: Uso de CPU
- node_memory_MemAvailable_bytes: Memória disponível
- node_filesystem_*: Uso de disco
- node_network_*: Estatísticas de rede
```

## Queries Úteis no Prometheus

### Verificar Sincronização

```promql
# Diferença entre slot atual e head slot (deve ser próximo de 0)
beacon_head_slot - beacon_clock_time_slot

# Peers conectados no consensus client
beacon_peer_count

# Peers conectados no execution client  
geth_p2p_peers
```

### Monitorar Performance

```promql
# CPU usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk usage
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100
```

## Configuração de Alertas (Opcional)

### 1. Editar prometheus.yml

Adicione regras de alerta se necessário:

```yaml
rule_files:
  - "/etc/prometheus/alerts/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

### 2. Exemplos de Alertas

Crie arquivo `alerts/ethereum-alerts.yml`:

```yaml
groups:
- name: ethereum
  rules:
  - alert: EthereumNodeDown
    expr: up{job="consensus-client"} == 0 or up{job="execution-client"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Ethereum node is down"
      
  - alert: LowPeerCount
    expr: beacon_peer_count < 5 or geth_p2p_peers < 5
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Low peer count detected"
```

## Verificações de Funcionamento

### 1. Teste das Métricas

```bash
# Verificar targets no Prometheus
curl <http://localhost:9090/api/v1/targets>

# Verificar métricas específicas
curl "<http://localhost:9090/api/v1/query?query=up>"
curl "<http://localhost:9090/api/v1/query?query=beacon_head_slot>"
curl "<http://localhost:9090/api/v1/query?query=geth_chain_head_block>"
```

### 2. Status dos Containers

```bash
docker-compose -f docker-compose.ssd.yml ps
docker-compose -f docker-compose.ssd.yml logs grafana
docker-compose -f docker-compose.ssd.yml logs prometheus
```

## Troubleshooting

### Grafana não carrega dashboards

```bash
# Verificar logs
docker logs grafana

# Verificar se arquivos estão no local correto
ls -la grafana/dashboards/
ls -la grafana/provisioning/
```

### Prometheus não coleta métricas

```bash
# Verificar configuração
docker exec prometheus cat /etc/prometheus/prometheus.yml

# Verificar logs
docker logs prometheus

# Testar conectividade
docker exec prometheus wget -qO- http://consensus-client:5054/metrics
```

### Dashboard não mostra dados

1. Verificar se datasource Prometheus está conectado
2. Verificar se as queries do dashboard estão corretas
3. Verificar se as métricas existem no Prometheus

## Próximos Passos

1. **Personalizar Dashboards**: Edite ou crie novos dashboards conforme necessário
2. **Configurar Alertas**: Implemente alertas para eventos críticos
3. **Backup Periódico**: Configure backup dos dados de monitoramento
4. **Otimização**: Ajuste intervalos de coleta conforme necessário

## Comandos de Manutenção

```bash
# Reiniciar apenas o monitoramento
docker-compose -f docker-compose.ssd.yml restart grafana prometheus

# Ver uso de recursos
docker stats

# Limpar dados antigos do Prometheus (se necessário)
docker-compose -f docker-compose.ssd.yml exec prometheus promtool query range --query="up" --start="2024-01-01T00:00:00Z" --end="2024-01-02T00:00:00Z" --step=1h
```

O sistema de monitoramento está agora completamente configurado e pronto para uso!

## Status de Validação Atual

### Containers Verificados

- **execution-client**: UP - Coletando métricas básicas
- **consensus-client**: UP - beacon_head_slot: 12027519
- **prometheus**: UP - Todos os targets ativos
- **grafana**: UP - Dashboard carregado
- **rocketpool-node**: UP - Aguardando configuração da wallet
- **node-exporter**: UP - Métricas do sistema ativas

### Métricas Confirmadas

Lighthouse (Consensus Client):

- beacon_head_slot: Funcionando
- beacon_peer_count: Disponível
- Todas as métricas do beacon chain ativas

Sistema (Node Exporter):

- CPU, memória, disco, rede: Todos funcionando
- Coleta a cada 15 segundos

Prometheus:

- Todos os targets UP
- Coleta funcionando normalmente
- Interface web acessível

Grafana:

- Interface web funcionando
- Datasource configurado automaticamente
- Dashboard importado e disponível

### Próximas Métricas (Após Configuração)

Quando a wallet for configurada e validadores ativados, aparecerão:

- Métricas específicas do Rocket Pool
- Performance dos validadores
- Recompensas e penalidades
- Status dos minipools

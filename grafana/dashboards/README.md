# Dashboards Importados

Este diretório contém dashboards recomendados para monitoramento do Rocket Pool.

## Dashboards Disponíveis

### Lighthouse (Consensus Client)

- `lighthouse_summary.json` - Visão geral do Lighthouse
- `lighthouse_validator_client.json` - Métricas do validador
- `lighthouse_validator_monitor.json` - Monitoramento avançado

### Geth (Execution Client)

- `geth_dashboard.json` - Dashboard oficial do Geth

### Sistema e Infraestrutura

- `docker_host_overview.json` - Monitoramento de containers
- `home_staking.json` - Dashboard para home staking
- `ethereum_metrics_exporter.json` - Métricas adicionais

## Como Importar

### Via Grafana UI

1. Acesse: <http://localhost:3000>
2. Vá em "+" → "Import"
3. Selecione "Upload JSON file"
4. Escolha o arquivo desejado
5. Configure Data Source como "Prometheus"

### Via Docker Compose

Os dashboards serão automaticamente provisionados se você configurar:

```yaml
grafana:
  volumes:
    - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
```

## Arquivos de Backup

Os arquivos `.backup` são backups dos originais antes das modificações.

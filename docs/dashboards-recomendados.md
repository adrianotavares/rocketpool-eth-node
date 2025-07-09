# Dashboards Recomendados para Rocket Pool

Com base na análise dos dashboards disponíveis no projeto [eth-docker](https://github.com/ethstaker/eth-docker), recomendo os seguintes dashboards para o seu ambiente Rocket Pool Holesky:

## Dashboards Essenciais

### 1. Lighthouse (Consensus Client)

O seu ambiente usa Lighthouse como consensus client. Recomendo estes dashboards:

#### Lighthouse Summary

- **URL**: <https://raw.githubusercontent.com/sigp/lighthouse-metrics/master/dashboards/Summary.json>
- **Descrição**: Visão geral das métricas principais do Lighthouse
- **Métricas**: Status de sincronização, peers, slots, attestações

#### Lighthouse Validator Client

- **URL**: <https://raw.githubusercontent.com/sigp/lighthouse-metrics/master/dashboards/ValidatorClient.json>
- **Descrição**: Métricas específicas do validador
- **Métricas**: Propostas de blocos, attestações, eficiência do validador

#### Lighthouse Validator Monitor

- **URL**: <https://raw.githubusercontent.com/sigp/lighthouse-metrics/master/dashboards/ValidatorMonitor.json>
- **Descrição**: Monitoramento avançado dos validadores
- **Métricas**: Performance detalhada, recompensas, penalidades

### 2. Geth (Execution Client)

Para o Geth (seu execution client):

#### Geth Dashboard

- **URL**: <https://gist.githubusercontent.com/karalabe/e7ca79abdec54755ceae09c08bd090cd/raw/3a400ab90f9402f2233280afd086cb9d6aac2111/dashboard.json>
- **Descrição**: Dashboard oficial do Geth
- **Métricas**: Sincronização, peers, gas, transações, memória

### 3. Sistema e Infraestrutura

#### Docker Host Container Overview

- **ID Grafana**: 19724
- **Descrição**: Monitoramento de containers Docker via cAdvisor
- **Métricas**: CPU, memória, rede, disco dos containers

#### Home Staking Dashboard

- **ID Grafana**: 17846
- **Descrição**: Dashboard específico para home staking
- **Métricas**: Métricas relevantes para validadores domésticos

#### Ethereum Metrics Exporter

- **ID Grafana**: 16277
- **Descrição**: Métricas adicionais do Ethereum
- **Métricas**: Dados da rede, validadores, rewards

## Como Importar os Dashboards

### Método 1: Import Manual via Grafana UI

1. Acesse o Grafana: <http://localhost:3000>
2. Vá em "+" → "Import"
3. Cole a URL do dashboard ou baixe o JSON
4. Configure o data source como "Prometheus"

### Método 2: Automático via Script

Criei um script de provisionamento baseado no eth-docker:

```bash
#!/bin/bash
# Script para baixar e configurar dashboards automaticamente

DASHBOARD_DIR="/Users/adrianotavares/dev/rocketpool-eth-node/grafana/dashboards"
mkdir -p "$DASHBOARD_DIR"

# Lighthouse Summary
wget -qO "$DASHBOARD_DIR/lighthouse_summary.json" \
  "https://raw.githubusercontent.com/sigp/lighthouse-metrics/master/dashboards/Summary.json"

# Lighthouse Validator Client
wget -qO "$DASHBOARD_DIR/lighthouse_validator_client.json" \
  "https://raw.githubusercontent.com/sigp/lighthouse-metrics/master/dashboards/ValidatorClient.json"

# Lighthouse Validator Monitor
wget -qO "$DASHBOARD_DIR/lighthouse_validator_monitor.json" \
  "https://raw.githubusercontent.com/sigp/lighthouse-metrics/master/dashboards/ValidatorMonitor.json"

# Geth Dashboard
wget -qO "$DASHBOARD_DIR/geth_dashboard.json" \
  "https://gist.githubusercontent.com/karalabe/e7ca79abdec54755ceae09c08bd090cd/raw/3a400ab90f9402f2233280afd086cb9d6aac2111/dashboard.json"

# Docker Host Overview
curl -s "https://grafana.com/api/dashboards/19724" | jq .revision > /tmp/revision
REVISION=$(cat /tmp/revision)
wget -qO "$DASHBOARD_DIR/docker_host_overview.json" \
  "https://grafana.com/api/dashboards/19724/revisions/$REVISION/download"

# Home Staking Dashboard
curl -s "https://grafana.com/api/dashboards/17846" | jq .revision > /tmp/revision
REVISION=$(cat /tmp/revision)
wget -qO "$DASHBOARD_DIR/home_staking.json" \
  "https://grafana.com/api/dashboards/17846/revisions/$REVISION/download"

# Ethereum Metrics Exporter
curl -s "https://grafana.com/api/dashboards/16277" | jq .revision > /tmp/revision
REVISION=$(cat /tmp/revision)
wget -qO "$DASHBOARD_DIR/ethereum_metrics_exporter.json" \
  "https://grafana.com/api/dashboards/16277/revisions/$REVISION/download"

# Fix data source references
for file in "$DASHBOARD_DIR"/*.json; do
  if [ -f "$file" ]; then
    # Replace placeholder data source with "Prometheus"
    sed -i 's/\${DS_PROMETHEUS}/Prometheus/g' "$file"
    sed -i 's/\${datasource}/Prometheus/g' "$file"
    sed -i 's/"uid": "prometheus"/"uid": "Prometheus"/g' "$file"
    echo "Processado: $(basename "$file")"
  fi
done

echo "Dashboards baixados e configurados em: $DASHBOARD_DIR"
```

### Método 3: Integração com Docker Compose

Para automação completa, você pode adicionar um provisionamento automático:

```yaml
# Adicionar ao docker-compose-holesky.yml
grafana:
  volumes:
    - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
    - ./grafana/provisioning:/etc/grafana/provisioning
```

## Prioridades de Implementação

### Fase 1 (Críticos)

1. **Lighthouse Summary** - Visão geral do consensus client
2. **Geth Dashboard** - Monitoramento do execution client
3. **Docker Host Overview** - Saúde dos containers

### Fase 2 (Importantes)

1. **Lighthouse Validator Client** - Métricas específicas de validação
2. **Home Staking Dashboard** - Métricas para staking doméstico
3. **Node Exporter** - Métricas do sistema (já tem via node-exporter-holesky)

### Fase 3 (Avançados)

1. **Lighthouse Validator Monitor** - Monitoramento avançado
2. **Ethereum Metrics Exporter** - Métricas adicionais da rede

## Dashboards Específicos para Rocket Pool

### Rocket Pool Node Dashboard

- **Recomendação**: Manter o dashboard atual `rocketpool-node.json`
- **Complementar com**: Lighthouse e Geth dashboards
- **Benefício**: Métricas específicas do protocolo Rocket Pool

### Métricas Importantes a Monitorar

- **Execution Client (Geth)**: Sincronização, peers, gas
- **Consensus Client (Lighthouse)**: Attestações, propostas, eficiência
- **Validadores**: Performance, recompensas, penalidades
- **Sistema**: CPU, memória, disco, rede
- **Rocket Pool**: Status do node, rewards, RPL staking

## Checklist de Implementação

- [ ] Baixar dashboards essenciais (Lighthouse + Geth)
- [ ] Configurar data sources corretos
- [ ] Testar importação via Grafana UI
- [ ] Verificar métricas sendo coletadas
- [ ] Customizar dashboards para o ambiente específico
- [ ] Configurar alertas críticos
- [ ] Documentar dashboards implementados

## 💡 Dicas Importantes

1. **Data Sources**: Sempre configure como "Prometheus"
2. **Customização**: Ajuste filtros por container name (geth, lighthouse)
3. **Alertas**: Configure alertas para métricas críticas
4. **Performance**: Monitore uso de recursos do Grafana
5. **Backup**: Exporte configurações dos dashboards customizados

## 🔗 Links Úteis

- [Lighthouse Metrics](https://github.com/sigp/lighthouse-metrics)
- [Geth Metrics](https://geth.ethereum.org/docs/interface/metrics)
- [Rocket Pool Metrics](https://docs.rocketpool.net/guides/node/local/advanced-config#prometheus-metrics)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)

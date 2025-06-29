# Sistema de Alertas Configurado - Rocket Pool Node

## Status: FUNCIONANDO

O sistema de alertas foi configurado com sucesso e está ativo.

## Componentes Configurados

### 1. Prometheus

**URL**: <http://localhost:9090>

- **Status**: UP e coletando métricas
- **Alertas carregados**: 9 regras de alerta ativas
- **Targets monitorados**: execution-client, consensus-client, node-exporter, prometheus

### 2. Alertmanager

**URL**: <http://localhost:9093>

- **Status**: UP e processando alertas
- **Configuração**: Webhook básico configurado
- **API**: v2 funcionando

## Dashboards

**Dashboard Ativo**: Ethereum Node Monitoring v2

- **Status**: Funcionando corretamente
- **UID**: ethereum-monitoring-v2
- **Provisionamento**: Automatizado via arquivo ethernet-fixed.json
- **Métricas**: Execution client, Consensus client, Node Exporter

**Observação**: Dashboard duplicado removido com sucesso.

## Alertas Configurados

### Alertas Críticos (Severity: critical)

1. **EthereumExecutionClientDown**: Geth não responde por > 1 min  
2. **EthereumConsensusClientDown**: Lighthouse não responde por > 1 min
3. **HighDiskUsage**: Uso de disco > 90% por > 10 min
4. **PrometheusDown**: Prometheus não responde por > 1 min

### Alertas de Aviso (Severity: warning)

1. **NodeExporterDown**: Node Exporter não responde por > 2 min
2. **HighCPUUsage**: Uso de CPU > 90% por > 5 min
3. **HighMemoryUsage**: Uso de memória > 85% por > 5 min
4. **ConsensusClientSyncLag**: Lighthouse sem sincronização por > 10 min
5. **LowPeerCount**: Lighthouse com < 5 peers por > 5 min

## Alertas Ativos Atualmente

**Status**: Nenhum alerta ativo - Todos os serviços funcionando normalmente

## URLs de Acesso

- **Prometheus**: <http://localhost:9090>
- **Alertmanager**: <http://localhost:9093>  
- **Grafana**: <http://localhost:3000>

## Configuração de Notificações

Atualmente configurado com webhook básico. Para configurar notificações:

### Email

Editar `alertmanager.yml` e descomentar a seção email-alert:

```yaml
- name: 'email-alert'
  email_configs:
  - to: 'seu-email@dominio.com'
    subject: 'Rocket Pool Alert: {{ .GroupLabels.alertname }}'
```

### Slack

Editar `alertmanager.yml` e descomentar a seção slack-alert:

```yaml
- name: 'slack-alert'
  slack_configs:
  - api_url: 'SEU_WEBHOOK_SLACK_URL'
    channel: '#alerts'
```

## Comandos Úteis

```bash
# Verificar status dos containers
docker-compose -f docker-compose.ssd.yml ps

# Ver alertas ativos
curl -s http://localhost:9093/api/v2/alerts

# Ver regras carregadas no Prometheus
curl -s http://localhost:9090/api/v1/rules

# Reiniciar alertas após mudanças
docker-compose -f docker-compose.ssd.yml restart prometheus alertmanager

# Logs dos serviços
docker logs prometheus
docker logs alertmanager
```

## Próximos Passos

1. **Configurar notificações** (email/Slack) editando `alertmanager.yml`
2. **Ajustar limites** dos alertas conforme necessário
3. **Criar dashboards** no Grafana para visualização
4. **Testar alertas** simulando falhas dos serviços

## Observações

- Todos os componentes estão funcionando corretamente
- O sistema está pronto para detectar problemas nos clientes Ethereum e infraestrutura
- Alertas podem ser silenciados temporariamente via interface do Alertmanager
- O job do Rocket Pool foi removido pois não expõe métricas por padrão

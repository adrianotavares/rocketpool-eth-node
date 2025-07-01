# CONFIGURAÇÃO CORRIGIDA DOS DASHBOARDS GRAFANA

## Problema Identificado

O dashboard "Geth Server" não mostrava dados porque:

1. **Métricas incorretas**: O dashboard original estava procurando por métricas com nomes como `geth_block`, `geth_block_transactions`, etc.
2. **Métricas reais do Geth**: O Geth expõe métricas com nomes diferentes como `chain_head_header`, `chain_head_block`, `p2p_peers`, etc.
3. **Endpoint correto**: As métricas estão em `/debug/metrics/prometheus`, não em `/metrics`

## Solução Aplicada

### 1. Métricas Geth Corrigidas

| Métrica Original (Incorreta) | Métrica Real do Geth | Descrição |
|------------------------------|---------------------|-----------|
| `geth_block` | `chain_head_header` | Número do bloco mais recente |
| `geth_block_transactions` | N/A | Não disponível no Geth padrão |
| `geth_peers` | `p2p_peers` | Número de peers conectados |
| `geth_status` | `up{job="execution-client"}` | Status do serviço |

### 2. Dashboard Novo Criado

**Arquivo**: `grafana/provisioning/dashboards/geth.json`

**Painéis incluídos**:
- **Current Block Header**: Mostra o bloco mais recente
- **Finalized Block**: Bloco finalizado
- **Connected Peers**: Número de peers conectados
- **Service Status**: Status UP/DOWN do Geth
- **Block Progress**: Gráfico temporal dos blocos
- **P2P Peers**: Gráfico temporal dos peers

### 3. Configuração do Prometheus

O Prometheus está configurado corretamente:
```yaml
- job_name: 'execution-client'
  static_configs:
    - targets: ['execution-client:6060']
  metrics_path: /debug/metrics/prometheus  # Endpoint correto
```

### 4. Verificações de Funcionamento

```bash
# Verificar métricas do Geth
curl http://localhost:6060/debug/metrics/prometheus

# Verificar coleta no Prometheus
curl "http://localhost:9090/api/v1/query?query=up"

# Verificar targets no Prometheus
curl "http://localhost:9090/api/v1/targets"
```

## Status Atual

✅ **Geth**: Conectado com 5 peers, expondo métricas  
✅ **Prometheus**: Coletando métricas do Geth corretamente  
✅ **Grafana**: Dashboard corrigido e funcionando  

## Dashboards Disponíveis

1. **Geth Server Monitoring** (`geth.json`): Métricas do cliente de execução
2. **Ethereum Node Monitoring** (`ethereum.json`): Dashboard personalizado
3. **Pasta "Ethereum"**: Todos dashboards organizados

## Como Acessar

1. Abrir: http://localhost:3000
2. Login: admin / admin
3. Navegar para: Dashboards > Ethereum > Geth Server Monitoring

---
**Data**: 30/06/2025  
**Status**: Dashboard corrigido e funcionando  

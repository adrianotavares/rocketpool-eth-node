# Guia Rápido - Criação de Dashboard Grafana Manual

## Problema Resolvido

O dashboard automatizado teve problemas de compatibilidade, mas o Grafana está funcionando perfeitamente. A solução é criar dashboards manualmente.

## Passo a Passo - Criar Dashboard

### 1. Acesso ao Grafana

- **URL**: <http://localhost:3000>
- **Login**: admin / admin (altere a senha)

### 2. Criar Novo Dashboard

1. Clique no ícone "+" no menu lateral
2. Selecione "Dashboard"
3. Clique em "Add visualization"

### 3. Configurar Primeiro Painel - Status do Consensus Client

1. **Query**: `up{job="consensus-client"}`
2. **Title**: "Consensus Client Status"
3. **Type**: Stat
4. **Value mappings**:
   - 0 = DOWN (vermelho)
   - 1 = UP (verde)
5. Clique "Apply"

### 4. Adicionar Segundo Painel - Status do Execution Client

1. Clique "Add panel"
2. **Query**: `up{job="execution-client"}`
3. **Title**: "Execution Client Status"
4. **Type**: Stat
5. Mesmo value mapping do anterior
6. Clique "Apply"

### 5. Adicionar Terceiro Painel - Beacon Head Slot

1. Clique "Add panel"
2. **Query**: `beacon_head_slot`
3. **Title**: "Beacon Head Slot"
4. **Type**: Time series
5. Clique "Apply"

### 6. Adicionar Quarto Painel - Peers Conectados

1. Clique "Add panel"
2. **Query**: `beacon_peer_count`
3. **Title**: "Peer Count"
4. **Type**: Time series
5. Clique "Apply"

### 7. Salvar Dashboard

1. Clique no ícone "Save" (disquete) no topo
2. **Title**: "Ethereum Node Monitoring"
3. Clique "Save"

## Métricas Disponíveis

### Consensus Client (Lighthouse)

```promql
beacon_head_slot              # Slot atual
beacon_peer_count            # Peers conectados
beacon_finalized_epoch       # Última época finalizada
```

### Execution Client (Geth)

```promql
up{job="execution-client"}   # Status UP/DOWN
```

### Sistema

```promql
node_cpu_seconds_total       # CPU usage
node_memory_MemAvailable_bytes # Memória disponível
```

## Queries Úteis para Dashboards

### Status de Sincronização

```promql
# Diferença entre slot atual e head (deve ser próximo de 0)
beacon_head_slot - beacon_clock_time_slot
```

### Performance do Sistema

```promql
# CPU usage percentage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

## Resultado

Após seguir estes passos você terá um dashboard funcional com:

- Status dos clientes em tempo real
- Métricas de sincronização
- Contadores de peers
- Gráficos temporais

O dashboard criado manualmente será mais estável e compatível com sua versão do Grafana.

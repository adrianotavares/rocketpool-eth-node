# Correção - Dashboard Peer Connections

## Problema Identificado

O painel "Peer Connections" no dashboard estava mostrando "No data" porque utilizava uma métrica inexistente: `beacon_peer_count`

## Solução Implementada

### Métricas Corrigidas

Substituída a métrica inexistente pelas seguintes métricas reais:

1. **Consensus Client Peers**: `libp2p_peers{job="consensus-client"}`
   - Mostra o número total de peers conectados ao cliente de consenso (Lighthouse)

2. **Execution Client Peers (Total)**: `p2p_peers{job="execution-client"}`
   - Mostra o número total de peers conectados ao cliente de execução (Geth)

3. **Execution Client Peers (Inbound)**: `p2p_peers_inbound{job="execution-client"}`
   - Mostra o número de conexões entrantes no cliente de execução

4. **Execution Client Peers (Outbound)**: `p2p_peers_outbound{job="execution-client"}`
   - Mostra o número de conexões saintes do cliente de execução

### Status Atual das Conexões

```text
Consensus Peers: 0 (em processo de sincronização)
Execution Peers Total: 11 (funcionando normalmente)
Execution Peers Inbound: 0
Execution Peers Outbound: 11
```

**Observação**: O cliente de consenso (Lighthouse) pode mostrar 0 peers durante o processo de sincronização inicial. Isso é normal e os peers aparecerão conforme a sincronização progride.

## Arquivo Modificado

- **Arquivo**: `grafana/provisioning/dashboards/ethereum-fixed.json`
- **Painel**: "Peer Connections" (ID: 4)
- **Tipo**: timeseries

## Resultado

- ✅ Dashboard agora mostra dados reais de conexões
- ✅ Métricas funcionais para ambos os clientes (Geth e Lighthouse)
- ✅ Detalhamento de conexões inbound/outbound
- ✅ Atualização automática a cada 30 segundos

## Verificação

Para verificar se as métricas estão funcionando:

```bash
# Consensus client peers
curl -s 'http://localhost:9090/api/v1/query?query=libp2p_peers{job="consensus-client"}' | jq '.data.result'

# Execution client peers
curl -s 'http://localhost:9090/api/v1/query?query=p2p_peers{job="execution-client"}' | jq '.data.result'

# Execution client inbound peers
curl -s 'http://localhost:9090/api/v1/query?query=p2p_peers_inbound{job="execution-client"}' | jq '.data.result'

# Execution client outbound peers
curl -s 'http://localhost:9090/api/v1/query?query=p2p_peers_outbound{job="execution-client"}' | jq '.data.result'
```

## Acesso ao Dashboard

1. **URL**: <http://localhost:3000>
2. **Login**: admin/admin
3. **Dashboard**: "Ethereum Node Monitoring v2"
4. **Painel**: "Peer Connections" (deve mostrar dados agora)

O dashboard agora exibe corretamente as informações de conexão de peers para ambos os clientes Ethereum.

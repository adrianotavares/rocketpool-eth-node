# Finalized Blocks - Processo de Finalização no Ethereum

## Visão Geral

Este documento explica o processo de finalização de blocos no Ethereum, especificamente no contexto do ambiente Rocket Pool Holesky, e por que as métricas de "Finalized Blocks" podem aparecer zeradas no Grafana durante a sincronização inicial.

## O que são Finalized Blocks?

### Definição

Finalized Blocks são blocos que foram confirmados pela rede Ethereum como irreversíveis. Uma vez que um bloco é finalizado, ele não pode mais ser reorganizado ou revertido, garantindo a segurança e imutabilidade da blockchain.

### Importância

- **Segurança**: Blocos finalizados não podem ser alterados
- **Confiabilidade**: Transações finalizadas são permanentes
- **Consenso**: Indicam que a rede chegou a um acordo sobre o estado

## Processo de Finalização

### Pré-requisitos para Finalização

#### 1. Sincronização Completa

Ambos os clients devem estar 100% sincronizados:

- **Execution Client (Geth)**: Deve ter todos os blocos da chain
- **Consensus Client (Lighthouse)**: Deve ter todos os slots do beacon chain

#### 2. Conectividade

- **Engine API**: Comunicação entre Geth e Lighthouse funcionando
- **P2P Network**: Conexão com peers da rede
- **Beacon Chain**: Acesso aos dados de consenso

### Sequência de Finalização

#### Fase 1: Proposição

1. **Slot**: Cada 12 segundos, um novo slot é criado
2. **Proposer**: Um validador é escolhido para propor um bloco
3. **Block Creation**: Bloco é criado com transações pendentes

#### Fase 2: Attestation

1. **Committee**: Validadores atestam a validade do bloco
2. **Voting**: Cada validador vota na head da chain
3. **Aggregation**: Votos são agregados em attestations

#### Fase 3: Justification

1. **Epoch**: Grupos de 32 slots (aproximadamente 6.4 minutos)
2. **Checkpoint**: Final de cada epoch é um checkpoint
3. **Justification**: Epoch é justificado se receber votos suficientes

#### Fase 4: Finalization

1. **Two Epochs**: Dois epochs consecutivos devem ser justificados
2. **Supermajority**: Mais de 2/3 dos validadores devem concordar
3. **Finalization**: Epoch anterior é finalizado

## Cronologia da Sincronização

### Status Atual (Exemplo)

```text
Geth: 97.66% sincronizado (1h18min restante)
Lighthouse: 42.752 slots atrás (5 dias 22 horas)
Finalized Blocks: 0 (aguardando sincronização)
```

### Timeline Estimada

#### Etapa 1: Geth Completa (0-2 horas)

- Geth alcança 100% de sincronização
- Blocos de execução atualizados
- Engine API disponível para Lighthouse

#### Etapa 2: Lighthouse Acelera (1-3 horas)

- Com Geth sincronizado, Lighthouse processa mais rápido
- Distance diminui progressivamente
- Peers aumentam conectividade

#### Etapa 3: Lighthouse Completa (2-4 horas)

- Distance chega a 0 slots
- is_syncing torna-se false
- Node pronto para participar do consenso

#### Etapa 4: Finalização Inicia (3-5 horas)

- Primeiros blocos começam a ser finalizados
- Métricas aparecem no Grafana
- Sistema totalmente operacional

## Monitoramento da Finalização

### APIs de Verificação

#### Status de Sincronização

```bash
# Verificar se Lighthouse está sincronizado
curl -s http://localhost:5052/eth/v1/node/syncing

# Exemplo de resposta (sincronizado):
# {"data":{"is_syncing":false,"is_optimistic":false,"el_offline":false}}
```

#### Checkpoints de Finalidade

```bash
# Verificar status de finalização
curl -s http://localhost:5052/eth/v1/beacon/states/head/finality_checkpoints

# Campos importantes:
# - current_justified: Epoch atualmente justificado
# - finalized: Último epoch finalizado
```

#### Cabeçalho Atual

```bash
# Verificar slot atual
curl -s http://localhost:5052/eth/v1/beacon/headers/head | jq '.data.header.message.slot'
```

### Métricas no Grafana

#### Antes da Sincronização

- **Finalized Epoch**: 0 ou valor antigo
- **Finalized Block**: 0
- **Sync Distance**: Número alto de slots
- **Peer Count**: Variável (1-10)

#### Após Sincronização

- **Finalized Epoch**: Aumenta constantemente
- **Finalized Block**: Atualiza a cada 2-3 epochs
- **Sync Distance**: 0-2 slots
- **Peer Count**: Estável (8-50)

## Troubleshooting

### Finalizações Não Aparecem

#### Possíveis Causas

1. **Sincronização Incompleta**
   - Verificar status de sync do Geth e Lighthouse
   - Confirmar que ambos estão 100%

2. **Problemas de Conectividade**
   - Verificar peers conectados
   - Validar conectividade P2P

3. **Engine API Issues**
   - Verificar comunicação Geth-Lighthouse
   - Validar JWT secret

4. **Recursos Insuficientes**
   - Verificar uso de CPU e memória
   - Confirmar que containers estão estáveis

#### Comandos de Diagnóstico

```bash
# Verificar logs do Lighthouse
docker logs lighthouse --tail 50

# Verificar conectividade Engine API
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"engine_exchangeCapabilities","params":[[]],"id":1}' \
  http://localhost:8551

# Monitor geral
./scripts/monitoring/monitor-holesky.sh
```

### Finalização Lenta

#### Sintomas

- Finalized blocks não atualizam regularmente
- Distance entre head e finalized aumenta
- Warnings sobre low peer count

#### Soluções

1. **Melhorar Conectividade**
   - Abrir portas P2P (9000/tcp, 9000/udp)
   - Verificar firewall e NAT

2. **Otimizar Recursos**
   - Aumentar memória se necessário
   - Verificar I/O do disco

3. **Verificar Network Health**
   - Confirmar que testnet está operacional
   - Verificar status em beaconcha.in

## Expectativas de Performance

### Holesky Testnet

- **Slot Time**: 12 segundos
- **Epoch Duration**: 6.4 minutos (32 slots)
- **Finalization**: A cada 2-3 epochs (~12-19 minutos)
- **Typical Distance**: 0-64 slots quando sincronizado

### Mainnet (Referência)

- **Slot Time**: 12 segundos
- **Epoch Duration**: 6.4 minutos
- **Finalization**: A cada 2 epochs (~12.8 minutos)
- **Target Distance**: 0-32 slots

## Conclusão

A ausência de finalized blocks durante a sincronização inicial é comportamento normal e esperado. O processo de finalização só inicia após ambos os clients (Geth e Lighthouse) estarem completamente sincronizados.

Uma vez que a sincronização seja concluída, as métricas de finalização aparecerão no Grafana e o sistema estará pronto para participar plenamente da rede Ethereum.

### Pontos Importantes

- **Paciência**: Sincronização pode levar várias horas
- **Monitoramento**: Use as APIs para acompanhar progresso
- **Normalidade**: Zero finalized blocks é normal durante sync
- **Automaticidade**: Finalização inicia automaticamente após sync

---

*Documento criado em: 6 de julho de 2025*  
*Atualizado: 6 de julho de 2025*

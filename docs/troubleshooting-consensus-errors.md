# Troubleshooting: "Beacon client online, but no consensus updates received in a while"

## Visão Geral

Este documento explica o erro "Beacon client online, but no consensus updates received in a while" que pode ocorrer no ambiente Rocket Pool Holesky, suas causas, e como resolver/prevenir o problema.

## Análise da Causa Raiz

### 1. **Problema Principal: Ciclo de Reinicializações do Lighthouse**

- **Observação**: Lighthouse mostra "Up 14 seconds" enquanto Geth mostra "Up 2 hours"
- **Causa**: Lighthouse reinicia frequentemente, provavelmente devido a restrições de recursos ou problemas de sincronização
- **Impacto**: Quando o Lighthouse reinicia, perde temporariamente a conexão com a API do engine do Geth, causando o erro de atualizações de consenso

### 2. **Problema Secundário: Restrições de Recursos**

- **Observação**: Lighthouse usando 98.77% de CPU e 2.835GiB de memória
- **Impacto**: Alto uso de recursos pode causar instabilidade e reinicializações

### 3. **Discrepância no Status de Sincronização**

- **Geth**: 95.58% sincronizado (bloco 3908879 de 4091231)
- **Rocket Pool**: Reporta 73.93% sincronizado (usando método de cálculo diferente)
- **Lighthouse**: Iniciando após reinicialização

## Status Atual (Resolução)

✅ **Erro está atualmente resolvido** - O sistema está funcionando adequadamente:

- Geth está estável e sincronizando normalmente
- Lighthouse está executando e consumindo endpoints da API
- Nenhum erro "beacon client online" aparece atualmente nos logs

## Por que Este Erro Ocorre

Este erro tipicamente acontece quando:

1. **Lighthouse reinicia** enquanto Geth continua executando
2. **Problemas de conectividade de rede** entre containers
3. **Incompatibilidade de JWT secret** (não é o caso aqui)
4. **Indisponibilidade de endpoint da API** durante períodos de inicialização
5. **Esgotamento de recursos** causando instabilidade do serviço

## Passos para Prevenir Futuras Ocorrências

### 1. **Monitorar e Gerenciar Recursos**

```bash
# Verificar uso de recursos regularmente
docker stats --no-stream

# Considerar aumentar limites de memória do Docker se necessário
# Editar docker-compose.yml para adicionar limites de memória
```

### 2. **Implementar Health Checks**

Adicione health checks ao seu `docker-compose.yml`:

```yaml
lighthouse:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:5052/eth/v1/node/health"]
    interval: 30s
    timeout: 10s
    retries: 3
```

### 3. **Monitorar Estabilidade do Lighthouse**

```bash
# Verificar frequência de reinicializações do Lighthouse
docker logs lighthouse 2>&1 | grep -i "starting\|stopping\|restart"

# Monitorar erros relacionados a recursos
docker logs lighthouse 2>&1 | grep -i "memory\|cpu\|resource"
```

### 4. **Verificar Conectividade da Engine API**

```bash
# Testar conectividade da engine API de dentro do container Lighthouse
docker exec lighthouse curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"engine_exchangeCapabilities","params":[[]],"id":1}' \
  http://geth:8551
```

### 5. **Implementar Políticas de Restart**

Certifique-se que seus containers tenham políticas de restart apropriadas:

```yaml
restart: unless-stopped
```

## Estratégia de Prevenção

1. **Gerenciamento de Recursos**: Monitorar uso de CPU/memória e garantir recursos adequados
2. **Monitoramento de Estabilidade**: Acompanhar frequência de reinicializações de containers
3. **Health Checks**: Implementar health checks adequados para detecção precoce
4. **Sincronização Gradual**: Permitir que ambos os clients sincronizem completamente antes de esperar coordenação perfeita

## Cronograma de Resolução Esperado

- **Imediato**: Erro não deve reocorrer enquanto Lighthouse permanecer estável
- **Curto prazo**: Monitorar pelas próximas 24-48 horas para padrões de reinicialização
- **Longo prazo**: Considerar otimização de recursos se reinicializações continuarem

## Comandos Úteis para Diagnóstico

### Verificar Status dos Containers

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Monitorar Logs em Tempo Real

```bash
# Todos os serviços
docker-compose logs -f

# Lighthouse específico
docker logs lighthouse -f

# Geth específico
docker logs geth -f
```

### Verificar Conectividade da API

```bash
# Geth RPC
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545

# Lighthouse API
curl -s http://localhost:5052/eth/v1/node/health
```

### Verificar Status de Sincronização

```bash
# Via script de monitoramento
./monitor-holesky.sh

# Via Rocket Pool CLI
docker exec rocketpool-node-holesky rocketpool api node sync
```

## Conclusão

O estado atual mostra um sistema saudável e funcional com ambos os clients trabalhando juntos adequadamente. O erro foi transitório e relacionado ao ciclo de reinicializações do Lighthouse, não a um problema fundamental de configuração.

### Indicadores de Sistema Saudável

- ✅ Geth sincronizando consistentemente
- ✅ Lighthouse executando sem erros de engine API
- ✅ Comunicação entre containers funcionando
- ✅ JWT secret configurado corretamente
- ✅ Portas e endpoints acessíveis

### Monitoramento Contínuo

- Verificar uso de recursos semanalmente
- Monitorar logs para padrões de erro
- Acompanhar progresso de sincronização
- Validar conectividade de rede regularmente

---

*Documento criado em: 6 de julho de 2025*  
*Última atualização: 6 de julho de 2025*

# Scripts de Monitoramento

Scripts para monitorar o status, sincronização e saúde do ambiente Rocket Pool Holesky.

## Scripts Disponíveis

### `monitor-holesky.sh` - Monitor Principal

Mais completo e recomendado.

- Status completo de todos os containers
- Progresso de sincronização com ETA
- Uso de recursos (CPU, memória, disco)
- Conectividade de rede
- Comandos úteis integrados

```bash
./scripts/monitoring/monitor-holesky.sh
```

### `monitor-simple.sh` - Monitor Simples

Rápido e direto.

- Status básico dos containers
- Progresso de sincronização
- Informações essenciais

```bash
./scripts/monitoring/monitor-simple.sh
```

### `monitor-complete-status.sh` - Status Detalhado

Análise profunda.

- Análise detalhada de recursos
- Métricas avançadas
- Diagnóstico de problemas

```bash
./scripts/monitoring/monitor-complete-status.sh
```

### `monitor-ssd.sh` - Monitor SSD

Para configurações com SSD externo.

- Monitoramento específico para SSD
- Métricas de armazenamento
- Performance do disco

```bash
./scripts/monitoring/monitor-ssd.sh
```

## Uso Regular

### Monitoramento Contínuo

```bash
# Executar a cada 30 segundos
watch -n 30 ./scripts/monitoring/monitor-holesky.sh

# Executar uma vez e sair
./scripts/monitoring/monitor-simple.sh
```

### Integração com Cron

```bash
# Adicionar ao crontab para monitoramento automático
# Executar a cada 5 minutos e salvar log
*/5 * * * * /path/to/scripts/monitoring/monitor-holesky.sh >> /var/log/rocketpool-monitor.log 2>&1
```

## Métricas Monitoradas

### Containers

- Status (Up/Down)
- Tempo de execução
- Uso de recursos

### Sincronização

- Progresso do Geth
- Status do Lighthouse
- ETA para sincronização completa

### Recursos

- CPU Load Average
- Memória do sistema
- Uso de disco
- Conectividade de rede

### Rocket Pool

- Status do node
- Versão do CLI
- Status da wallet

## Alertas e Diagnóstico

Os scripts identificam automaticamente:

- Containers parados
- Problemas de sincronização
- Alto uso de recursos
- Problemas de conectividade
- Erros de configuração

## Personalização

Para personalizar os scripts:

1. Faça uma cópia do script
2. Modifique as variáveis no topo
3. Adicione suas próprias verificações
4. Mantenha a estrutura de output

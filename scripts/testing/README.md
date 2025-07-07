# Scripts de Teste

Scripts para testar e validar o funcionamento do ambiente Rocket Pool Holesky.

## Scripts Disponíveis

### `test-simple-holesky.sh` - Teste Simples

Testes básicos de funcionamento

- Verificação de containers
- Teste de conectividade
- Validação de APIs

```bash
./scripts/testing/test-simple-holesky.sh
```

### `test-dashboards-holesky.sh` - Teste de Dashboards

Testes específicos do Grafana

- Validação de dashboards
- Teste de métricas
- Verificação de datasources

```bash
./scripts/testing/test-dashboards-holesky.sh
```

## 🔬 Tipos de Teste

### Testes de Conectividade

- Ping para containers
- Teste de portas
- Verificação de APIs

### Testes de Funcionalidade

- Sincronização
- Métricas
- Logs

### Testes de Performance

- Uso de recursos
- Latência
- Throughput

## Execução

### Teste Completo

```bash
# Executar todos os testes
./scripts/testing/test-simple-holesky.sh
./scripts/testing/test-dashboards-holesky.sh
```

### Teste Específico

```bash
# Apenas teste de conectividade
./scripts/testing/test-simple-holesky.sh --connectivity

# Apenas teste de dashboards
./scripts/testing/test-dashboards-holesky.sh --dashboards
```

## Relatórios

Os testes geram relatórios detalhados:

- Status de cada verificação
- Tempos de resposta
- Erros encontrados
- Recomendações

## Personalização

### Adicionar Novos Testes

```bash
# Criar novo teste
cp test-simple-holesky.sh test-custom.sh

# Personalizar verificações
nano test-custom.sh
```

### Configurar Alertas

```bash
# Integrar com monitoramento
./scripts/testing/test-simple-holesky.sh | mail -s "Teste Holesky" admin@example.com
```

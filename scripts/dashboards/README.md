# Scripts de Dashboards

Scripts para gestão, importação e manutenção dos dashboards do Grafana.

## Scripts Disponíveis

### `import-recommended-dashboards.sh` - Importar Dashboards

Importa dashboards recomendados para o Grafana

- Importação automática
- Correção de datasources
- Validação de imports

```bash
./scripts/dashboards/import-recommended-dashboards.sh
```

### `download-dashboards.sh` - Download via API

Baixa dashboards usando a API do Grafana

- Download via API
- Múltiplos dashboards
- Organização automática

```bash
./scripts/dashboards/download-dashboards.sh
```

### `download-dashboards-curl.sh` - Download via cURL

Baixa dashboards usando cURL

- Download direto
- Sem dependências
- Configuração manual

```bash
./scripts/dashboards/download-dashboards-curl.sh
```

### `fix-dashboard-containers.sh` - Corrigir Containers

Corrige nomes de containers nos dashboards

- Correção automática
- Nomes padronizados
- Atualização de queries

```bash
./scripts/dashboards/fix-dashboard-containers.sh
```

## 📦 Dashboards Disponíveis

### Principais

- **Lighthouse Summary** - Visão geral do consensus
- **Geth Dashboard** - Métricas do execution client
- **Docker Host Container Overview** - Containers
- **Home Staking Dashboard** - Staking doméstico

### Específicos

- **Lighthouse Validator Client** - Cliente validador
- **Lighthouse Validator Monitor** - Monitor avançado
- **Ethereum Metrics Exporter** - Métricas extras

## Uso Comum

### Importação Inicial

```bash
# Importar todos os dashboards recomendados
./scripts/dashboards/import-recommended-dashboards.sh

# Verificar importação
curl -s "http://admin:admin@localhost:3000/api/search?query=&"
```

### Atualização de Dashboards

```bash
# Baixar novas versões
./scripts/dashboards/download-dashboards.sh

# Corrigir nomes se necessário
./scripts/dashboards/fix-dashboard-containers.sh
```

### Backup e Restore

```bash
# Backup de dashboards
./scripts/dashboards/download-dashboards.sh

# Restore após problema
./scripts/dashboards/import-recommended-dashboards.sh
```

## 🛠️ Personalização

### Adicionar Novos Dashboards

```bash
# Editar lista de dashboards
nano scripts/dashboards/import-recommended-dashboards.sh

# Adicionar novo dashboard
# DASHBOARD_IDS="1860 7587 13865 ..."
```

### Configurar Datasources

```bash
# Verificar datasources
curl -s "http://admin:admin@localhost:3000/api/datasources"

# Corrigir se necessário
./scripts/dashboards/fix-dashboard-containers.sh
```

## Métricas dos Dashboards

### Execution Client (Geth)

- Sync status
- Peers
- Chain data
- Performance

### Consensus Client (Lighthouse)

- Validator status
- Beacon chain
- Attestations
- Rewards

### Sistema

- Container resources
- Host metrics
- Network stats
- Disk usage

## Troubleshooting

### Problemas Comuns

- Dashboards não carregam
- Métricas não aparecem
- Datasources incorretos
- Permissões do Grafana

### Soluções

```bash
# Verificar Grafana
docker logs grafana-holesky

# Verificar Prometheus
curl -s "http://localhost:9090/api/v1/targets"

# Recriar dashboards
./scripts/dashboards/import-recommended-dashboards.sh
```

## Automação

### Backup Automático

```bash
# Cron job para backup diário
0 2 * * * /path/to/scripts/dashboards/download-dashboards.sh > backup.log 2>&1
```

### Monitoramento

```bash
# Verificar se dashboards estão funcionando
curl -s "http://admin:admin@localhost:3000/api/health"
```

---

Categoria: Dashboards e Visualização

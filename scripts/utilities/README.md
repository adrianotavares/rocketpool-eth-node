# Scripts Utilitários

Scripts de apoio e utilitários diversos para o ambiente Rocket Pool Holesky.

## Scripts Disponíveis

### `status-holesky.sh` - Status Rápido

Verificação rápida do status

- Status dos containers
- Informações básicas
- Verificação rápida

```bash
./scripts/utilities/status-holesky.sh
```

### `verify-wallet.sh` - Verificação de Wallet

Verificação da configuração da wallet

- Status da wallet
- Verificação de chaves
- Validação de configuração

```bash
./scripts/utilities/verify-wallet.sh
```

### `show-dashboard-structure.sh` - Estrutura de Dashboards

Exibe a estrutura dos dashboards

- Lista de dashboards
- Estrutura dos arquivos
- Informações de configuração

```bash
./scripts/utilities/show-dashboard-structure.sh
```

## 🛠️ Utilitários Comuns

### Verificações Rápidas

```bash
# Status geral
./scripts/utilities/status-holesky.sh

# Verificar wallet
./scripts/utilities/verify-wallet.sh

# Ver dashboards
./scripts/utilities/show-dashboard-structure.sh
```

### Informações do Sistema

```bash
# Verificar recursos
docker stats --no-stream

# Ver logs recentes
docker logs geth --tail 50
docker logs lighthouse --tail 50
```

## Casos de Uso

### Diagnóstico Rápido

- Verificar se tudo está funcionando
- Identificar problemas básicos
- Obter informações essenciais

### Manutenção

- Verificação pós-atualização
- Validação de configurações
- Limpeza de dados

### Troubleshooting

- Primeira verificação
- Coleta de informações
- Diagnóstico inicial

## Informações Coletadas

### Sistema

- Status dos containers
- Uso de recursos
- Conectividade

### Configuração

- Variáveis de ambiente
- Arquivos de configuração
- Permissões

### Wallet e Chaves

- Status da wallet
- Chaves disponíveis
- Configuração do validador

## Automação

### Scripts de Manutenção

```bash
# Verificação diária
./scripts/utilities/status-holesky.sh > daily-status.log

# Verificação semanal da wallet
./scripts/utilities/verify-wallet.sh > weekly-wallet.log
```

### Integração

```bash
# Usar em outros scripts
source scripts/utilities/status-holesky.sh
check_container_status "geth"
```

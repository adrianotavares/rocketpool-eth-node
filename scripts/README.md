# Scripts do Rocket Pool Holesky

Este diretório contém todos os scripts organizados por categoria para facilitar a gestão e manutenção do ambiente Rocket Pool Holesky.

## Estrutura dos Scripts

```text
scripts/
├── README.md                 # Este arquivo
├── monitoring/               # Scripts de monitoramento
│   ├── README.md            # Guia de monitoramento
│   ├── monitor-holesky.sh   # Monitor principal Holesky
│   ├── monitor-simple.sh    # Monitor simples
│   ├── monitor-complete-status.sh
│   └── monitor-ssd.sh
├── setup/                   # Scripts de configuração inicial
│   ├── README.md            # Guia de setup
│   ├── setup-holesky.sh     # Setup Holesky
│   ├── setup-ssd.sh         # Setup SSD
│   └── setup-external-ssd.sh
├── testing/                 # Scripts de teste
│   ├── README.md            # Guia de testes
│   ├── test-simple-holesky.sh
│   └── test-dashboards-holesky.sh
├── utilities/               # Utilitários diversos
│   ├── README.md            # Utilitários diversos
│   ├── status-holesky.sh
│   ├── verify-wallet.sh
│   └── show-dashboard-structure.sh
└── dashboards/              # Gestão de dashboards
    ├── README.md            # Gestão de dashboards
    ├── download-dashboards.sh
    ├── download-dashboards-curl.sh
    ├── fix-dashboard-containers.sh
    └── import-recommended-dashboards.sh
```

## Scripts Mais Usados

### Monitoramento

```bash
# Monitor principal (recomendado)
./scripts/monitoring/monitor-holesky.sh

# Monitor simples
./scripts/monitoring/monitor-simple.sh

# Status completo
./scripts/monitoring/monitor-complete-status.sh
```

### Setup e Configuração

```bash
# Setup inicial do Holesky
./scripts/setup/setup-holesky.sh

# Setup com SSD externo
./scripts/setup/setup-external-ssd.sh
```

### Dashboards

```bash
# Importar dashboards recomendados
./scripts/dashboards/import-recommended-dashboards.sh

# Baixar dashboards
./scripts/dashboards/download-dashboards.sh
```

## Compatibilidade

Para manter a compatibilidade com comandos existentes, links simbólicos foram criados na raiz do projeto:

```bash
# Estes comandos continuam funcionando:
./monitor-holesky.sh        # -> scripts/monitoring/monitor-holesky.sh
./monitor-simple.sh         # -> scripts/monitoring/monitor-simple.sh
./setup-holesky.sh          # -> scripts/setup/setup-holesky.sh
```

## Contribuindo

Ao adicionar novos scripts:

1. Escolha a categoria apropriada (ou crie uma nova se necessário)
2. Adicione documentação no README da categoria
3. Use nomes descritivos para os arquivos
4. Inclua cabeçalho com descrição e uso
5. Torne o script executável: `chmod +x script.sh`

## Convenções

- **Nomes**: Use kebab-case (ex: `monitor-holesky.sh`)
- **Cabeçalhos**: Inclua descrição, autor e data
- **Documentação**: Cada categoria tem seu próprio README
- **Executabilidade**: Todos os scripts devem ser executáveis

## Busca Rápida

Para encontrar um script específico:

```bash
# Buscar por nome
find scripts/ -name "*holesky*" -type f

# Buscar por conteúdo
grep -r "docker-compose" scripts/

# Listar todos os scripts
find scripts/ -name "*.sh" -type f
```

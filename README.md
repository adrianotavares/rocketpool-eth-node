# Rocket Pool Ethereum Node com Monitoramento

Este projeto configura um nó Ethereum completo com Rocket Pool, incluindo cliente de execução (Geth), cliente de consenso (Lighthouse) e monitoramento via Prometheus e Grafana, com autenticação JWT.

## Estrutura do Projeto

```text
rocketpool-eth-node/
├── alerts/
│   └── node-alerts.yml          # Alertas do Prometheus
├── consensus-data/              # Dados do Lighthouse
├── execution-data/              # Dados do Geth (inclui JWT secret)
├── grafana/
│   ├── dashboards/
│   │   ├── rocketpool-node.json # Dashboard Rocket Pool
│   │   └── ethereum-node.json   # Dashboard Ethereum
│   └── provisioning/
│       └── dashboards/
│           └── dashboards.yml   # Configuração dos dashboards
├── rocketpool-data/             # Dados do Rocket Pool
├── docker-compose.yml           # Configuração original
├── docker-compose.ssd.yml       # Configuração para SSD externo
├── .env.ssd                     # Variáveis de ambiente SSD
├── setup-ssd.sh                 # Script de configuração SSD
├── monitor-ssd.sh               # Script de monitoramento SSD
├── SSD-CONFIG.md                # Documentação SSD detalhada
├── QUICK-START-SSD.md           # Guia rápido SSD
├── ethereum-dashboard-import.json 
├── prometheus.yml               # Configuração do Prometheus
└── README.md
```

## Configuração Padrão vs SSD Externo

### Configuração Padrão (Original)

- Dados armazenados localmente no diretório do projeto
- Use: `docker-compose up -d`

### Configuração SSD Externo (Recomendado)

- Dados armazenados em SSD externo de 1TB+
- Use: `./setup-ssd.sh` seguido de `docker-compose -f docker-compose.ssd.yml --env-file .env.ssd up -d`
- **Vantagens**: Mais espaço, melhor performance, portabilidade
- **Documentação**: Veja [SSD-CONFIG.md](SSD-CONFIG.md) e [QUICK-START-SSD.md](QUICK-START-SSD.md)

## Pré-requisitos

- Docker e Docker Compose instalados
- **Para SSD Externo**: SSD externo de 1TB+ (recomendado)
- **Para configuração padrão**: Pelo menos 1TB de espaço livre em disco
- 16GB+ de RAM (32GB recomendado)
- Conexão estável à internet
- Portas abertas no firewall:
  - `30303` - P2P Geth (TCP/UDP)
  - `9000` - P2P Lighthouse (TCP/UDP)
  - `8545` - RPC HTTP Geth
  - `8551` - RPC autenticado Geth (JWT)
  - `9090` - Prometheus
  - `3000` - Grafana
  - `8000` - Rocket Pool (se necessário)

## Como Executar

### Início Rápido

```bash
docker-compose up -d
```

### Passo a Passo Detalhado

1. Clone este repositório:

   ```bash
   git clone https://github.com/seu-usuario/rocketpool-eth-node.git
   cd rocketpool-eth-node
   ```

2. Configure os volumes e as portas conforme necessário no `docker-compose.yml` (se necessário).

3. Inicie os contêineres:

   ```bash
   docker-compose up -d
   ```

4. Acompanhe os logs:

   ```bash
   docker-compose logs -f
   ```

5. Verifique o status dos contêineres:

   ```bash
   docker ps
   ```

## Acessando os Serviços

### Interfaces Web

- **Grafana**: <http://localhost:3000>
  - Usuário: `admin`
  - Senha: `admin`
  - Dashboards pré-configurados para Ethereum e Rocket Pool

- **Prometheus**: <http://localhost:9090>
  - Interface para consultar métricas e verificar alertas

### APIs e RPC

- **Geth RPC**: <http://localhost:8545>
  - Endpoint HTTP para interação com o cliente de execução

```bash
# Teste de conectividade
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
  http://localhost:8545
```

## Arquitetura e Componentes

### Cliente de Execução (Geth)

- **Imagem**: `ethereum/client-go:stable`
- **Modo de Sincronização**: Snap sync
- **JWT Authentication**: Configurado para comunicação segura
- **Portas**: 30303 (P2P), 8545 (HTTP RPC), 8551 (Auth RPC)

### Cliente de Consenso (Lighthouse)

- **Imagem**: `sigp/lighthouse:latest`
- **Checkpoint Sync**: Habilitado para sincronização rápida
- **JWT Authentication**: Conectado ao Geth via porta 8551
- **Portas**: 9000 (P2P)

### Rocket Pool

- **Imagem**: `rocketpool/smartnode:latest`
- **Dependências**: Aguarda Geth e Lighthouse estarem prontos
- **Configuração**: Arquivo de configuração será criado na primeira execução

### Monitoramento

- **Prometheus**: Coleta métricas de todos os clientes
- **Grafana**: Visualização e dashboards
- **Alertas**: Configurados para cenários críticos

## Monitoramento e Alertas

### Métricas Coletadas

- **Prometheus** coleta métricas de todos os clientes automaticamente
- **Grafana** apresenta dashboards pré-configurados para:
  - Ethereum node (Geth e Lighthouse)
  - Rocket Pool específico
  - Saúde dos contêineres

### Alertas Configurados

- Queda do Execution Client
- Falha no Consensus Client  
- Validador offline
- Baixa performance do node

## Comandos Úteis

### Gerenciamento dos Contêineres

```bash
# Iniciar todos os serviços
docker-compose up -d

# Parar todos os serviços
docker-compose down

# Ver logs em tempo real
docker-compose logs -f

# Ver logs de um serviço específico
docker-compose logs -f execution-client
docker-compose logs -f consensus-client
docker-compose logs -f rocketpool-node

# Reiniciar um serviço específico
docker-compose restart consensus-client

# Ver status dos contêineres
docker ps
```

### Verificação de Saúde

```bash
# Verificar se Geth está respondendo
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
  http://localhost:8545

# Verificar peers conectados
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  http://localhost:8545

# Verificar status de sincronização
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545
```

## Importante - JWT Authentication

Este setup implementa corretamente a autenticação JWT entre os clientes:

- **Geth** gera automaticamente o JWT secret em `/root/.ethereum/jwtsecret`
- **Lighthouse** usa o mesmo JWT token para comunicação segura
- **Porta 8551** é usada para comunicação autenticada (não HTTP público)
- **Porta 8545** continua disponível para RPC HTTP público

## Processo de Sincronização

### Primeira Execução

1. **Geth** iniciará o download da blockchain (pode levar várias horas)
2. **Lighthouse** usará checkpoint sync para sincronização rápida
3. **Rocket Pool** aguardará ambos os clientes estarem sincronizados

### Tempos Estimados

- **Checkpoint Sync (Lighthouse)**: 5-15 minutos
- **Snap Sync (Geth)**: 2-6 horas (dependendo do hardware e internet)
- **Sincronização completa**: 4-8 horas

## Configuração Completa do Node e Dashboards

### Passo 1: Inicialização dos Clientes

```bash
# 1. Iniciar todos os serviços
docker-compose up -d

# 2. Verificar status dos contêineres
docker ps

# 3. Acompanhar logs em tempo real
docker-compose logs -f
```

### Passo 2: Verificar Sincronização

```bash
# Verificar sincronização do Geth
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545

# Verificar peers conectados
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  http://localhost:8545

# Verificar status do Lighthouse
docker logs --tail=20 consensus-client
```

### Passo 3: Configurar Rocket Pool

1. **Aguardar Sincronização**: Espere Geth e Lighthouse sincronizarem (pode levar algumas horas)

2. **Configurar Rocket Pool**:

   ```bash
   # Parar o Rocket Pool temporariamente
   docker stop rocketpool-node

   # Criar configuração básica
   mkdir -p rocketpool-data/.rocketpool

   # O arquivo user-settings.yml já está criado automaticamente
   ```

3. **Iniciar Rocket Pool**:

   ```bash
   docker start rocketpool-node
   ```

### Passo 4: Configurar Dashboards do Grafana

1. **Acessar Grafana**: <http://localhost:3000>
   - Usuário: `admin`
   - Senha: `admin`

2. **Adicionar Prometheus como Data Source**:
   - Vá em Configuration > Data Sources
   - Clique em "Add data source"
   - Selecione "Prometheus"
   - URL: `http://prometheus:9090`
   - Clique em "Save & Test"

3. **Importar Dashboards**:
   - Vá em "+" > Import
   - Upload dos arquivos JSON da pasta `grafana/dashboards/`
   - Ou usar IDs dos dashboards da comunidade:
     - **Geth Dashboard**: ID `6976`
     - **Lighthouse Dashboard**: ID `13759`
     - **Node Exporter**: ID `1860`

### Passo 5: Monitoramento de Métricas

Após a sincronização completa, as seguintes métricas estarão disponíveis:

**Geth (Execution Client)**:

- URL: <http://localhost:6060/debug/metrics/prometheus>
- Métricas: blocos, peers, memória, CPU, transações

**Lighthouse (Consensus Client)**:

- URL: <http://localhost:5054/metrics>
- Métricas: validadores, slots, attestations, sincronização

**Prometheus**:

- URL: <http://localhost:9090>
- Interface para consultar métricas diretamente

### Passo 6: Comandos de Verificação

```bash
# Status dos contêineres
docker ps

# Logs específicos
docker logs execution-client
docker logs consensus-client
docker logs rocketpool-node
docker logs prometheus
docker logs grafana

# Verificar métricas do Prometheus
curl -s http://localhost:9090/api/v1/targets

# Testar conectividade RPC
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
  http://localhost:8545
```

### Passo 7: Configuração Avançada

**Personalizar Alertas**:

```bash
# Editar alertas personalizados
nano alerts/node-alerts.yml
```

**Configurar Backup Automático**:

```bash
# Script de backup dos dados importantes
tar -czf backup-$(date +%Y%m%d).tar.gz \
  execution-data/geth/keystore \
  consensus-data/mainnet/beacon/validator_db \
  rocketpool-data/.rocketpool
```

**Otimização de Performance**:

- Use SSD para armazenamento
- Mínimo 16GB RAM (32GB recomendado)
- Conexão de internet estável (100Mbps+)

### Tempos Estimados de Sincronização

| Componente | Tempo Estimado | Observações |
|------------|----------------|-------------|
| **Lighthouse** | 5-15 minutos | Checkpoint sync ativo |
| **Geth** | 2-6 horas | Snap sync, depende do hardware |
| **Rocket Pool** | Após sincronização | Aguarda clientes prontos |

### Resolução de Problemas Comuns

**Problema**: Lighthouse não conecta ao Geth

```bash
# Verificar JWT token
cat execution-data/geth/jwtsecret
docker logs consensus-client | grep -i jwt
```

**Problema**: Métricas não aparecem no Grafana

```bash
# Verificar targets do Prometheus
curl -s http://localhost:9090/api/v1/targets

# Reiniciar serviços de monitoramento
docker-compose restart prometheus grafana
```

**Problema**: Rocket Pool reiniciando constantemente

```bash
# Verificar configuração
cat rocketpool-data/.rocketpool/user-settings.yml
docker logs rocketpool-node
```

## Tutoriais e Recursos Online

### Tutoriais Oficiais

#### Documentação Oficial dos Clientes

- **[Rocket Pool - Guia Oficial de Node](https://docs.rocketpool.net/guides/node/local/overview.html)**
  - Setup completo de node Rocket Pool
  - Configuração de hardware recomendado
  - Processo de instalação passo a passo

- **[Geth - Getting Started](https://geth.ethereum.org/docs/getting-started)**
  - Tutorial oficial do cliente Geth
  - Configuração de contas e wallets
  - Sincronização e operação básica

- **[Lighthouse - Documentation](https://lighthouse.gitbook.io/lighthouse/)**
  - Guia completo do cliente Lighthouse
  - Configuração de validadores
  - Monitoramento e manutenção

#### Monitoramento e Dashboards

- **[Grafana Dashboard - Geth](https://grafana.com/grafana/dashboards/6976)**
  - Dashboard oficial para monitoramento do Geth
  - Métricas de performance e sincronização

- **[Grafana Dashboard - Lighthouse](https://grafana.com/grafana/dashboards/13759)**
  - Dashboard para cliente de consenso Lighthouse
  - Métricas de validadores e attestations

### Tutoriais da Comunidade

#### YouTube Channels

- **[CoinCashew - Ethereum Staking Guides](https://www.youtube.com/@CoinCashew)**
  - Tutoriais detalhados de setup de nodes
  - Configuração de hardware e software
  - Troubleshooting comum

- **[EthStaker Community](https://www.youtube.com/@EthStaker)**
  - Webinars sobre staking
  - Discussões técnicas avançadas
  - Updates de protocolo

#### Guias Escritos

- **[CoinCashew Written Guides](https://www.coincashew.com/coins/overview-eth/guide-or-how-to-setup-a-validator-on-eth2-mainnet)**
  - Guias completos de setup
  - Configurações de segurança
  - Melhores práticas

- **[Somer Esat Guides](https://someresat.medium.com/)**
  - Tutoriais detalhados no Medium
  - Setup de diferentes clientes
  - Configuração de monitoramento

### Ferramentas e Recursos Técnicos

#### Ferramentas de Monitoramento

- **[Beaconcha.in](https://beaconcha.in/)**
  - Explorer da Beacon Chain
  - Monitoramento de validadores
  - Estatísticas da rede

- **[Rated Network](https://www.rated.network/)**
  - Análise de performance de validadores
  - Comparativo entre operadores
  - Métricas avançadas

#### Calculadoras e Simuladores

- **[Rocket Pool Calculator](https://www.rp-metrics-dashboard.com/dashboard/MAINNET)**
  - Calculadora de recompensas
  - Métricas do protocolo
  - Dashboard de RPL staking

- **[Ethereum Staking Calculator](https://www.stakingrewards.com/earn/ethereum-2-0/calculate)**
  - Calculadora de recompensas ETH 2.0
  - Simulação de diferentes cenários
  - ROI estimado

### Tutoriais Específicos para Este Projeto

#### Docker Compose + Ethereum

- **[Ethereum Node with Docker](https://ethereum.org/en/developers/tutorials/run-node-raspberry-pi/)**
  - Setup usando Docker
  - Configuração em Raspberry Pi
  - Otimizações de performance

- **[Docker Ethereum Stack](https://github.com/eth-educators/ethstaker-guides)**
  - Repositório com múltiplos guias
  - Configurações Docker avançadas
  - Scripts de automação

#### Prometheus + Grafana

- **[Prometheus Documentation](https://prometheus.io/docs/)**
  - Setup de monitoramento completo
  - Configuração de coleta de métricas
  - Criação de alertas personalizados

- **[Grafana Dashboards](https://grafana.com/grafana/dashboards/)**
  - Dashboards prontos para Ethereum
  - Templates para monitoramento de nodes
  - Personalização de visualizações

### Recursos Avançados

#### Segurança e Hardening

- **[Ethereum Node Security Guide](https://ethereum.org/en/developers/docs/nodes-and-clients/run-a-node/)**
  - Práticas de segurança
  - Configuração de firewall
  - Backup e recuperação

#### Performance e Otimização

- **[Ethereum Client Comparison](https://clientdiversity.org/)**
  - Comparativo entre clientes
  - Benchmarks de performance
  - Diversidade de clientes

### Comunidades e Suporte

#### Discord Communities

- **[Rocket Pool Discord](https://discord.gg/rocketpool)**
  - Suporte oficial da comunidade
  - Canais técnicos especializados
  - Anúncios importantes

- **[EthStaker Discord](https://discord.gg/ethstaker)**
  - Maior comunidade de staking Ethereum
  - Canais por cliente (Geth, Lighthouse, etc.)
  - Suporte técnico 24/7

#### Reddit Communities

- **[r/ethstaker](https://reddit.com/r/ethstaker)**
  - Discussões técnicas
  - Troubleshooting
  - Novidades do ecossistema

### Documentação Técnica Avançada

#### Ethereum Protocol

- **[Ethereum Improvement Proposals (EIPs)](https://eips.ethereum.org/)**
  - Especificações técnicas do protocolo
  - Propostas de melhorias
  - Roadmap de desenvolvimento

#### Consensus Layer

- **[Ethereum 2.0 Specs](https://github.com/ethereum/consensus-specs)**
  - Especificações técnicas da Beacon Chain
  - Implementações de referência
  - Testes e validação

### Troubleshooting e FAQ

#### Common Issues

- **[EthStaker Documentation](https://docs.ethstaker.cc/)**
  - Problemas mais comuns
  - Soluções step-by-step
  - Dicas de performance

- **[Rocket Pool Troubleshooting](https://docs.rocketpool.net/guides/node/faq)**
  - FAQ oficial do Rocket Pool
  - Problemas específicos do protocolo
  - Soluções da comunidade

### Vídeo Tutoriais

#### Tutoriais em Português

- **[Node Ethereum - Setup Completo](https://www.youtube.com/results?search_query=ethereum+node+setup+português)**
  - Busque por "ethereum node setup português" no YouTube
  - Tutoriais de configuração completa de nodes

- **[Rocket Pool Brasil](https://www.youtube.com/results?search_query=rocket+pool+tutorial+português)**
  - Busque por "rocket pool tutorial português"
  - Comunidade brasileira de staking

#### Tutoriais em Inglês

- **[CoinCashew Ethereum Guides](https://www.youtube.com/results?search_query=coincashew+ethereum+staking)**
  - Tutoriais detalhados de setup de nodes
  - Configuração de hardware e software

- **[EthStaker Community](https://www.youtube.com/results?search_query=ethstaker+node+setup)**
  - Webinars sobre staking
  - Discussões técnicas avançadas

#### Tópicos Específicos Recomendados

1. **"Ethereum Node Docker Setup 2024"** - Configuração com containers
2. **"Rocket Pool Complete Guide"** - Setup passo a passo
3. **"Grafana Dashboard Ethereum"** - Monitoramento avançado
4. **"Docker Compose Blockchain"** - Orquestração de serviços

### Apps e Ferramentas Mobile

- **[Rocket Pool Website](https://rocketpool.net/)**
  - Informações oficiais do protocolo
  - Documentação e recursos
  - Links para dashboards

- **[Beaconcha.in Explorer](https://beaconcha.in/)**
  - Monitor de validadores via web
  - Estatísticas da rede Ethereum
  - Notificações de performance (via site)

## Contribuição

Contribuições são bem-vindas! Por favor:

1. Faça fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## CONFIGURAÇÃO SSD CONCLUÍDA COM SUCESSO

**Data da Conclusão**: 28 de Junho de 2025  
**Status**: OPERACIONAL

### Validação Completa Realizada

A configuração do Rocket Pool Ethereum Node no SSD externo Kingston 1TB foi **concluída com sucesso** e está totalmente funcional:

- **Execution Client (Geth)**: Sincronizando com a rede Ethereum
- **Consensus Client (Lighthouse)**: Conectado e funcionando  
- **Monitoramento**: Prometheus + Grafana operacionais
- **Armazenamento**: Todos os dados gravados no SSD (~500MB utilizados de 1TB)
- **Scripts**: Setup e monitoramento funcionais

### Arquivos de Configuração SSD Criados

```txt
SSD-CONFIG.md          # Documentação técnica completa
QUICK-START-SSD.md     # Guia rápido de uso  
STATUS-FINAL-SSD.md    # Relatório final detalhado
docker-compose.ssd.yml # Compose específico para SSD
.env.ssd              # Variáveis de ambiente SSD
setup-ssd.sh          # Script de configuração automática
monitor-ssd.sh        # Script de monitoramento
```

### Como Usar

```bash
# Iniciar sistema completo no SSD
docker-compose -f docker-compose.ssd.yml --env-file .env.ssd up -d

# Monitorar status
./monitor-ssd.sh

# Acessar dashboards
open http://localhost:3000  # Grafana (admin/admin)
open http://localhost:9090  # Prometheus
```

### Status Atual

- **Espaço SSD**: 724GB livres (75% disponível)
- **Containers**: 5/5 funcionando (Rocket Pool temporariamente desabilitado)
- **Sincronização**: Em progresso
- **Monitoramento**: Ativo e coletando métricas

Para detalhes completos, consulte `STATUS-FINAL-SSD.md`.

---

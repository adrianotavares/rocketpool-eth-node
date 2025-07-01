# Configuração do Rocket Pool - Modo Híbrido

## Arquivos de Configuração

### Arquivo Ativo

- **Localização**: `/Volumes/KINGSTON/ethereum-data/rocketpool-data/user-settings.yml`
- **Descrição**: Configuração atual em uso pelo Rocket Pool
- **Status**: Funcionando corretamente

### Template de Referência

- **Localização**: `./rocketpool-data/user-settings.template.yml`
- **Descrição**: Template documentado para referência e backup

## Configuração Atual

```yaml
root:
  version: "1.16.0"
  network: "mainnet"
  isNative: "false"
  executionClientMode: "external"
  consensusClientMode: "external"
  externalExecutionHttpUrl: "http://execution-client:8545"
  externalExecutionWsUrl: "ws://execution-client:8546"
  externalConsensusHttpUrl: "http://consensus-client:5052"
```

## Modo Híbrido (External Clients)

O Rocket Pool está configurado para usar clientes externos:

- **Execution Client**: Geth (container: `execution-client`)
- **Consensus Client**: Lighthouse (container: `consensus-client`)
- **Rocket Pool Node**: Container gerenciado (`rocketpool-node`)

## Estrutura de Diretórios

```text
/Volumes/KINGSTON/ethereum-data/
├── execution-data/                 # Dados do Geth
├── consensus-data/                 # Dados do Lighthouse  
├── rocketpool-data/                # Dados do Rocket Pool
│   ├── user-settings.yml           # Configuração ativa
│   └── user-settings.template.yml  # Template de referência
│   └── .rocketpool-data/
│       └── user-settings.yml 
├── prometheus-data/                # Dados do Prometheus
└── grafana-data/                   # Dados do Grafana
```

## Comandos Úteis

```bash
# Verificar status dos containers
docker-compose -f docker-compose.ssd.yml --env-file .env.ssd ps

# Verificar logs do Rocket Pool
docker logs rocketpool-node

# Verificar status de sincronização
docker exec rocketpool-node rocketpool api node sync

# Iniciar todos os serviços
docker-compose -f docker-compose.ssd.yml --env-file .env.ssd up -d

# Parar todos os serviços
docker-compose -f docker-compose.ssd.yml --env-file .env.ssd down
```

## Próximos Passos

1. **Configurar wallet**: `docker exec -it rocketpool-node rocketpool wallet init`
2. **Aguardar sincronização** dos clientes de execução e consenso
3. **Configurar nó**: Seguir documentação oficial do Rocket Pool
4. **Monitoramento**: Acessar Grafana em `http://localhost:3000`

## Troubleshooting

- **"Settings file not found"**: Verificar se o arquivo existe em `/Volumes/KINGSTON/ethereum-data/rocketpool-data/user-settings.yml`
- **"cannot unmarshal"**: Verificar syntax YAML do arquivo de configuração  
- **"dial unix: missing address"**: Verificar se os containers de clientes estão rodando
- **"node password not set"**: Executar `rocketpool wallet init`

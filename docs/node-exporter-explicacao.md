# Node Exporter - Explicação Detalhada

## O que é o Node Exporter?

O **Node Exporter** é um exportador de métricas do sistema desenvolvido pela equipe do Prometheus. Ele é um componente fundamental do sistema de monitoramento do ambiente Rocket Pool, responsável por coletar métricas detalhadas sobre o sistema operacional e hardware da máquina onde está rodando.

## Função Principal

O container `node-exporter-holesky` coleta métricas detalhadas do sistema operacional e hardware, expondo-as em formato Prometheus na porta `9100`. Essas métricas são então coletadas pelo Prometheus e visualizadas no Grafana.

## Métricas Coletadas

### Sistema

- `node_cpu_seconds_total` - Uso de CPU por core
- `node_memory_MemAvailable_bytes` - Memória disponível
- `node_filesystem_free_bytes` - Espaço livre em disco
- `node_load1`, `node_load5`, `node_load15` - Load average do sistema
- `node_uptime_seconds` - Tempo de atividade do sistema

### Rede

- `node_network_receive_bytes_total` - Total de bytes recebidos
- `node_network_transmit_bytes_total` - Total de bytes transmitidos
- `node_network_up` - Status das interfaces de rede
- `node_network_info` - Informações das interfaces

### Disco

- `node_disk_io_time_seconds_total` - Tempo de I/O do disco
- `node_disk_reads_completed_total` - Leituras completadas
- `node_disk_writes_completed_total` - Escritas completadas
- `node_disk_read_bytes_total` - Bytes lidos do disco
- `node_disk_written_bytes_total` - Bytes escritos no disco

### Temperatura e Hardware

- `node_hwmon_temp_celsius` - Temperatura dos componentes
- `node_thermal_zone_temp` - Temperatura das zonas térmicas
- `node_power_supply_info` - Informações da fonte de alimentação

## 🔗 Integração no Ambiente Rocket Pool

### Arquitetura de Monitoramento

```text
Node Exporter (9100) → Prometheus (9090) → Grafana (3000)
                                   ↓
                              Alertmanager
```

### Configuração no Prometheus

No arquivo `prometheus-holesky.yml`, o Node Exporter está configurado como:

```yaml
- job_name: 'node-exporter'
  static_configs:
    - targets: ['node-exporter-holesky:9100']
      labels:
        service: 'system'
        network: 'holesky'
  scrape_interval: 30s
  metrics_path: /metrics
```

### Configuração no Docker Compose

```yaml
node-exporter:
  image: prom/node-exporter:latest
  container_name: node-exporter-holesky
  restart: always
  ports:
    - "9100:9100"
  volumes:
    - /proc:/host/proc:ro
    - /sys:/host/sys:ro
    - /:/rootfs:ro
  command:
    - '--path.procfs=/host/proc'
    - '--path.rootfs=/rootfs'
    - '--path.sysfs=/host/sys'
    - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
```

## Por que é Importante para Rocket Pool?

### 1. **Monitoramento de Recursos**

- Garante que o sistema tem recursos suficientes para rodar Geth + Lighthouse
- Monitora uso de CPU, memória e disco em tempo real
- Identifica possíveis gargalos antes que afetem a performance

### 2. **Detecção de Problemas**

- Identifica gargalos de CPU, memória ou disco
- Monitora temperatura dos componentes
- Detecta problemas de conectividade de rede

### 3. **Capacidade de Planejamento**

- Ajuda a prever quando será necessário upgrade de hardware
- Fornece dados históricos para análise de tendências
- Permite otimização de recursos

### 4. **Troubleshooting**

- Facilita a identificação de problemas de performance
- Correlaciona problemas dos nodes com recursos do sistema
- Fornece dados para análise de incidentes

## Visualização no Grafana

As métricas coletadas pelo Node Exporter são visualizadas no Grafana através de dashboards específicos, proporcionando:

- **Visão geral do sistema**: CPU, memória, disco
- **Análise de rede**: Tráfego, latência, conectividade
- **Monitoramento de temperatura**: Prevenção de superaquecimento
- **Alertas personalizados**: Notificações quando recursos estão limitados

## 🛠 Comandos Úteis

### Verificar Status do Node Exporter

```bash
docker logs node-exporter-holesky --tail=10
```

### Acessar Métricas Diretamente

```bash
curl http://localhost:9100/metrics
```

### Testar Conectividade

```bash
curl -s http://localhost:9100/metrics | grep node_up
```

### Verificar Uso de Recursos

```bash
curl -s http://localhost:9100/metrics | grep -E "(node_cpu|node_memory|node_filesystem)"
```

## Configurações Avançadas

### Coletores Habilitados

O Node Exporter vem com vários coletores habilitados por padrão:

- `cpu` - Informações de CPU
- `diskstats` - Estatísticas de disco
- `filesystem` - Informações do sistema de arquivos
- `loadavg` - Load average
- `meminfo` - Informações de memória
- `netdev` - Dispositivos de rede
- `stat` - Estatísticas do kernel
- `time` - Tempo do sistema
- `uname` - Informações do sistema

### Exclusões de Sistema de Arquivos

```bash
--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)
```

## Métricas Críticas para Rocket Pool

### Para Validação

- **CPU**: Manter < 80% durante operação normal
- **Memória**: Manter > 2GB disponível
- **Disco**: Manter > 20% de espaço livre
- **Rede**: Monitorar latência e throughput

### Alertas Recomendados

- CPU > 90% por mais de 5 minutos
- Memória disponível < 1GB
- Espaço em disco < 10%
- Temperatura > 80°C

## 📚 Referências

- [Prometheus Node Exporter](https://github.com/prometheus/node_exporter)
- [Documentação Oficial](https://prometheus.io/docs/guides/node-exporter/)
- [Métricas Disponíveis](https://prometheus.io/docs/prometheus/latest/querying/basics/)

---

**Nota**: Este arquivo documenta a configuração e uso do Node Exporter no ambiente Rocket Pool Holesky. Para configurações específicas de produção, consulte a documentação oficial do Rocket Pool.

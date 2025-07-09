# Guia Completo: Configuração de Port Forwarding para Lighthouse

## 📋 Resumo da Configuração Necessária

### Informações do Seu Sistema

- **IP Local**: 192.168.18.98
- **Gateway**: 192.168.18.1
- **Porta necessária**: 9000 (TCP + UDP)
- **Serviço**: Lighthouse Beacon Node (Holesky)

### Status Atual

- ✅ **Docker**: Portas mapeadas corretamente
- ✅ **Conectividade local**: Funcionando
- ❌ **UPnP**: Não suportado pelo gateway
- ⚠️ **Acesso externo**: Requer configuração manual

---

## 🔧 Configuração do Roteador

### Passo 1: Acessar o Roteador

**Método 1 - Pelo navegador:**

```bash
http://192.168.18.1
```

**Método 2 - IPs comuns de roteadores:**

- `http://192.168.1.1`
- `http://192.168.0.1`
- `http://10.0.0.1`

**Credenciais padrão comuns:**

- admin/admin
- admin/password
- admin/(vazio)
- (vazio)/admin

### Passo 2: Localizar a Seção de Port Forwarding

**Nomes comuns da seção:**

- Port Forwarding
- Virtual Server
- NAT Forwarding
- Application & Gaming
- Firewall → Port Forwarding
- Advanced → Port Forwarding

### Passo 3: Configurar a Regra

**Configuração necessária:**

| Campo | Valor | Descrição |
|-------|-------|-----------|
| **Nome/Descrição** | Lighthouse-P2P | Identificação da regra |
| **Protocolo** | TCP+UDP ou Both | Ambos protocolos |
| **Porta Externa** | 9000 | Porta que o mundo externo acessa |
| **Porta Interna** | 9000 | Porta no computador local |
| **IP Interno** | 192.168.18.98 | IP da sua máquina |
| **Status** | Enabled/Ativo | Regra ativa |

**Exemplo de configuração:**

```text
Nome: Lighthouse-P2P
Protocolo: TCP+UDP
Porta Externa: 9000-9000
Porta Interna: 9000-9000
IP Interno: 192.168.18.98
Status: Enabled
```

---

## 📱 Configuração por Marca de Roteador

### TP-Link

1. **Acesse**: `http://192.168.18.1`
2. **Vá para**: Advanced → NAT Forwarding → Port Forwarding
3. **Clique**: Add
4. **Configure**:
   - Service Name: Lighthouse-P2P
   - Protocol: TCP+UDP
   - External Port: 9000
   - Internal Port: 9000
   - Internal IP: 192.168.18.98
5. **Salve**: Save

### D-Link

1. **Acesse**: `http://192.168.18.1`
2. **Vá para**: Advanced → Port Forwarding
3. **Clique**: Add Rule
4. **Configure**:
   - Name: Lighthouse-P2P
   - Protocol: TCP+UDP
   - Public Port: 9000
   - Private Port: 9000
   - IP Address: 192.168.18.98
5. **Salve**: Apply

### Netgear

1. **Acesse**: `http://192.168.18.1`
2. **Vá para**: Dynamic DNS → Port Forwarding
3. **Clique**: Add Custom Service
4. **Configure**:
   - Service Name: Lighthouse-P2P
   - Protocol: TCP+UDP
   - External Starting Port: 9000
   - External Ending Port: 9000
   - Internal Starting Port: 9000
   - Internal Ending Port: 9000
   - Server IP Address: 192.168.18.98
5. **Salve**: Apply

### Linksys

1. **Acesse**: `http://192.168.18.1`
2. **Vá para**: Smart Wi-Fi Tools → Port Forwarding
3. **Clique**: Add a New Port Range
4. **Configure**:
   - Device: Selecione seu computador
   - Protocol: TCP+UDP
   - External Port: 9000
   - Internal Port: 9000
5. **Salve**: Save

### ASUS

1. **Acesse**: `http://192.168.18.1`
2. **Vá para**: Advanced Settings → WAN → Port Forwarding
3. **Configure**:
   - Service Name: Lighthouse-P2P
   - Protocol: TCP+UDP
   - Port Range: 9000
   - Local IP: 192.168.18.98
   - Local Port: 9000
4. **Salve**: Apply

---

## 🛠️ Configuração Avançada (Opcional)

### Reservar IP Local (DHCP Reservation)

Para garantir que sua máquina sempre tenha o IP 192.168.18.98:

1. **Vá para**: DHCP → Address Reservation
2. **Adicione**:
   - MAC Address: (MAC da sua máquina)
   - IP Address: 192.168.18.98
   - Description: Lighthouse-Node

**Encontrar MAC Address:**

```bash
ifconfig | grep "ether"
```

### Configurar DMZ (Última Opção)

⚠️ **Não recomendado para produção**

Se port forwarding não funcionar:

1. **Vá para**: DMZ ou Exposed Host
2. **Configure**: IP 192.168.18.98
3. **Ative**: DMZ

---

## 🧪 Testes de Conectividade

### Teste 1: Verificar Configuração Local

```bash
# Executar o script de teste
./scripts/test-udp-connectivity.sh
```

### Teste 2: Teste Online

**Sites para testar porta aberta:**

- <https://www.yougetsignal.com/tools/open-ports/>
- <https://canyouseeme.org/>
- <https://www.portchecktool.com/>

**Configuração do teste:**

- IP: (seu IP público)
- Port: 9000
- Protocol: TCP e UDP

### Teste 3: Verificar IP Público

```bash
# Descobrir seu IP público
curl -s httpbin.org/ip
```

### Teste 4: Teste de Peer Discovery

```bash
# Monitorar peers após configuração
./scripts/monitor-peers-lighthouse.sh --continuous
```

---

## 🔧 Atualizar Configuração do Lighthouse

Após configurar o port forwarding, otimize o Lighthouse:

### Passo 1: Descobrir IP Público Real

```bash
# Obter IP público
PUBLIC_IP=$(curl -s httpbin.org/ip | jq -r '.origin')
echo "Seu IP público: $PUBLIC_IP"
```

### Passo 2: Aplicar Configuração Otimizada

```bash
# Executar script de otimização
./scripts/optimize-peers-lighthouse.sh
```

### Passo 3: Configuração Manual (se necessário)

Edite o `docker-compose-holesky.yml`:

```yaml
lighthouse:
  command: >
    lighthouse bn
    --network=holesky
    --datadir=/root/.lighthouse
    --http
    --http-address=0.0.0.0
    --http-port=5052
    --execution-endpoint=http://geth:8551
    --execution-jwt=/secrets/jwtsecret
    --metrics
    --metrics-address=0.0.0.0
    --metrics-port=5054
    --port=9000
    --discovery-port=9000
    --enr-address=SEU_IP_PUBLICO_AQUI    # Substitua pelo IP público
    --enr-tcp-port=9000
    --enr-udp-port=9000
    --block-cache-size=10
    --historic-state-cache-size=4
    --auto-compact-db=true
    --checkpoint-sync-url=https://checkpoint-sync.holesky.ethpandaops.io
    --checkpoint-sync-url-timeout=600
    --target-peers=25
    --discovery-address=0.0.0.0
    --libp2p-addresses=/ip4/0.0.0.0/tcp/9000
    --libp2p-addresses=/ip4/0.0.0.0/udp/9000
```

### Passo 4: Reiniciar e Testar

```bash
# Reiniciar Lighthouse
docker-compose -f docker-compose-holesky.yml restart lighthouse

# Aguardar estabilização
sleep 30

# Testar conectividade
./scripts/test-udp-connectivity.sh

# Monitorar peers
./scripts/monitor-peers-lighthouse.sh
```

---

## 📊 Resultados Esperados

### Antes da Configuração

- Peers conectados: 0-2
- Peers descobertos: 200+
- Warnings: "Low peer count" frequentes

### Após a Configuração

- Peers conectados: 5-15
- Peers descobertos: 200+
- Warnings: Reduzidos significativamente
- Melhor estabilidade de conexão

---

## 🔍 Troubleshooting

### Problema: Port Forwarding Não Funciona

**Soluções:**

1. **Verificar firewall local**:

   ```bash
   sudo pfctl -sr | grep 9000
   ```

2. **Testar conectividade interna**:

   ```bash
   nc -u -v 192.168.18.98 9000
   ```

3. **Verificar ISP**:
   - Alguns ISPs bloqueiam portas P2P
   - Contatar suporte técnico se necessário

### Problema: Roteador Não Encontrado

**Soluções:**

1. **Descobrir gateway**:

   ```bash
   route -n get default | grep gateway
   ```

2. **Scan de rede**:

   ```bash
   nmap -sn 192.168.18.0/24
   ```

### Problema: Credenciais Incorretas

**Soluções:**

1. **Reset do roteador** (botão físico)
2. **Verificar etiqueta do roteador**
3. **Consultar manual do modelo**

---

## 📋 Checklist Final

- [ ] Acessar roteador (<http://192.168.18.1>)
- [ ] Criar regra port forwarding porta 9000 TCP+UDP
- [ ] Direcionar para IP 192.168.18.98
- [ ] Salvar configuração
- [ ] Reiniciar roteador (opcional)
- [ ] Testar conectividade online
- [ ] Atualizar configuração Lighthouse
- [ ] Reiniciar containers
- [ ] Monitorar peers por 24h

---

## 🚀 Próximos Passos

1. **Configure o port forwarding** seguindo o guia da sua marca
2. **Teste a conectividade** com ferramentas online
3. **Execute a otimização** do Lighthouse
4. **Monitore os resultados** por 24-48 horas

**Resultado esperado**: Melhoria significativa na contagem de peers conectados!

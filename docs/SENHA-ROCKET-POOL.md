# 🔐 Configuração de Senha do Rocket Pool

## **Problema Resolvido - Senha Obrigatória**

### **Contexto do Problema**

O erro `The node password has not been set, retrying in 15s...` aparece quando o Rocket Pool não encontra uma senha configurada para o nó. **A senha é obrigatória** antes de qualquer operação.

### **Solução Implementada**

Adicionamos a configuração automática de senha no script `setup-rocketpool-hoodi.sh`:

```bash
# 2. Configurar senha do nó (se não estiver configurada)
echo "2️⃣  Configurando senha do nó..."
echo "==============================="
if rp_exec wallet status 2>/dev/null | grep -q "Password not set"; then
    echo "🔐 A senha do nó não foi configurada. Vamos configurá-la agora."
    echo ""
    echo "IMPORTANTE: Esta senha protege sua wallet e deve ser segura."
    echo "Recomendação: Use ao menos 12 caracteres, incluindo letras, números e símbolos."
    echo ""
    read -s -p "Digite uma senha para sua wallet: " node_password
    echo ""
    read -s -p "Confirme a senha: " confirm_password
    echo ""
    
    if [[ "$node_password" != "$confirm_password" ]]; then
        echo "❌ As senhas não coincidem!"
        exit 1
    fi
    
    if [[ ${#node_password} -lt 8 ]]; then
        echo "❌ A senha deve ter pelo menos 8 caracteres!"
        exit 1
    fi
    
    echo "🔧 Configurando senha do nó..."
    echo "$node_password" | rp_exec wallet set-password
    echo "✅ Senha configurada com sucesso!"
else
    echo "✅ Senha do nó já está configurada!"
fi
```

## **Como Usar**

### Opção 1: Configuração Automática (Recomendado)

```bash
./scripts/setup-rocketpool-hoodi.sh
```

O script detecta automaticamente se a senha não está configurada e solicita que você a defina.

### Opção 2: Configuração Manual

Se necessário, você pode configurar a senha manualmente:

```bash
# Dentro do container
docker exec -it rocketpool-node-hoodi rocketpool wallet set-password

# Ou usando nossa função auxiliar
rp_exec() {
    docker exec -it rocketpool-node-hoodi rocketpool "$@"
}

echo "suasenhasegura" | rp_exec wallet set-password
```

## 🔒 **Recomendações de Segurança**

### Características da Senha

- **Mínimo**: 8 caracteres (sistema exige)
- **Recomendado**: 12+ caracteres
- **Inclua**: Letras maiúsculas, minúsculas, números e símbolos
- **Evite**: Palavras comuns, informações pessoais, sequências

### Exemplos de Senhas Seguras

```text
✅ Bom: MyR0ck3tP00l2025!
✅ Bom: H00d1T3stN3t@2025
✅ Bom: Secur3W4ll3t#RP

❌ Ruim: 12345678
❌ Ruim: password
❌ Ruim: rocketpool
```

### Backup da Senha

⚠️ **IMPORTANTE**: Guarde sua senha em local seguro!

- Use um gerenciador de senhas
- Anote em papel e guarde em local físico seguro
- **NÃO** armazene em arquivos de texto simples
- **NÃO** compartilhe com ninguém

## **Verificação da Configuração**

Para verificar se a senha está configurada:

```bash
# Verificar status da wallet
docker exec -it rocketpool-node-hoodi rocketpool wallet status

# Deve mostrar: "Password set: true"
# Se mostrar "Password not set", execute o setup novamente
```

## 🛠️ **Troubleshooting**

### Erro: "Password not set"

```bash
# Solução: Execute o setup
./scripts/setup-rocketpool-hoodi.sh
```

### Erro: "Password too short"

```bash
# Solução: Use uma senha com pelo menos 8 caracteres
# Recomendado: 12+ caracteres
```

### Esqueci a senha

⚠️ **Atenção**: Se você esquecer a senha da wallet, precisará:

1. Parar todos os containers
2. Fazer backup das chaves (se possível)
3. Recriar a wallet usando o mnemonic
4. Reconfigurar tudo

Por isso é crucial fazer backup da senha!

## **Ordem Correta de Configuração**

1. ✅ **Iniciar containers**: `./scripts/start-hoodi.sh`
2. ✅ **Configurar senha**: Feito automaticamente no setup
3. ✅ **Criar wallet**: Feito automaticamente no setup
4. ✅ **Registrar nó**: Feito automaticamente no setup
5. ✅ **Configurar comissão**: Feito automaticamente no setup

## **Status Final**

Agora o processo é totalmente automático e seguro:

- ✅ Senha configurada automaticamente se necessário
- ✅ Validação de segurança da senha
- ✅ Confirmação de senha para evitar erros
- ✅ Verificação se já está configurada
- ✅ Integração completa com o setup

**O erro "password has not been set" está resolvido!** 🎉

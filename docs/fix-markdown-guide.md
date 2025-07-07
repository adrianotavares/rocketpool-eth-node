# fix-markdown.sh - Ferramenta de Correção Automática

## Descrição

Script utilitário para correção automática de problemas comuns em arquivos markdown, especialmente útil para manter um padrão profissional na documentação.

## Principais Funcionalidades

### Correções Automáticas

- **Remove emojis** de títulos (headings)
- **Padroniza formatação** para estilo profissional
- **Corrige emphasis** usado incorretamente como heading
- **Mantém estrutura** e conteúdo técnico intacto

### Flexibilidade de Uso

- **Arquivos específicos**: Processa arquivos individuais
- **Diretórios completos**: Processa scripts/ ou docs/
- **Projeto inteiro**: Processa todos os .md do projeto
- **Backup opcional**: Cria backups antes das modificações
- **Modo verbose**: Mostra detalhes das correções

## Como Usar

### Sintaxe Básica

```bash
./fix-markdown.sh [opções] [arquivos...]
```

### Opções Disponíveis

- `-h, --help` - Mostra ajuda completa
- `-a, --all` - Processa todos os arquivos .md do projeto
- `-s, --scripts` - Processa apenas arquivos em scripts/
- `-d, --docs` - Processa apenas arquivos em docs/
- `-b, --backup` - Cria backup antes de modificar
- `-v, --verbose` - Mostra detalhes das correções

### Exemplos Práticos

#### Correção de Todo o Projeto

```bash
# Corrigir todos os arquivos .md
./fix-markdown.sh --all

# Com backup e detalhes
./fix-markdown.sh --all --backup --verbose
```

#### Correção por Diretório

```bash
# Apenas scripts/
./fix-markdown.sh --scripts

# Apenas docs/ com backup
./fix-markdown.sh --docs --backup
```

#### Arquivos Específicos

```bash
# Arquivo único
./fix-markdown.sh docs/README.md

# Múltiplos arquivos
./fix-markdown.sh docs/README.md scripts/README.md

# Com backup
./fix-markdown.sh --backup docs/troubleshooting.md
```

## Exemplos de Correções

### Antes da Correção

```markdown
# Scripts do Rocket Pool
## Scripts Disponíveis
### Monitoramento
**Título em Negrito Incorreto**
```

### Depois da Correção

```markdown
# Scripts do Rocket Pool
## Scripts Disponíveis
### Monitoramento
Título em formato correto.
```

## Casos de Uso

### Durante Desenvolvimento

```bash
# Verificar e corrigir antes de commit
./fix-markdown.sh --all --verbose
```

### Manutenção Regular

```bash
# Correção semanal com backup
./fix-markdown.sh --all --backup
```

### Integração de Novos Documentos

```bash
# Corrigir apenas novos arquivos
./fix-markdown.sh docs/new-feature.md
```

### Padronização de Equipe

```bash
# Garantir padrão em scripts/
./fix-markdown.sh --scripts --verbose
```

## Backup e Segurança

### Sistema de Backup

- **Automático**: Com flag `--backup`
- **Timestamp**: Nome único com data/hora
- **Formato**: `arquivo.md.backup.20250706_215030`

### Recuperação

```bash
# Se algo der errado, restaurar do backup
cp docs/README.md.backup.20250706_215030 docs/README.md
```

## Integração com Git

### Antes de Commits

```bash
# Verificar e corrigir antes de commit
./fix-markdown.sh --all
git add .
git commit -m "docs: fix markdown formatting"
```

### Hook Pre-commit (opcional)

```bash
# No .git/hooks/pre-commit
#!/bin/bash
./fix-markdown.sh --all
git add *.md
```

## Saída do Script

### Modo Normal

```text
[PROCESSANDO] docs/README.md
[CORRIGIDO] docs/README.md
[OK] scripts/README.md já está correto
```

### Modo Verbose

```text
[PROCESSANDO] docs/README.md
[BACKUP] Backup criado para docs/README.md
[CORRIGIDO] docs/README.md
  → Emojis removidos dos títulos
  → Formatação padronizada
```

## Vantagens

1. **Automação**: Correção rápida de múltiplos arquivos
2. **Consistência**: Padrão uniforme em toda documentação
3. **Segurança**: Sistema de backup opcional
4. **Flexibilidade**: Múltiplas opções de uso
5. **Eficiência**: Processa apenas arquivos que precisam
6. **Profissionalismo**: Resultado limpo e empresarial

## Manutenção do Script

O script está localizado na raiz do projeto e pode ser facilmente:

- **Modificado**: Para adicionar novas correções
- **Estendido**: Para suportar novos padrões
- **Integrado**: Com outros workflows
- **Versionado**: Junto com o projeto

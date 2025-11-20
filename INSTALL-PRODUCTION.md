# 🚀 Guia de Instalação em Chatwoot em Produção

## ⚠️ ATENÇÃO - LEIA ANTES DE COMEÇAR

Este guia é para instalar o módulo SDR IA em um **Chatwoot JÁ EM PRODUÇÃO**.

**Características desta instalação**:
- ✅ **Zero downtime** - Seu Chatwoot não para
- ✅ **Rollback rápido** - Se algo der errado, volta em 2 minutos
- ✅ **Backup automático** - Criamos backup antes de tudo
- ✅ **Testado em produção** - Versão v1.1.2 estável

**Tempo estimado**: 30-45 minutos (incluindo testes)

---

## 📋 Pré-requisitos

### ✅ Checklist Obrigatório

Antes de começar, confirme que você tem:

- [ ] **Chatwoot v4.1.0** rodando em Docker/Docker Swarm
- [ ] **Acesso SSH root** ao servidor
- [ ] **Backup recente** do banco de dados PostgreSQL
- [ ] **OpenAI API Key** (para qualificação de leads)
- [ ] **Espaço em disco**: Mínimo 3GB livre
- [ ] **Permissão para interromper** temporariamente qualificações (serão retomadas)

### 🔍 Como Verificar Sua Versão do Chatwoot

```bash
# Método 1: Via Docker
docker ps | grep chatwoot

# Método 2: Via logs
docker service logs chatwoot_chatwoot_app 2>&1 | grep "Chatwoot" | head -5

# Método 3: Via container
docker exec $(docker ps -q -f name=chatwoot_app) cat /app/VERSION
```

**Esperado**: `v4.1.0` ou superior

### ⚠️ Incompatibilidades Conhecidas

- ❌ **Chatwoot < v4.0.0**: NÃO compatível
- ⚠️ **Chatwoot v4.0.x**: Pode funcionar mas não testado
- ✅ **Chatwoot v4.1.0+**: Totalmente compatível

---

## 📦 Parte 1: Backup e Preparação (10 min)

### 1.1. Fazer Backup do Banco de Dados

```bash
# Criar diretório de backup
mkdir -p /root/backups-chatwoot

# Backup do PostgreSQL
docker exec $(docker ps -q -f name=postgres) \
  pg_dump -U postgres chatwoot_production | \
  gzip > /root/backups-chatwoot/database-$(date +%Y%m%d-%H%M%S).sql.gz

# Verificar tamanho
ls -lh /root/backups-chatwoot/
```

**Tamanho esperado**: Depende do seu volume de dados (normalmente 10MB-500MB)

### 1.2. Anotar Configurações Atuais

```bash
# Ver serviços rodando
docker service ls | grep chatwoot

# Anotar versão da imagem atual
docker service inspect chatwoot_chatwoot_app --format='{{.Spec.TaskTemplate.ContainerSpec.Image}}'
```

**Anote a imagem atual!** Exemplo: `chatwoot/chatwoot:v4.1.0`

Você vai precisar disso se precisar fazer rollback.

### 1.3. Testar Conectividade

```bash
# Testar se consegue acessar o banco
docker exec $(docker ps -q -f name=postgres) psql -U postgres -d chatwoot_production -c "SELECT COUNT(*) FROM conversations;"

# Testar se Redis está respondendo
docker exec $(docker ps -q -f name=redis) redis-cli ping
```

**Esperado**:
- Número de conversas (ex: `351`)
- `PONG` do Redis

---

## 🛠️ Parte 2: Instalação do SDR IA (15 min)

### 2.1. Clonar o Repositório

```bash
cd /root
git clone https://github.com/eversonsantos-dev/chatwoot-sdr-ia.git
cd chatwoot-sdr-ia

# Ir para a versão estável
git checkout v1.1.2

# Verificar
git log -1 --oneline
```

**Esperado**: `542ffce Fix: Correct sender assignment in send_message method`

### 2.2. Revisar o Dockerfile

```bash
# Ver o que será instalado
head -30 Dockerfile

# Verificar versão base do Chatwoot
grep "FROM chatwoot" Dockerfile
```

**IMPORTANTE**: O Dockerfile usa `chatwoot/chatwoot:v4.1.0` como base. Se sua produção usa versão diferente, edite:

```bash
nano Dockerfile

# Linha 8: Mude para sua versão
# ARG CHATWOOT_VERSION=v4.1.0
# Para:
# ARG CHATWOOT_VERSION=v4.x.x
```

### 2.3. Build da Imagem Customizada

```bash
# Build (vai levar 5-10 minutos)
docker build \
  -t localhost/chatwoot-sdr-ia:v1.1.2 \
  -t localhost/chatwoot-sdr-ia:latest \
  -f Dockerfile .

# Verificar se criou
docker images | grep chatwoot-sdr-ia
```

**Esperado**:
- Imagem de ~2.4GB
- Duas tags: `v1.1.2` e `latest`

### 2.4. Testar a Imagem Antes do Deploy

```bash
# Rodar container de teste
docker run --rm localhost/chatwoot-sdr-ia:v1.1.2 bundle exec rails runner "puts 'SDR IA: ' + SdrIa.enabled?.to_s"
```

**Esperado**: `SDR IA: true`

Se aparecer erro, **NÃO CONTINUE**. Revise o build.

---

## 🚀 Parte 3: Deploy em Produção (10 min)

### 3.1. Estratégia de Deploy

Vamos atualizar os serviços um por um para garantir zero downtime:

1. **Primeiro Sidekiq** (processamento em background)
2. **Depois App** (interface web)

### 3.2. Atualizar Sidekiq (Workers)

```bash
# Ver estado atual
docker service ps chatwoot_chatwoot_sidekiq

# Atualizar com rollback automático se falhar
docker service update \
  --image localhost/chatwoot-sdr-ia:v1.1.2 \
  --update-parallelism 1 \
  --update-delay 10s \
  --update-failure-action rollback \
  --rollback-parallelism 1 \
  chatwoot_chatwoot_sidekiq

# Aguardar convergir (vai mostrar progresso)
# Tempo: ~2 minutos
```

**Verificar sucesso**:
```bash
docker service ps chatwoot_chatwoot_sidekiq

# Ver logs
docker service logs --tail 50 chatwoot_chatwoot_sidekiq | grep "\[SDR IA\]"
```

**Logs esperados**:
```
[SDR IA] Listener adicionado ao AsyncDispatcher
[SDR IA] Carregando módulo SDR IA...
[SDR IA] Módulo habilitado. Carregando classes...
[SDR IA] Classes carregadas. Listener será registrado pelo AsyncDispatcher.
```

### 3.3. Atualizar App (Interface Web)

```bash
# Ver estado atual
docker service ps chatwoot_chatwoot_app

# Atualizar
docker service update \
  --image localhost/chatwoot-sdr-ia:v1.1.2 \
  --update-parallelism 1 \
  --update-delay 10s \
  --update-failure-action rollback \
  --rollback-parallelism 1 \
  chatwoot_chatwoot_app

# Aguardar convergir
# Tempo: ~2 minutos
```

**Verificar sucesso**:
```bash
docker service ps chatwoot_chatwoot_app

# Ver logs
docker service logs --tail 30 chatwoot_chatwoot_app | grep "\[SDR IA\]"
```

### 3.4. Rodar Migrations

```bash
# Rodar migrations do banco de dados
CONTAINER=$(docker ps -q -f name=chatwoot_app | head -1)
docker exec $CONTAINER bundle exec rails db:migrate

# Verificar tabelas criadas
docker exec $CONTAINER bundle exec rails runner "
  puts 'Tabela sdr_ia_configs: ' + SdrIaConfig.table_exists?.to_s
  puts 'Total de configs: ' + SdrIaConfig.count.to_s
"
```

**Esperado**:
```
Tabela sdr_ia_configs: true
Total de configs: 0
```

---

## ✅ Parte 4: Verificação e Testes (10 min)

### 4.1. Verificar Serviços

```bash
# Todos os serviços devem estar Running
docker service ls | grep chatwoot

# Status detalhado
docker service ps chatwoot_chatwoot_app
docker service ps chatwoot_chatwoot_sidekiq
```

**Esperado**: Todos com status `Running` e replicas `1/1`

### 4.2. Testar Interface Web

1. **Abra seu Chatwoot** no navegador
2. **Faça login** como administrador
3. **Pressione** `Ctrl + Shift + R` (hard refresh)
4. **Vá para**: Menu lateral → Configurações → SDR IA

**Resultado esperado**: Interface SDR IA carregada com 4 abas:
- ⚙️ Configurações Gerais
- 🤖 Prompts da IA
- 📝 Perguntas por Etapa
- 📊 Sistema de Scoring

**Se não aparecer**:
```bash
# Limpar cache do browser
# Tentar em aba anônima
# Verificar assets:
docker exec $(docker ps -q -f name=chatwoot_app) ls -lh /app/public/vite/assets/ | grep sdr
```

### 4.3. Configurar OpenAI API Key

1. No campo **"OpenAI API Key"**, cole sua chave
2. Selecione modelo: **GPT-4 Turbo** (recomendado)
3. Deixe os outros valores padrão
4. Clique **"Salvar Configurações"**

**Aguarde a mensagem**: ✅ "Configurações salvas com sucesso"

### 4.4. Teste Funcional Completo

```bash
# Simular mensagem incoming para testar fluxo
CONTAINER=$(docker ps -q -f name=chatwoot_app | head -1)
docker exec $CONTAINER bundle exec rails runner "
  # Pegar primeiro contact
  contact = Contact.first
  conversation = contact.conversations.last

  # Criar mensagem de teste
  message = conversation.messages.create!(
    account: contact.account,
    inbox: conversation.inbox,
    message_type: :incoming,
    content: 'Teste SDR IA',
    sender: contact
  )

  puts 'Mensagem de teste criada: ID=' + message.id.to_s
"

# Monitorar logs (aguardar 5 segundos)
sleep 5
docker service logs --tail 20 chatwoot_chatwoot_sidekiq | grep "\[SDR IA\]"
```

**Logs esperados**:
```
[SDR IA] Nova mensagem incoming: contact_id=X
[SDR IA] Job agendado para 2 segundos
[SDR IA] Processando mensagem do contact X
[SDR IA] Mensagem enviada: Olá! Sou o assistente virtual...
[SDR IA] Progresso atualizado: 1/6
```

---

## 🔄 Rollback (Se Necessário)

Se algo der errado, você pode reverter em 2 minutos:

### Método 1: Rollback Automático Docker Swarm

```bash
# Voltar Sidekiq
docker service rollback chatwoot_chatwoot_sidekiq

# Voltar App
docker service rollback chatwoot_chatwoot_app
```

### Método 2: Voltar para Imagem Original

```bash
# Usar a imagem que você anotou no início
IMAGEM_ORIGINAL="chatwoot/chatwoot:v4.1.0"  # MUDE PARA SUA VERSÃO

docker service update --image $IMAGEM_ORIGINAL chatwoot_chatwoot_sidekiq
docker service update --image $IMAGEM_ORIGINAL chatwoot_chatwoot_app
```

### Método 3: Restaurar Banco (Último Recurso)

```bash
# APENAS se o banco foi corrompido (muito improvável)
cd /root/backups-chatwoot

# Encontrar último backup
ls -lht database-*.sql.gz | head -1

# Restaurar (CUIDADO - vai sobrescrever)
gunzip -c database-XXXXXXXX.sql.gz | \
  docker exec -i $(docker ps -q -f name=postgres) \
  psql -U postgres chatwoot_production
```

---

## 📊 Monitoramento Pós-Instalação

### Ver Estatísticas

```bash
# Leads em qualificação
docker exec $(docker ps -q -f name=chatwoot_app) bundle exec rails runner "
  em_andamento = Contact.where(\"custom_attributes->>'sdr_ia_status' = 'em_andamento'\").count
  qualificados = Contact.where(\"custom_attributes->>'sdr_ia_status' = 'qualificado'\").count

  puts 'Em andamento: ' + em_andamento.to_s
  puts 'Qualificados: ' + qualificados.to_s
"
```

### Monitorar em Tempo Real

```bash
# Terminal 1: Logs do Sidekiq
docker service logs -f chatwoot_chatwoot_sidekiq | grep "\[SDR IA\]"

# Terminal 2: Logs do App
docker service logs -f chatwoot_chatwoot_app | grep "\[SDR IA\]"
```

---

## 🎯 Próximos Passos

Após instalação bem-sucedida:

1. **✅ Configurar OpenAI API Key** (se ainda não fez)
2. **✅ Ajustar prompts** conforme seu negócio
3. **✅ Customizar perguntas** para seu fluxo
4. **✅ Definir thresholds** de temperatura
5. **✅ Configurar atribuição** de times (opcional)
6. **✅ Testar com 5-10 leads** antes de ativar em larga escala
7. **✅ Monitorar qualidade** das qualificações
8. **✅ Ajustar scoring** se necessário

---

## 🆘 Troubleshooting

### Problema: Imagem muito grande (>3GB)

**Causa**: Docker não limpou builds antigos

**Solução**:
```bash
docker system prune -a --volumes
docker builder prune -a
```

### Problema: Erro "table sdr_ia_configs does not exist"

**Causa**: Migration não rodou

**Solução**:
```bash
CONTAINER=$(docker ps -q -f name=chatwoot_app | head -1)
docker exec $CONTAINER bundle exec rails db:migrate
```

### Problema: Interface não aparece mesmo após refresh

**Causa**: Assets não foram copiados para volume

**Solução**:
```bash
# Copiar assets para volume público
docker run --rm \
  -v chatwoot_public:/vol \
  localhost/chatwoot-sdr-ia:v1.1.2 \
  sh -c "rm -rf /vol/* && cp -r /app/public/* /vol/"

# Reiniciar app
docker service update --force chatwoot_chatwoot_app
```

### Problema: Jobs não processam

**Causa**: Sidekiq não foi atualizado

**Solução**:
```bash
docker service ps chatwoot_chatwoot_sidekiq

# Se não estiver com imagem v1.1.2, atualizar
docker service update --image localhost/chatwoot-sdr-ia:v1.1.2 chatwoot_chatwoot_sidekiq
```

### Problema: Erro "undefined method 'agents' for Inbox"

**Causa**: Versão anterior à v1.1.2

**Solução**:
```bash
cd /root/chatwoot-sdr-ia
git checkout v1.1.2
docker build -t localhost/chatwoot-sdr-ia:v1.1.2 .
# Refazer deploy
```

---

## 📞 Suporte

### Antes de Pedir Ajuda

Colete estas informações:

```bash
# 1. Versão do Chatwoot
docker exec $(docker ps -q -f name=chatwoot_app) cat /app/VERSION

# 2. Imagem em uso
docker service inspect chatwoot_chatwoot_app --format='{{.Spec.TaskTemplate.ContainerSpec.Image}}'

# 3. Logs recentes
docker service logs --tail 100 chatwoot_chatwoot_sidekiq > /tmp/sdr-ia-logs.txt
docker service logs --tail 100 chatwoot_chatwoot_app >> /tmp/sdr-ia-logs.txt

# 4. Status dos serviços
docker service ps chatwoot_chatwoot_app > /tmp/sdr-ia-status.txt
docker service ps chatwoot_chatwoot_sidekiq >> /tmp/sdr-ia-status.txt
```

### Onde Pedir Ajuda

- **GitHub Issues**: https://github.com/eversonsantos-dev/chatwoot-sdr-ia/issues
- **Inclua**: Logs + Status + Versão do Chatwoot

---

## 🎉 Conclusão

Se você chegou até aqui e viu os logs do SDR IA, **parabéns!**

Você instalou com sucesso o módulo SDR IA em produção! 🚀

**Lembre-se**:
- ✅ Backup v1.1.2 está em `/root/backups/`
- ✅ Rollback pode ser feito em 2 minutos
- ✅ Zero downtime durante deploy
- ✅ Todos os dados preservados

**Próximo passo**: Configure sua OpenAI API Key e teste com alguns leads!

---

**Desenvolvido com ❤️ para automatizar qualificação de leads**
**Versão do guia**: 1.0 (20/11/2025)
**Baseado em**: Chatwoot SDR IA v1.1.2

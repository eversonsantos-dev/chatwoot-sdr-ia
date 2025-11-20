# Guia de Atualização - SDR IA v1.2.0

## 🎯 O que muda nesta versão?

### Novas Funcionalidades
1. **Agente Padrão**: Todos os atendimentos automáticos serão feitos pelo agente configurado (Pedro Zoia)
2. **Prompt Conversacional**: IA agora conversa de forma natural, não apenas faz perguntas mecânicas
3. **Personalização**: Nome da clínica, IA e endereço configuráveis
4. **Scoring Aprimorado**: Sistema de pontuação de 0-130 pontos com detalhamento

### Alterações no Banco de Dados
Nova migration adiciona 4 campos em `sdr_ia_configs`:
- `default_agent_email` - Email do agente padrão (Pedro Zoia)
- `clinic_name` - Nome da clínica
- `ai_name` - Nome da IA
- `clinic_address` - Endereço da clínica

---

## 📋 Pré-requisitos

- Versão atual: v1.1.2 ou superior
- Backup completo do banco de dados
- Acesso ao servidor com Docker Swarm

---

## 🚀 Processo de Atualização

### Passo 1: Backup (OBRIGATÓRIO)

```bash
cd /root/chatwoot-sdr-ia

# 1. Backup do código atual
git tag v1.1.2-backup-$(date +%Y%m%d)
git push origin --tags

# 2. Backup da imagem Docker atual
docker save localhost/chatwoot-sdr-ia:542ffce | gzip > ~/backup-sdr-ia-v1.1.2-$(date +%Y%m%d).tar.gz

# 3. Backup do banco de dados
docker exec -it chatwoot_postgres pg_dump -U postgres chatwoot_production > ~/backup-db-$(date +%Y%m%d).sql
```

### Passo 2: Atualizar o Código

```bash
cd /root/chatwoot-sdr-ia

# Verificar se não há mudanças não commitadas
git status

# Se houver mudanças, commitar ou fazer stash
# git stash

# Atualizar para v1.2.0 (quando disponível)
git pull origin main

# Ou aplicar as mudanças manualmente se você recebeu os arquivos
```

### Passo 3: Rebuild da Imagem Docker

```bash
cd /root/chatwoot-sdr-ia

# Rebuild com novo hash
./rebuild.sh

# Isso vai:
# - Compilar nova imagem com migrations
# - Incluir novos prompts
# - Atualizar ConversationManager
```

### Passo 4: Deploy

```bash
# Deploy da nova versão
./deploy.sh

# Ou manualmente:
NEW_IMAGE=$(git rev-parse --short HEAD)
docker service update --image localhost/chatwoot-sdr-ia:$NEW_IMAGE chatwoot_chatwoot_app
docker service update --image localhost/chatwoot-sdr-ia:$NEW_IMAGE chatwoot_chatwoot_sidekiq
```

### Passo 5: Rodar Migrations

As migrations vão rodar automaticamente no entrypoint do container, mas você pode verificar:

```bash
# Verificar se migrations rodaram
docker service logs chatwoot_chatwoot_app | grep "Migrating to AddDefaultAgentToSdrIaConfigs"

# Se necessário, rodar manualmente
docker exec -it $(docker ps -q -f name=chatwoot_chatwoot_app) bundle exec rails db:migrate
```

### Passo 6: Verificar Configuração do Agente

**IMPORTANTE**: Certifique-se de que o usuário Pedro Zoia existe no Chatwoot:

```bash
# Verificar se o usuário existe
docker exec -it $(docker ps -q -f name=chatwoot_chatwoot_app) bundle exec rails runner "
  user = User.find_by(email: 'pedro.zoia@nexusatemporal.com')
  if user
    puts '✅ Usuário Pedro Zoia encontrado: ' + user.name
  else
    puts '❌ ERRO: Usuário pedro.zoia@nexusatemporal.com NÃO encontrado!'
    puts 'Por favor, crie este usuário no Chatwoot antes de continuar.'
  end
"
```

Se o usuário não existir, crie no painel do Chatwoot:
1. Acesse Settings → Agents
2. Clique em "Add Agent"
3. Email: `pedro.zoia@nexusatemporal.com`
4. Nome: `Pedro Zoia`
5. Role: `Administrator` (ou Agent)

---

## 🔧 Configuração Pós-Deploy

### Atualizar Prompts via Painel Admin

1. Acesse o Chatwoot
2. Vá em **Settings → SDR IA**
3. Aba **"Prompts da IA"**
4. Você verá os novos prompts conversacionais já carregados
5. Personalize se necessário:
   - Nome da clínica
   - Nome da IA
   - Endereço
   - Valores de referência

### Configurar Agente Padrão

Na aba **"Configurações Gerais"**:
- **Email do Agente Padrão**: `pedro.zoia@nexusatemporal.com`
- **Nome da Clínica**: `Nexus Atemporal` (ou seu nome)
- **Nome da IA**: `Nexus IA` (ou personalize)
- **Endereço**: Insira o endereço completo da clínica

Clique em **"Salvar Configurações"**

---

## ✅ Verificação Pós-Atualização

### 1. Verificar Serviços

```bash
# Verificar se serviços estão rodando
docker service ps chatwoot_chatwoot_app
docker service ps chatwoot_chatwoot_sidekiq

# Verificar logs
docker service logs -f chatwoot_chatwoot_sidekiq | grep "\[SDR IA\]"
```

### 2. Testar Fluxo Completo

1. Envie uma mensagem de teste via WhatsApp
2. Verifique nos logs se a mensagem foi detectada:
   ```
   [SDR IA] Nova mensagem incoming: contact_id=X
   [SDR IA] Job agendado para 2 segundos
   [SDR IA] Usando agente padrão: pedro.zoia@nexusatemporal.com
   [SDR IA] Mensagem enviada por pedro.zoia@nexusatemporal.com: Olá! Sou a Nexus IA...
   ```

3. Verifique se o remetente das mensagens é **Pedro Zoia**

### 3. Verificar Banco de Dados

```bash
docker exec -it $(docker ps -q -f name=chatwoot_chatwoot_app) bundle exec rails runner "
  config = SdrIaConfig.first
  puts '=== Configuração SDR IA ==='
  puts 'Agente Padrão: ' + config.default_agent_email.to_s
  puts 'Nome Clínica: ' + config.clinic_name.to_s
  puts 'Nome IA: ' + config.ai_name.to_s
  puts 'Prompt System: ' + config.prompt_system[0..100].to_s + '...'
"
```

---

## 🔄 Rollback (Se necessário)

Se algo der errado, você pode voltar para v1.1.2:

```bash
# Opção 1: Via Git tag
cd /root/chatwoot-sdr-ia
git checkout v1.1.2
./rebuild.sh
./deploy.sh

# Opção 2: Via imagem Docker salva
gunzip -c ~/backup-sdr-ia-v1.1.2-YYYYMMDD.tar.gz | docker load
docker service update --image localhost/chatwoot-sdr-ia:542ffce chatwoot_chatwoot_app
docker service update --image localhost/chatwoot-sdr-ia:542ffce chatwoot_chatwoot_sidekiq

# Opção 3: Restaurar banco de dados (ÚLTIMO RECURSO)
cat ~/backup-db-YYYYMMDD.sql | docker exec -i chatwoot_postgres psql -U postgres chatwoot_production
```

---

## 📊 Comparação de Versões

| Recurso | v1.1.2 | v1.2.0 |
|---------|--------|--------|
| Agente Padrão | ❌ (primeiro usuário da conta) | ✅ Pedro Zoia configurável |
| Prompt | Mecânico (6 perguntas) | Conversacional e natural |
| Personalização | ❌ Hardcoded | ✅ Nome clínica, IA, endereço |
| Scoring | 0-100 pontos | 0-130 pontos detalhado |
| Respostas a perguntas | Limitado | ✅ IA responde antes de prosseguir |
| Coleta implícita | Não | ✅ Extrai info das respostas |

---

## 🆘 Troubleshooting

### Erro: "Usuário pedro.zoia@nexusatemporal.com não encontrado"

**Solução**: Crie o usuário no Chatwoot antes de ativar o SDR IA.

### Mensagens não estão sendo enviadas

1. Verifique logs: `docker service logs chatwoot_chatwoot_sidekiq | grep ERROR`
2. Verifique se migrations rodaram: `docker exec ... rails db:migrate:status`
3. Verifique configuração: Settings → SDR IA → Verificar se está **Enabled**

### Prompt antigo ainda aparece

1. Limpe cache do Redis:
   ```bash
   docker exec -it chatwoot_redis redis-cli FLUSHDB
   ```
2. Restart dos serviços:
   ```bash
   docker service update --force chatwoot_chatwoot_app
   docker service update --force chatwoot_chatwoot_sidekiq
   ```

---

## 📞 Suporte

- Issues: https://github.com/eversonsantos-dev/chatwoot-sdr-ia/issues
- Documentação: README.md
- Changelog: CHANGELOG.md

---

**Data de Lançamento**: 2025-11-20
**Versão**: 1.2.0
**Compatibilidade**: Chatwoot v4.1.0+

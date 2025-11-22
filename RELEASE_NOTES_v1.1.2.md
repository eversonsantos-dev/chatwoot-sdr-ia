# Release v1.1.2 - Versão Funcional Estável (BACKUP RECOMENDADO)

**Data**: 20/11/2025
**Commit**: `542ffce`
**Tag**: `v1.1.2`
**Imagem Docker**: `localhost/chatwoot-sdr-ia:542ffce`

## 🟢 VERSÃO TOTALMENTE FUNCIONAL

Esta é uma versão **estável e testada em produção** que serve como **ponto de backup seguro**.

## ✅ Status

- ✅ Totalmente funcional
- ✅ Testada em produção
- ✅ Recomendada para backup e restore
- ✅ Sem bugs conhecidos

## 🐛 Correção Crítica

### Fix: Sender Assignment no send_message

**Problema Resolvido**: `undefined method 'agents' for an instance of Inbox`

#### Descrição do Erro
O método `send_message` em `ConversationManager` tentava acessar `conversation.inbox.agents.first`, mas a classe `Inbox` do Chatwoot não possui o método `agents`, causando falha ao enviar mensagens automáticas.

#### Impacto
- SDR IA detectava mensagens corretamente
- Mas falhava ao tentar responder automaticamente
- Jobs Sidekiq retornavam erro 500

#### Solução Aplicada
```ruby
# ANTES (quebrado):
sender: conversation.inbox.agents.first || @account.users.first

# DEPOIS (funcional):
sender = conversation.assignee || @account.users.first
```

**Arquivo**: `plugins/sdr_ia/app/services/conversation_manager.rb:181-191`

## ✨ Funcionalidades Funcionando

### 🔄 Fluxo Completo Operacional
1. ✅ WhatsApp → Chatwoot → `message.created` event
2. ✅ EventDispatcherJob → SDR IA Listener detecta
3. ✅ QualifyLeadJob agendado (delay de 2 segundos)
4. ✅ ConversationManager.process_message! executado
5. ✅ send_message() envia resposta automática
6. ✅ Progresso atualizado (0/6 → 1/6 → 2/6... → 6/6)
7. ✅ Após 6/6: Qualificação final via OpenAI

### 📝 Sistema de 6 Perguntas
- Nome do lead
- Interesse (procedimento)
- Urgência (quando pretende fazer)
- Conhecimento (pesquisou antes?)
- Motivação (por que quer fazer?)
- Localização

### 🤖 Qualificação Automática
- Análise completa via OpenAI após 6 respostas
- Score 0-100 baseado em interesse, urgência, conhecimento
- Classificação por temperatura (Quente, Morno, Frio, Muito Frio)
- Labels aplicadas automaticamente

## 📊 Logs Esperados (Funcionando)

```
[SDR IA] Nova mensagem incoming: contact_id=8
[SDR IA] Job agendado para 2 segundos
[SDR IA] Processando mensagem do contact 8
[SDR IA] Mensagem enviada: Olá! Sou o assistente virtual...
[SDR IA] Progresso atualizado: 1/6
```

## 💾 Como Fazer Backup

```bash
# 1. Salvar imagem Docker
docker save localhost/chatwoot-sdr-ia:542ffce | gzip > chatwoot-sdr-ia-v1.1.2-backup.tar.gz

# 2. Backup do código
tar -czf chatwoot-sdr-ia-v1.1.2-code.tar.gz chatwoot-sdr-ia/

# 3. Verificar tag Git
git tag -v v1.1.2
```

## 🔄 Como Restaurar

### Opção 1: Via Git Tag
```bash
cd /root/chatwoot-sdr-ia
git checkout v1.1.2
docker build -t localhost/chatwoot-sdr-ia:542ffce .
docker service update --image localhost/chatwoot-sdr-ia:542ffce chatwoot_chatwoot_sidekiq
docker service update --image localhost/chatwoot-sdr-ia:542ffce chatwoot_chatwoot_app
```

### Opção 2: Via Imagem Docker Salva
```bash
gunzip -c chatwoot-sdr-ia-v1.1.2-backup.tar.gz | docker load
docker service update --image localhost/chatwoot-sdr-ia:542ffce chatwoot_chatwoot_sidekiq
docker service update --image localhost/chatwoot-sdr-ia:542ffce chatwoot_chatwoot_app
```

### Opção 3: Via Commit Hash
```bash
cd /root/chatwoot-sdr-ia
git checkout 542ffce
./rebuild.sh
./deploy.sh
```

## ✅ Verificação Pós-Deploy

```bash
# 1. Verificar serviços
docker service ps chatwoot_chatwoot_sidekiq
docker service ps chatwoot_chatwoot_app

# 2. Verificar logs do SDR IA
docker service logs -f chatwoot_chatwoot_sidekiq | grep "[SDR IA]"

# 3. Testar enviando mensagem via WhatsApp
# Deve aparecer: "[SDR IA] Mensagem enviada: ..."
```

## ⚠️ Limitações Conhecidas

- **Comportamento mecânico**: Faz perguntas sequenciais fixas
- **Não responde perguntas**: Ignora questões do lead e continua o script
- **Sem extração implícita**: Não detecta informações nas respostas
- **6 perguntas fixas**: Não adapta baseado no contexto

> **Nota**: Para comportamento conversacional natural, use v1.2.0 ou superior.

## 📈 Performance

- Delay de 2 segundos entre receber e processar mensagem (por design)
- Envio de mensagens instantâneo após processamento
- Qualificação final (após 6 respostas): ~2-5 segundos (latência OpenAI)

## 🔒 Segurança

- Mensagens criadas com sender apropriado (assignee ou admin)
- Validação de custom_attributes preservada
- Logs não expõem dados sensíveis

## 🔗 Links

- **Commit**: https://github.com/eversonsantos-dev/chatwoot-sdr-ia/commit/542ffce
- **Comparação com v1.2.0**: Ver CHANGELOG.md

---

**💡 Recomendação**: Use esta versão apenas como backup de segurança. Para produção, use v1.2.0 com IA conversacional.

**Desenvolvido com ❤️ por Everson Santos**

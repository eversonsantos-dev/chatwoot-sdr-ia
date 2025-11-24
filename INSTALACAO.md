# 🚀 Instalação - Chatwoot SDR IA v2.1.1

Guia de instalação do plugin SDR IA para Chatwoot.

---

## 📋 Requisitos

- Chatwoot instalado (versão 2.x ou superior)
- Acesso root ao servidor
- API Key da OpenAI
- Acesso aos arquivos do plugin (fornecidos após compra)

---

## ⚡ Instalação Rápida

### 1. Extrair Arquivos

Após receber o arquivo do plugin, extraia no servidor:

```bash
# Fazer upload do arquivo para o servidor
scp chatwoot-sdr-ia-v2.1.1.zip root@seu-servidor:/root/

# Conectar ao servidor
ssh root@seu-servidor

# Extrair arquivos
cd /root
unzip chatwoot-sdr-ia-v2.1.1.zip
cd chatwoot-sdr-ia
```

### 2. Executar Instalador

```bash
# Dar permissão de execução
chmod +x install.sh

# Executar instalador
sudo ./install.sh
```

O script vai solicitar:
1. **Caminho do Chatwoot** (detecta automaticamente)
2. **API Key da OpenAI** (obrigatório)

---

## 🔧 O que o Instalador Faz

1. ✅ Detecta automaticamente a instalação do Chatwoot
2. ✅ Cria backup completo antes de instalar
3. ✅ Copia plugin para `plugins/sdr_ia/`
4. ✅ Copia migrations do banco de dados
5. ✅ Configura variáveis de ambiente (.env)
6. ✅ Executa migrations (se instalação local)
7. ✅ Cria documentação de configuração
8. ✅ Instrui sobre próximos passos

---

## 🐳 Instalação Docker

Se seu Chatwoot está rodando em Docker, após executar o instalador:

### Docker Compose:

```bash
# 1. Rebuild da imagem
cd /caminho/do/chatwoot
docker build -t seu-usuario/chatwoot:sdr-ia .

# 2. Executar migrations
docker exec -it chatwoot_app bundle exec rails db:migrate

# 3. Reiniciar containers
docker-compose restart
```

### Docker Swarm:

```bash
# 1. Rebuild da imagem
cd /caminho/do/chatwoot
docker build -t localhost/chatwoot:sdr-ia .

# 2. Executar migrations
docker exec -it $(docker ps -q -f name=chatwoot_app) bundle exec rails db:migrate

# 3. Atualizar serviços
docker service update --force chatwoot_app
docker service update --force chatwoot_sidekiq
```

---

## 📝 Configuração Pós-Instalação

### 1. Acessar Painel Admin

1. Faça login no Chatwoot como **Super Admin**
2. Vá em **Settings** → **Inboxes**
3. Selecione o inbox que deseja configurar

### 2. Configurar SDR IA

Na aba **SDR IA** do inbox, configure:

- ✅ **Ativar SDR IA**: ON
- 📝 **Nome da Clínica/Empresa**: Nome completo
- 📍 **Endereço**: Endereço completo com cidade/estado
- 🔗 **Link de Agendamento**: URL do seu sistema de agendamento
- 👥 **Closers**: Selecione os agentes que receberão leads qualificados

### 3. Testar o Sistema

1. Envie uma mensagem de teste para o inbox
2. Envie um áudio de teste (MP3, M4A, WAV ou OGG)
3. Verifique se a IA respondeu
4. Verifique os logs para confirmar funcionamento

---

## 📊 Funcionalidades

### 🤖 IA Conversacional
- Responde automaticamente aos leads
- Entende contexto da conversa
- Tom natural e humanizado

### 🎤 Transcrição de Áudio
- Suporta MP3, M4A, WAV, OGG
- Transcrição automática via OpenAI Whisper
- Tamanho máximo: 25MB por áudio

### 📈 Qualificação Inteligente

**Sistema de Pontuação (0-130 pontos):**

- **INTERESSE** (0-50 pontos) - Fator principal
  - Procedimento específico: 50 pontos
  - Procedimento genérico: 40 pontos
  
- **URGÊNCIA** (0-30 pontos)
  - Esta semana: 30 pontos
  - Próximas 2 semanas: 25 pontos
  - Até 30 dias: 20 pontos
  
- **CONHECIMENTO** (0-20 pontos)
- **LOCALIZAÇÃO** (0-10 pontos)
- **MOTIVAÇÃO BÔNUS** (0-20 pontos)

**Classificação por Temperatura:**

- 🔴 **QUENTE** (90-130 pontos): Atribuído imediatamente ao closer
- 🟡 **MORNO** (50-89 pontos): Atribuído ao closer
- 🔵 **FRIO** (20-49 pontos): Apenas nutrição
- ⚫ **MUITO FRIO** (0-19 pontos): Apenas registro

### 🎯 Round Robin Automático
- Distribuição balanceada de leads entre closers
- Rastreamento persistente (Redis)
- Leads QUENTES e MORNOS são atribuídos automaticamente

### ⏱️ Buffer de Mensagens (35 segundos)
- Agrupa mensagens consecutivas do lead
- IA responde uma única vez para múltiplas mensagens
- Reduz custo de API OpenAI em ~70%

---

## 📊 Monitoramento

### Verificar Logs (Docker):

```bash
# Logs gerais do SDR IA
docker logs -f chatwoot_sidekiq | grep "\[SDR IA\]"

# Logs de transcrição de áudio
docker logs -f chatwoot_sidekiq | grep "\[Audio\]"

# Logs de qualificação
docker logs -f chatwoot_sidekiq | grep "\[Qualification\]"

# Logs de Round Robin
docker logs -f chatwoot_sidekiq | grep "\[RoundRobin\]"
```

### Verificar Logs (Local):

```bash
# Logs gerais
tail -f log/production.log | grep "\[SDR IA\]"

# Logs de áudio
tail -f log/production.log | grep "\[Audio\]"
```

---

## 🔧 Troubleshooting

### ✗ Áudio não está sendo transcrito

**Causas possíveis:**
1. API Key da OpenAI incorreta ou sem créditos
2. Formato de áudio não suportado
3. Arquivo muito grande (>25MB)

**Solução:**
```bash
# Verificar logs de áudio
docker logs chatwoot_sidekiq | grep "\[Audio\]" | tail -20

# Verificar .env
grep OPENAI_API_KEY /caminho/do/chatwoot/.env
```

---

### ✗ IA não está respondendo

**Causas possíveis:**
1. SDR IA não ativado no inbox
2. Configurações do inbox incompletas
3. API Key da OpenAI incorreta

**Solução:**
1. Settings → Inboxes → [Seu Inbox] → SDR IA
2. Verificar se "Ativar SDR IA" está ON
3. Verificar se Nome da Clínica e Endereço estão preenchidos
4. Verificar logs: `docker logs chatwoot_sidekiq | grep "\[SDR IA\]"`

---

### ✗ Leads não estão sendo atribuídos

**Causas possíveis:**
1. Nenhum closer configurado no inbox
2. Redis não está rodando
3. Lead com temperatura FRIO ou MUITO FRIO

**Solução:**
1. Settings → Inboxes → [Seu Inbox] → SDR IA → Adicionar closers
2. Verificar Redis: `docker ps | grep redis` ou `redis-cli ping`
3. Verificar logs: `docker logs chatwoot_sidekiq | grep "\[RoundRobin\]"`

---

### ✗ Erro após atualizar Chatwoot

**Causa:**
Atualização do Chatwoot pode sobrescrever arquivos do plugin

**Solução:**
```bash
# Restaurar backup
cd /root/backups
tar -xzf chatwoot-pre-sdr-ia-[DATA].tar.gz

# Ou reinstalar o plugin
cd /root/chatwoot-sdr-ia
sudo ./install.sh
```

---

## 🔐 Segurança

- ✅ Backup automático antes de cada instalação
- ✅ API Key armazenada apenas no .env (não exposta)
- ✅ Validação de todos os caminhos e arquivos
- ✅ Logs detalhados de todas as operações
- ✅ Transcrições de áudio deletadas após processamento

---

## 📈 Boas Práticas

### 1. Monitoramento Regular

```bash
# Criar script de monitoramento
cat > /root/monitor-sdr-ia.sh <<'MONITOR'
#!/bin/bash
echo "=== Estatísticas de Hoje ==="
docker logs chatwoot_sidekiq --since 24h | grep "\[SDR IA\]" | grep -c "Resposta enviada"
echo "Leads qualificados:"
docker logs chatwoot_sidekiq --since 24h | grep "\[Qualification\]" | grep -c "QUENTE\|MORNO"
echo "Áudios transcritos:"
docker logs chatwoot_sidekiq --since 24h | grep "\[Audio\]" | grep -c "Transcrição bem-sucedida"
MONITOR

chmod +x /root/monitor-sdr-ia.sh
```

### 2. Backup Regular

```bash
# Adicionar ao cron para backup semanal
echo "0 3 * * 0 tar -czf /root/backups/chatwoot-weekly-\$(date +\%Y\%m\%d).tar.gz /root/chatwoot" | crontab -
```

### 3. Otimização de Custos

- Buffer de 35s já reduz custos em ~70%
- Monitore uso da API OpenAI no dashboard: https://platform.openai.com/usage
- Considere usar GPT-3.5 Turbo para reduzir custos (configurável)

---

## 📞 Suporte

### Documentação Adicional

Após instalação, consulte:
- `/caminho/do/chatwoot/SDR_IA_CONFIG.md` - Documentação completa
- `/root/backups/` - Backups criados

### Contato para Suporte

Entre em contato com o fornecedor do sistema para:
- Suporte técnico
- Atualizações
- Customizações
- Treinamento

---

## 🔄 Atualizações

### Como Atualizar para Nova Versão

1. Backup automático será criado
2. Extrair nova versão
3. Executar `install.sh` novamente
4. Seguir instruções específicas da versão

---

## ⚠️ Importante

- Sempre mantenha backups atualizados
- Teste em ambiente de homologação primeiro
- Monitore logs após instalação
- Entre em contato com suporte se houver dúvidas

---

**Versão:** v2.1.1  
**Status:** ✅ Estável e Validado em Produção  
**Última Atualização:** Novembro 2025

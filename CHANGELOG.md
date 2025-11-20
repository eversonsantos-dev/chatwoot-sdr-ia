# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [Unreleased]

## [1.1.2] - 2025-11-20 às 22:26 UTC 🟢 VERSÃO FUNCIONAL - RECOMENDADA PARA BACKUP

### 🎯 Status da Versão
- ✅ **VERSÃO TOTALMENTE FUNCIONAL**
- ✅ **RECOMENDADA PARA BACKUP E RESTORE**
- ✅ **TESTADA E ESTÁVEL EM PRODUÇÃO**
- 📅 **Data/Hora**: 20 de Novembro de 2025 às 22:26 UTC
- 🔖 **Tag Git**: `v1.1.2`
- 🐳 **Imagem Docker**: `localhost/chatwoot-sdr-ia:542ffce`
- 📦 **Commit**: `542ffce`

### ⚠️ IMPORTANTE - Use Esta Versão Como Backup
Esta versão contém todas as funcionalidades do SDR IA funcionando corretamente:
- ✅ Fluxo conversacional completo com 6 perguntas
- ✅ Envio automático de mensagens aos leads
- ✅ Qualificação final via OpenAI após todas as respostas
- ✅ Interface administrativa funcional
- ✅ Armazenamento de configurações no banco de dados
- ✅ Listener registrado e detectando mensagens
- ✅ Jobs processando sem erros

**Se você precisar reverter para uma versão funcional, use esta!**

### Fixed
- 🐛 **CRÍTICO: Erro "undefined method 'agents' for Inbox" ao enviar mensagens**
  - **Problema**: `ConversationManager.send_message` tentava acessar `conversation.inbox.agents.first`
  - **Causa Raiz**: Classe `Inbox` do Chatwoot não possui método `agents`
  - **Erro Completo**: `undefined method 'agents' for an instance of Inbox`
  - **Impacto**: SDR IA detectava mensagens mas falhava ao tentar responder automaticamente
  - **Solução**: Substituído por `conversation.assignee || @account.users.first`
  - **Arquivo**: `plugins/sdr_ia/app/services/conversation_manager.rb:181-191`
  - **Resultado**: Mensagens agora são enviadas com sucesso ✅

### Changed
- 🔄 **Método `send_message` refatorado**
  ```ruby
  # ANTES (quebrado):
  sender: conversation.inbox.agents.first || @account.users.first

  # DEPOIS (funcional):
  sender = conversation.assignee || @account.users.first
  ```
  - Primeiro tenta usar o agente assignado à conversa
  - Se não houver assignee, usa o primeiro usuário da conta
  - Tratamento de erro melhorado com rescue
  - Log detalhado de sucesso/erro

### Technical Details

#### Fluxo de Mensagens Funcionando
1. ✅ WhatsApp → Chatwoot → `message.created` event
2. ✅ EventDispatcherJob → SDR IA Listener detecta
3. ✅ QualifyLeadJob agendado (delay de 2 segundos)
4. ✅ ConversationManager.process_message! executado
5. ✅ send_message() envia resposta automática
6. ✅ Progresso atualizado (0/6 → 1/6 → 2/6... → 6/6)
7. ✅ Após 6/6: Qualificação final via OpenAI

#### Arquivos Modificados
- **conversation_manager.rb** (linha 181-199)
  - Método `send_message` corrigido
  - Tratamento robusto de erros
  - Logs informativos

#### Logs Esperados (Funcionando)
```
[SDR IA] Nova mensagem incoming: contact_id=8
[SDR IA] Job agendado para 2 segundos
[SDR IA] Processando mensagem do contact 8
[SDR IA] Mensagem enviada: Olá! Sou o assistente virtual...
[SDR IA] Progresso atualizado: 1/6
```

#### Commit History
- `542ffce` - Fix: Correct sender assignment in send_message method

### Deployment

#### Como Fazer Backup Desta Versão
```bash
# 1. Salvar imagem Docker
docker save localhost/chatwoot-sdr-ia:542ffce | gzip > chatwoot-sdr-ia-v1.1.2-backup.tar.gz

# 2. Backup do código
cd /root
tar -czf chatwoot-sdr-ia-v1.1.2-code.tar.gz chatwoot-sdr-ia/

# 3. Verificar tag Git
cd chatwoot-sdr-ia
git tag -v v1.1.2
```

#### Como Restaurar Esta Versão
```bash
# Opção 1: Via Git tag
cd /root/chatwoot-sdr-ia
git checkout v1.1.2
docker build -t localhost/chatwoot-sdr-ia:542ffce .
docker service update --image localhost/chatwoot-sdr-ia:542ffce chatwoot_chatwoot_sidekiq
docker service update --image localhost/chatwoot-sdr-ia:542ffce chatwoot_chatwoot_app

# Opção 2: Via imagem Docker salva
gunzip -c chatwoot-sdr-ia-v1.1.2-backup.tar.gz | docker load
docker service update --image localhost/chatwoot-sdr-ia:542ffce chatwoot_chatwoot_sidekiq
docker service update --image localhost/chatwoot-sdr-ia:542ffce chatwoot_chatwoot_app

# Opção 3: Via commit hash
cd /root/chatwoot-sdr-ia
git checkout 542ffce
# seguir passos do Opção 1
```

#### Verificação Pós-Deploy
```bash
# 1. Verificar serviços
docker service ps chatwoot_chatwoot_sidekiq
docker service ps chatwoot_chatwoot_app

# 2. Verificar logs do SDR IA
docker service logs -f chatwoot_chatwoot_sidekiq | grep "\[SDR IA\]"

# 3. Testar enviando mensagem via WhatsApp
# Deve aparecer: "[SDR IA] Mensagem enviada: ..."
```

### Breaking Changes
Nenhuma. Atualização totalmente compatível com v1.1.1.

### Known Issues
Nenhum. Todos os problemas críticos foram resolvidos.

### Performance
- Delay de 2 segundos entre receber e processar mensagem (por design)
- Envio de mensagens instantâneo após processamento
- Qualificação final (após 6 respostas) depende da latência da OpenAI API (~2-5 segundos)

### Security Notes
- Mensagens criadas com sender apropriado (assignee ou admin)
- Validação de custom_attributes preservada
- Logs não expõem dados sensíveis

---

## [1.1.1] - 2025-11-20

### Fixed
- 🐛 **Erro "TypeError: x.put is not a function" ao salvar configurações**
  - **Problema raiz**: Interface Vue.js estava usando `accountAPI.put()` que não existe na API do Chatwoot
  - **Solução**: Substituído por chamadas diretas ao `axios.put/get/post`
  - Afetou: `frontend/routes/dashboard/settings/sdr-ia/Index.vue:133-181`
  - Funções corrigidas: `saveSettings`, `loadSettings`, `loadStats`, `loadTeams`, `testQualification`

- 🐛 **Assets compilados não sendo atualizados no navegador**
  - **Problema**: Volume Docker `chatwoot_public` sobrescrevia assets novos com antigos
  - **Causa**: Assets compilados estavam na imagem mas o volume montado tinha versão antiga
  - **Solução**: Script de deploy agora copia todos os assets da imagem para o volume
  - Hashes atualizados: `dashboard-Kor-mld7.js`, `Index-C235wyqW.js`, `DashboardIcon-Clsh_-4Z.js`

- 🐛 **Ordem incorreta no Dockerfile causando cache de Vite**
  - **Problema**: Cache era limpo DEPOIS de copiar arquivos frontend
  - **Solução**: Reordenado para limpar cache → copiar arquivos → compilar
  - Adicionada verificação: exibe primeiras 5 linhas do Index.vue para confirmar `/* global axios */`

### Changed
- 📦 **Dockerfile otimizado para compilação de assets**
  - Cache do Vite limpo ANTES de copiar arquivos (linha 46-50)
  - Verificação automática do arquivo copiado (linha 59-62)
  - Garante que Vite compila código fonte correto

- 🔄 **Processo de deploy atualizado**
  - Copia TODOS os arquivos de `/app/public` para volume `chatwoot_public`
  - Não apenas `/vite`, mas também manifests e outros assets
  - Previne incompatibilidade de hashes entre HTML e assets

### Technical Details
- **Commit**: `e554c4d`
- **Imagem Docker**: `localhost/chatwoot-sdr-ia:e554c4d`
- **Arquivos modificados**:
  - `Dockerfile` (linhas 46-62)
  - `frontend/routes/dashboard/settings/sdr-ia/Index.vue` (5 funções)
  - Scripts de deploy atualizados
- **Verificação**:
  - ✅ `Index-C235wyqW.js` contém 5 ocorrências de `axios`
  - ✅ 0 ocorrências de `accountAPI`
  - ✅ Assets datados de Nov 20 17:47 (atualizados)

### Breaking Changes
Nenhuma. Atualização totalmente compatível com versão anterior.

### Deployment Notes
Após atualizar para esta versão:
1. Reconstruir imagem Docker: `./rebuild.sh`
2. Deploy: `./deploy.sh` ou `docker service update --image localhost/chatwoot-sdr-ia:e554c4d`
3. Copiar assets para volume: `docker run --rm -v chatwoot_public:/old localhost/chatwoot-sdr-ia:e554c4d sh -c "rm -rf /old/* && cp -r /app/public/* /old/"`
4. Limpar cache do navegador no primeiro acesso

---

## [1.1.0] - 2025-11-20

### Added
- 🎨 **Interface Visual Completa para Configuração de Prompts**
  - Editor de prompts do sistema e análise diretamente no painel
  - 4 abas organizadas: Configurações Gerais, Prompts da IA, Perguntas por Etapa, Sistema de Scoring
  - Configuração visual de todas as 6 perguntas do SDR
  - Gerenciamento de procedimentos com adicionar/remover
  - Configuração de pesos de scoring em tempo real
  - Thresholds de temperatura ajustáveis visualmente
  - Menu lateral com ícone "brain" e label "SDR IA"
  - Rota: `/accounts/:accountId/settings/sdr-ia`

- 💾 **Configurações Armazenadas no Banco de Dados**
  - Migration `20251120152500_add_prompts_to_sdr_ia_configs.rb`
  - Novos campos: `prompt_system` (text), `prompt_analysis` (text), `perguntas_etapas` (jsonb)
  - Cada conta pode ter configuração própria
  - API Key OpenAI armazenada no banco com segurança
  - Fallback automático para YAML caso banco não esteja disponível
  - Valores padrão populados automaticamente

- 🔌 **API Endpoints**
  - GET `/api/v1/accounts/:accountId/sdr_ia/config` - Buscar configuração
  - PUT `/api/v1/accounts/:accountId/sdr_ia/config` - Atualizar configuração
  - Autenticação via API key do Chatwoot
  - Permissões: apenas administradores

### Changed
- 🔄 **Módulo SdrIa Atualizado**
  - Busca configurações do banco de dados primeiro
  - Fallback inteligente para arquivos YAML
  - Suporta configuração por conta (multi-tenant)
  - Método `SdrIa.config(account)` aceita parâmetro opcional de conta

- 🤖 **Serviços Atualizados**
  - `LeadQualifier` agora usa prompts do banco (`plugins/sdr_ia/app/services/lead_qualifier.rb:14`)
  - `OpenaiClient` busca API key do banco primeiro (`plugins/sdr_ia/app/services/openai_client.rb:12`)
  - Suporte a passar account para configurações específicas
  - Método `load_prompts_from_yaml` como fallback seguro

- 📦 **Dockerfile Atualizado**
  - Agora copia ambas as migrations (linha 27-28)
  - Assets do frontend recompilados com Vite
  - Suporte completo para Vue.js 3 Composition API

### Technical Details

#### Arquivos Modificados/Criados
- `db/migrate/20251120152500_add_prompts_to_sdr_ia_configs.rb` (novo)
- `models/sdr_ia_config.rb` (atualizado - método `to_config_hash`)
- `frontend/routes/dashboard/settings/sdr-ia/Index.vue` (910 linhas)
- `plugins/sdr_ia/lib/sdr_ia.rb` (atualizado - método `config`)
- `plugins/sdr_ia/app/services/lead_qualifier.rb` (atualizado)
- `plugins/sdr_ia/app/services/openai_client.rb` (atualizado)
- `Dockerfile` (atualizado - linha 27-28)

#### Interface Vue.js (910 linhas)
**Componentes Principais:**
- Tab 1 - Configurações Gerais: Toggle de ativação, debug, modelo OpenAI, temperatura, max tokens
- Tab 2 - Prompts da IA: Editores de texto para prompt do sistema e prompt de análise
- Tab 3 - Perguntas por Etapa: 6 campos editáveis (nome, interesse, urgência, conhecimento, motivação, localização)
- Tab 4 - Sistema de Scoring: Sliders para pesos de urgência, conhecimento e thresholds de temperatura

### Benefits
- ✅ Não precisa mais editar arquivos YAML manualmente
- ✅ Teste rápido de ajustes nos prompts sem restart
- ✅ Configuração 100% pelo painel administrativo
- ✅ Alterações em tempo real
- ✅ Multi-tenant ready (cada conta tem sua config)
- ✅ Interface intuitiva com validação de campos
- ✅ Botão "Salvar Configurações" com feedback visual

### Deployment
- **Imagem**: `localhost/chatwoot-sdr-ia:6cd5b5c`
- **Build Date**: 2025-11-20
- **Container ID**: 6bb4126452e8
- **Status**: ✅ Deployed e rodando

---

## [1.0.0] - 2025-11-20

### ✅ Status Atual
- **Módulo**: Totalmente operacional
- **Deploy**: Docker Swarm com imagem customizada
- **Commit**: `18256b8`
- **Imagem**: `localhost/chatwoot-sdr-ia:latest` (2.43GB)

### Added
- ✨ Módulo SDR IA completo para qualificação automática de leads
- 🎨 Interface administrativa Vue.js com dashboard e configurações
- 🤖 Integração com OpenAI (GPT-4, GPT-4 Turbo, GPT-3.5)
- 📊 Sistema de scoring 0-100 para leads
- 🌡️ Classificação por temperatura (Quente, Morno, Frio, Muito Frio)
- 🔄 Processamento assíncrono com Sidekiq
- 📝 16 custom attributes para Contact
- 🏷️ 14 labels automáticas para categorização
- 🚀 Dockerfile profissional para build customizado
- 📜 Scripts automatizados:
  - `install.sh` - Instalação rápida
  - `rebuild.sh` - Build da imagem Docker
  - `deploy.sh` - Deploy no Docker Swarm
  - `update.sh` - Atualização do módulo
  - `uninstall.sh` - Remoção completa
- 📚 Documentação completa:
  - `README.md` - Guia principal
  - `DEPLOY.md` - Guia de deploy
  - `docs/SDR_IA_MODULE_DOCUMENTATION.md`
  - `docs/SDR_IA_ADMIN_INTERFACE.md`
  - `docs/testar_sdr_ia.sh`

### Fixed
- 🐛 Compilação de assets frontend no Docker
- 🐛 Cache do Vite sendo limpo antes do rebuild
- 🐛 Paths do initializer para estrutura Docker
- 🐛 Permissões de usuário no Dockerfile
- 🐛 Assets sendo incluídos corretamente na imagem

### Technical Details

#### Arquitetura
```
WhatsApp → Chatwoot → SDR IA Listener → Sidekiq Job →
LeadQualifier Service → OpenAI API → PostgreSQL
```

#### Componentes Principais
- **Backend**: Ruby on Rails 7.0.8
- **Frontend**: Vue.js
- **Queue**: Sidekiq
- **Database**: PostgreSQL 12+
- **Cache**: Redis 6+
- **AI**: OpenAI GPT-4

#### Estrutura de Arquivos
```
plugins/sdr_ia/
├── app/
│   ├── services/
│   │   ├── openai_client.rb
│   │   └── lead_qualifier.rb
│   ├── jobs/
│   │   └── qualify_lead_job.rb
│   └── listeners/
│       └── sdr_ia_listener.rb
├── config/
│   ├── settings.yml
│   ├── prompts.yml
│   └── routes.rb
└── lib/
    └── sdr_ia.rb
```

---

## [0.1.0] - 2025-11-20 (Versões Anteriores)

### 2025-11-20 - Commit 18256b8
**Fixed**: Asset compilation - clear all Vite caches before rebuild
- Limpeza completa de cache do Vite antes do rebuild
- Resolve problemas de assets não atualizando

### 2025-11-20 - Commit 0312044
**Fixed**: Tentar limpar assets antes de recompilar
- Primeira tentativa de limpar assets antigos
- Melhoria no processo de build

### 2025-11-20 - Commit de1ee57
**Added**: Compilação de assets frontend no Dockerfile
- Assets frontend sendo compilados durante build
- Instalação do pnpm no Dockerfile

### 2025-11-20 - Commit 48c8002
**Fixed**: Corrigir paths do initializer para estrutura Docker
- Paths corretos para ambiente Docker
- Inicialização mais confiável

### 2025-11-20 - Commit 6fd853d
**Fixed**: Corrigir permissões de usuário no Dockerfile
- Permissões corretas para arquivos
- Melhor segurança

### 2025-11-20 - Commit a1fda7a
**Added**: Docker Build profissional para produção
- Dockerfile otimizado
- Multi-stage build
- Imagem customizada baseada em chatwoot/chatwoot:v4.1.0

### 2025-11-20 - Commit 71d6eee
**Added**: Scripts automatizados de instalação, atualização e desinstalação
- `install.sh` - Instalação automática
- `update.sh` - Atualização do módulo
- `uninstall.sh` - Remoção completa com backup

### 2025-11-20 - Commit a382d9f
**Added**: Initial commit - Chatwoot SDR IA Module
- Versão inicial do módulo
- Todas as funcionalidades core
- Documentação inicial

---

## Categorias de Mudanças

- **Added** (✨): Novas funcionalidades
- **Changed** (🔄): Mudanças em funcionalidades existentes
- **Deprecated** (⚠️): Funcionalidades que serão removidas
- **Removed** (🗑️): Funcionalidades removidas
- **Fixed** (🐛): Correções de bugs
- **Security** (🔒): Correções de vulnerabilidades

---

## Notas de Versão

### Como Atualizar

```bash
cd /root/chatwoot-sdr-ia
git pull origin main
./rebuild.sh
./deploy.sh
```

### Rollback

Se precisar voltar para uma versão anterior:

```bash
# Ver imagens disponíveis
docker images | grep chatwoot-sdr-ia

# Voltar para commit específico
docker service update --image localhost/chatwoot-sdr-ia:<commit-hash> chatwoot_chatwoot_app
docker service update --image localhost/chatwoot-sdr-ia:<commit-hash> chatwoot_chatwoot_sidekiq
```

### Compatibilidade

- **Chatwoot**: v4.1.0 ou superior
- **Ruby**: 3.3.3
- **Rails**: 7.0.8+
- **PostgreSQL**: 12+
- **Redis**: 6+
- **Docker**: 20.10+

---

## Links

- [GitHub Repository](https://github.com/eversonsantos-dev/chatwoot-sdr-ia)
- [Issues](https://github.com/eversonsantos-dev/chatwoot-sdr-ia/issues)
- [Documentation](README.md)
- [Deploy Guide](DEPLOY.md)

---

**Desenvolvido com ❤️ por [@eversonsantos-dev](https://github.com/eversonsantos-dev)**

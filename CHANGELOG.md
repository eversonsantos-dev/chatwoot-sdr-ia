# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [Unreleased]

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

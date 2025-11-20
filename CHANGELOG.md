# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [Unreleased]

### Em Desenvolvimento
- Aguardando novas features e melhorias

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

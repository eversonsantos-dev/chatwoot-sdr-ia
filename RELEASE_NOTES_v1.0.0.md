# Release v1.0.0 - Módulo SDR IA Completo

**Data**: 20/11/2025
**Commit**: `18256b8`
**Tag**: `v1.0.0`

## 🎯 Primeira Release Oficial

Lançamento inicial do módulo SDR IA para Chatwoot com qualificação automática de leads via OpenAI.

## ✨ Funcionalidades Principais

### 🤖 Qualificação Automática de Leads
- Sistema completo de SDR (Sales Development Representative) automatizado
- Integração nativa com OpenAI (GPT-4, GPT-4 Turbo, GPT-3.5)
- Processamento assíncrono com Sidekiq
- Qualificação inteligente baseada em conversas

### 📊 Sistema de Scoring
- Pontuação de 0-100 para cada lead
- Avaliação baseada em múltiplos fatores:
  - Interesse no procedimento
  - Urgência
  - Conhecimento prévio
  - Localização
  - Motivação

### 🌡️ Classificação por Temperatura
- **Quente**: Leads prontos para fechar
- **Morno**: Leads com potencial
- **Frio**: Leads em fase inicial
- **Muito Frio**: Leads sem interesse

### 📝 Custom Attributes
16 atributos customizados para Contact:
- `sdr_ia_status`
- `sdr_ia_temperatura`
- `sdr_ia_score`
- `sdr_ia_nome`
- `sdr_ia_interesse`
- `sdr_ia_urgencia`
- `sdr_ia_conhecimento`
- `sdr_ia_motivacao`
- `sdr_ia_localizacao`
- `sdr_ia_comportamento`
- `sdr_ia_resumo`
- `sdr_ia_proximo_passo`
- `sdr_ia_qualificado_em`
- E mais...

### 🏷️ Labels Automáticas
14 labels para categorização instantânea:
- Temperatura (Quente, Morno, Frio, Muito Frio)
- Interesse (Alto, Médio, Baixo)
- Urgência (Imediata, 2 Semanas, 1 Mês, Pesquisando)
- Próximos passos (Transferir Closer, Agendar Follow-up, etc.)

### 🎨 Interface Administrativa
- Dashboard completo em Vue.js
- Painel de configurações
- Visualização de estatísticas
- Gestão de prompts e regras

### 🐳 Deploy Profissional
- Dockerfile customizado baseado em `chatwoot/chatwoot:v4.1.0`
- Build otimizado com multi-stage
- Scripts automatizados:
  - `install.sh` - Instalação rápida
  - `rebuild.sh` - Build da imagem
  - `deploy.sh` - Deploy no Docker Swarm
  - `update.sh` - Atualização do módulo
  - `uninstall.sh` - Remoção completa com backup

## 📚 Documentação

- README.md completo com guia de instalação
- DEPLOY.md com instruções de produção
- docs/SDR_IA_MODULE_DOCUMENTATION.md
- docs/SDR_IA_ADMIN_INTERFACE.md
- Script de testes: docs/testar_sdr_ia.sh

## 🔧 Arquitetura

```
WhatsApp → Chatwoot → SDR IA Listener → Sidekiq Job →
LeadQualifier Service → OpenAI API → PostgreSQL
```

### Componentes
- **Backend**: Ruby on Rails 7.0.8
- **Frontend**: Vue.js
- **Queue**: Sidekiq
- **Database**: PostgreSQL 12+
- **Cache**: Redis 6+
- **AI**: OpenAI GPT-4

## 📦 Instalação

```bash
# Clone o repositório
git clone https://github.com/eversonsantos-dev/chatwoot-sdr-ia.git
cd chatwoot-sdr-ia

# Checkout v1.0.0
git checkout v1.0.0

# Instalar
./install.sh
```

## 🚀 Deploy

```bash
# Build da imagem
./rebuild.sh

# Deploy
./deploy.sh
```

## ⚙️ Requisitos

- Chatwoot v4.1.0 ou superior
- Ruby 3.3.3
- Rails 7.0.8+
- PostgreSQL 12+
- Redis 6+
- Docker 20.10+
- OpenAI API Key

## 📄 Licença

MIT License

## 👨‍💻 Desenvolvedor

**Everson Santos**
GitHub: [@eversonsantos-dev](https://github.com/eversonsantos-dev)

---

**Desenvolvido com ❤️ para transformar atendimento em vendas!**

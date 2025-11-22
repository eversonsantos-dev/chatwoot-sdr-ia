# Release v1.1.0 - Interface Visual Completa

**Data**: 20/11/2025
**Commit**: `6cd5b5c`
**Tag**: `v1.1.0`

## 🎨 Interface Visual para Configuração de Prompts

Esta release adiciona uma interface administrativa completa para gerenciar todas as configurações do SDR IA sem precisar editar arquivos manualmente.

## ✨ Novidades

### 🖥️ Painel Administrativo Completo
- **4 Abas Organizadas**:
  1. **Configurações Gerais**: Toggle de ativação, debug, modelo OpenAI, temperatura, max tokens
  2. **Prompts da IA**: Editores de texto para prompt do sistema e prompt de análise
  3. **Perguntas por Etapa**: 6 campos editáveis (nome, interesse, urgência, conhecimento, motivação, localização)
  4. **Sistema de Scoring**: Sliders para pesos de urgência, conhecimento e thresholds de temperatura

### 💾 Configurações no Banco de Dados
- **Nova Migration**: `20251120152500_add_prompts_to_sdr_ia_configs.rb`
- **Novos Campos**:
  - `prompt_system` (text) - Prompt do sistema
  - `prompt_analysis` (text) - Prompt de análise
  - `perguntas_etapas` (jsonb) - Perguntas personalizadas por etapa
- Configuração específica por conta (multi-tenant)
- API Key OpenAI armazenada com segurança
- Fallback automático para YAML se banco indisponível

### 🔌 API Endpoints
- `GET /api/v1/accounts/:accountId/sdr_ia/config` - Buscar configuração
- `PUT /api/v1/accounts/:accountId/sdr_ia/config` - Atualizar configuração
- Autenticação via API key do Chatwoot
- Permissões: apenas administradores

### 🔄 Módulo SdrIa Aprimorado
- Busca configurações do banco primeiro
- Fallback inteligente para arquivos YAML
- Suporte completo multi-tenant
- Método `SdrIa.config(account)` aceita parâmetro de conta

## 🔧 Mudanças Técnicas

### Arquivos Criados
- `db/migrate/20251120152500_add_prompts_to_sdr_ia_configs.rb`
- `frontend/routes/dashboard/settings/sdr-ia/Index.vue` (910 linhas)

### Arquivos Modificados
- `models/sdr_ia_config.rb` - Método `to_config_hash` atualizado
- `plugins/sdr_ia/lib/sdr_ia.rb` - Método `config` com suporte a account
- `plugins/sdr_ia/app/services/lead_qualifier.rb` - Usa prompts do banco
- `plugins/sdr_ia/app/services/openai_client.rb` - Busca API key do banco
- `Dockerfile` - Copia ambas migrations

## ✅ Benefícios

- ✅ Não precisa mais editar YAML manualmente
- ✅ Teste rápido de ajustes sem restart
- ✅ Configuração 100% pelo painel
- ✅ Alterações em tempo real
- ✅ Multi-tenant ready
- ✅ Interface intuitiva com validação
- ✅ Feedback visual ao salvar

## 📦 Upgrade de v1.0.0

```bash
cd /root/chatwoot-sdr-ia
git checkout v1.1.0
./rebuild.sh
./deploy.sh

# Rodar migration
docker exec <container> bundle exec rails db:migrate
```

## 🐛 Bugs Conhecidos

Nenhum bug crítico conhecido nesta release.

## 📄 Compatibilidade

- Totalmente compatível com v1.0.0
- Migrations rodam automaticamente
- Configurações antigas preservadas

---

**Desenvolvido com ❤️ por Everson Santos**

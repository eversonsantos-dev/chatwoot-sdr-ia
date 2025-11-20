# INTERFACE ADMINISTRATIVA SDR IA - INSTALADA

**Data:** 2025-11-20
**Status:** ✅ Interface Completa Instalada

---

## O QUE FOI FEITO

Criei uma **interface visual completa** para gerenciar o módulo SDR IA diretamente no painel do Chatwoot, sem precisar editar arquivos YAML manualmente.

### Componentes Instalados

#### 1. **Backend API Controller** ✅
- Localização: `/app/app/controllers/api/v1/accounts/sdr_ia/settings_controller.rb`
- Endpoints criados:
  - `GET /api/v1/accounts/:account_id/sdr_ia/settings` - Carregar configurações
  - `PUT /api/v1/accounts/:account_id/sdr_ia/settings` - Salvar configurações
  - `POST /api/v1/accounts/:account_id/sdr_ia/test` - Testar qualificação manual
  - `GET /api/v1/accounts/:account_id/sdr_ia/stats` - Estatísticas de leads
  - `GET /api/v1/accounts/:account_id/sdr_ia/teams` - Listar times disponíveis

#### 2. **Frontend Vue.js** ✅
- Localização: `/app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia/Index.vue`
- Interface responsiva e moderna
- Suporta tema escuro (dark mode)
- Formulários intuitivos para todas as configurações

#### 3. **Rotas Configuradas** ✅
- Rota adicionada: `/accounts/:accountId/settings/sdr-ia`
- Arquivo: `/app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js`
- Rota do plugin: `/app/plugins/sdr_ia/config/routes.rb`

#### 4. **Menu Lateral (Sidebar)** ✅
- Item "SDR IA" adicionado ao menu de Configurações
- Aparece entre "Robôs" e "Auditoria"
- Ícone: ✨ (sparkles)
- Tradução: PT-BR e EN
- Permissão: Apenas administradores

---

## COMO ACESSAR

### Passo 1: Fazer Login
Acesse o Chatwoot: **https://chatteste.nexusatemporal.com**

### Passo 2: Navegar até Configurações
1. Faça login como **administrador**
2. Clique no ícone de **Configurações** no menu lateral esquerdo
3. Procure o item **"SDR IA"** na lista (deve aparecer após "Robôs")
4. Clique em **"SDR IA"**

### Passo 3: Você Verá

#### Dashboard de Estatísticas
- **Total Qualificados** - Leads que passaram pela qualificação
- **Quentes** - Leads de alta prioridade (score ≥ 70)
- **Mornos** - Leads de média prioridade (score ≥ 40)
- **Frios** - Leads de baixa prioridade (score ≥ 20)
- **Muito Frios** - Leads muito frios (score < 20)

#### Configurações Gerais
- **Módulo Ativo** - Liga/desliga o módulo SDR IA
- **Modo Debug** - Ativa logs detalhados
- **Modelo OpenAI** - Escolha entre GPT-4 Turbo, GPT-4, GPT-3.5 Turbo

#### Limites de Temperatura
- **Quente (mínimo)** - Score mínimo para considerar lead quente (padrão: 70)
- **Morno (mínimo)** - Score mínimo para considerar lead morno (padrão: 40)

#### Atribuição Automática
- **Time para Leads Quentes** - Selecione o time que receberá leads quentes automaticamente
- **Time para Leads Mornos** - Selecione o time que receberá leads mornos automaticamente

#### Testar Qualificação
- Digite o **ID de um contato** existente
- Clique em **"Testar"**
- Veja o resultado da qualificação em tempo real

---

## FUNCIONALIDADES DA INTERFACE

### ✅ O Que Você Pode Fazer

1. **Ativar/Desativar o Módulo**
   - Toggle simples para ligar/desligar

2. **Alterar Modelo de IA**
   - Escolher entre GPT-4 Turbo (recomendado), GPT-4, ou GPT-3.5 Turbo

3. **Ajustar Scoring**
   - Modificar os limites de temperatura (quente/morno)
   - As alterações são salvas diretamente no `settings.yml`

4. **Configurar Times**
   - Atribuir automaticamente leads quentes para um time específico
   - Atribuir automaticamente leads mornos para outro time

5. **Testar Qualificação**
   - Testar o módulo com um contato específico
   - Ver resultado instantâneo (temperatura e score)

6. **Ver Estatísticas**
   - Acompanhar quantos leads foram qualificados
   - Distribuição por temperatura

### 🔄 Salvar Configurações

1. Faça as alterações desejadas
2. Clique no botão **"Salvar Configurações"**
3. As configurações são salvas em `/app/plugins/sdr_ia/config/settings.yml`
4. O módulo recarrega automaticamente a configuração

---

## CONFIGURAÇÃO NECESSÁRIA

### ⚠️ IMPORTANTE: Configure a OpenAI API Key

A interface está pronta, mas você ainda precisa **configurar a chave da OpenAI** para o módulo funcionar.

#### Como Configurar

Edite o arquivo `/root/chatwoot.yaml` e adicione a variável de ambiente `OPENAI_API_KEY` nas seções `chatwoot_app` e `chatwoot_sidekiq`:

```yaml
services:
  chatwoot_app:
    environment:
      # ... outras variáveis ...
      - OPENAI_API_KEY=sk-proj-SUA_CHAVE_AQUI

  chatwoot_sidekiq:
    environment:
      # ... outras variáveis ...
      - OPENAI_API_KEY=sk-proj-SUA_CHAVE_AQUI
```

Depois, faça o redeploy:

```bash
docker stack deploy -c /root/chatwoot.yaml chatwoot
```

---

## ARQUITETURA TÉCNICA

### Backend (Rails)

**Controller**: `Api::V1::Accounts::SdrIa::SettingsController`
- Herda de `Api::V1::Accounts::BaseController`
- Usa `check_admin_authorization?` para segurança
- Métodos:
  - `show` - Carrega settings.yml via YAML.load_file
  - `update` - Deep merge de configurações + File.write
  - `test_qualification` - Executa `SdrIa::LeadQualifier.new(contact: contact).qualify!`
  - `stats` - Query no PostgreSQL para contar leads por temperatura
  - `teams` - Lista times da conta

**Routes**: `/api/v1/accounts/:account_id/sdr_ia/*`

### Frontend (Vue.js 3)

**Component**: `Index.vue` (Composition API)
- Usa `useStore`, `useStoreGetters`, `useAdmin`, `useI18n`
- Reactive refs para estado do formulário
- Integração com `accountAPI` para chamadas HTTP
- Grid responsivo com Tailwind CSS

**Features**:
- Dark mode support
- Form validation
- Loading states
- Error handling
- Toast notifications

### Arquivos Modificados

1. `/app/app/controllers/api/v1/accounts/sdr_ia/settings_controller.rb` (novo)
2. `/app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia/Index.vue` (novo)
3. `/app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia/sdr-ia.routes.js` (novo)
4. `/app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js` (modificado - adicionado import e rota)
5. `/app/app/javascript/dashboard/components/layout/config/sidebarItems/settings.js` (modificado - adicionado menu item)
6. `/app/app/javascript/dashboard/i18n/locale/pt_BR/settings.json` (modificado - adicionado "SDR_IA": "SDR IA")
7. `/app/app/javascript/dashboard/i18n/locale/en/settings.json` (modificado - adicionado "SDR_IA": "SDR AI")
8. `/app/plugins/sdr_ia/config/routes.rb` (novo)
9. `/app/plugins/sdr_ia/lib/sdr_ia.rb` (modificado - adicionado load de rotas)

---

## PRÓXIMOS PASSOS

### ✅ Já Feito
- Interface administrativa completa instalada
- Backend API funcionando
- Frontend Vue.js responsivo
- Menu lateral configurado
- Traduções em PT-BR e EN
- Serviços reiniciados

### 🔲 Para Você Fazer

1. **Configure a OpenAI API Key** (urgente)
   - Edite `/root/chatwoot.yaml`
   - Adicione `OPENAI_API_KEY=sk-proj-...`
   - Redeploy: `docker stack deploy -c /root/chatwoot.yaml chatwoot`

2. **Acesse a Interface**
   - Login → Configurações → SDR IA
   - Verifique se aparece corretamente

3. **Configure os Times** (opcional)
   - Na interface, selecione times para atribuição automática
   - Salve as configurações

4. **Teste com um Lead Real**
   - Encontre o ID de um contato no Chatwoot
   - Use a função "Testar Qualificação"
   - Verifique se retorna temperatura e score

---

## TROUBLESHOOTING

### Problema: Menu "SDR IA" não aparece

**Possível causa**: Cache do browser

**Solução**:
```bash
# Hard refresh no navegador
Ctrl + Shift + R (Windows/Linux)
Cmd + Shift + R (Mac)
```

### Problema: Erro 500 ao acessar configurações

**Possível causa**: Routes não carregadas

**Solução**:
```bash
# Reiniciar serviço
docker service update --force chatwoot_chatwoot_app
```

### Problema: "Unauthorized" ao salvar

**Possível causa**: Usuário não é administrador

**Solução**:
- Apenas usuários com role "administrator" podem acessar
- Verifique suas permissões no Chatwoot

### Problema: Configurações não salvam

**Possível causa**: Arquivo settings.yml não tem permissão de escrita

**Solução**:
```bash
docker exec <CONTAINER_ID> chmod 666 /app/plugins/sdr_ia/config/settings.yml
```

---

## MONITORAMENTO

### Ver Logs da Interface

```bash
# Logs do backend (API)
docker service logs chatwoot_chatwoot_app -f | grep "SDR IA"

# Logs do Rails
docker exec <CONTAINER_ID> tail -f /app/log/production.log | grep "SDR IA"
```

### Testar API Diretamente

```bash
# Obter configurações
curl -H "Authorization: Bearer <TOKEN>" \
  https://chatteste.nexusatemporal.com/api/v1/accounts/1/sdr_ia/settings

# Obter estatísticas
curl -H "Authorization: Bearer <TOKEN>" \
  https://chatteste.nexusatemporal.com/api/v1/accounts/1/sdr_ia/stats
```

---

## RESUMO

✅ **Interface Administrativa Completa**
- Backend API com 5 endpoints
- Frontend Vue.js moderno e responsivo
- Menu integrado ao Chatwoot
- Traduções PT-BR e EN
- Permissões apenas para admin

🎯 **Acesso**:
`https://chatteste.nexusatemporal.com` → Configurações → **SDR IA**

⚠️ **Falta Apenas**:
Configurar `OPENAI_API_KEY` no `chatwoot.yaml` e fazer redeploy

---

**Instalação Concluída com Sucesso!** 🎉

*Agora você pode gerenciar todo o módulo SDR IA visualmente, sem editar arquivos!*

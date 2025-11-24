# PLANO DE DESENVOLVIMENTO - Chatwoot SDR IA

**Versão do Documento:** 1.0
**Data de Criação:** 22 de Novembro de 2025
**Última Atualização:** 22 de Novembro de 2025
**Versão Atual do Sistema:** v2.0.0-patch2 (aa4bd4f)

---

## 📋 ÍNDICE

1. [Visão Geral](#visão-geral)
2. [Arquitetura Atual](#arquitetura-atual)
3. [Roadmap de Funcionalidades](#roadmap-de-funcionalidades)
4. [Pendências Técnicas](#pendências-técnicas)
5. [Melhorias de Infraestrutura](#melhorias-de-infraestrutura)
6. [Cronograma](#cronograma)
7. [Riscos e Mitigações](#riscos-e-mitigações)

---

## 🎯 VISÃO GERAL

### Objetivo do Projeto
Criar um sistema de qualificação automática de leads integrado ao Chatwoot, usando Inteligência Artificial (OpenAI GPT-4) para:
- Conversar naturalmente com leads via WhatsApp
- Coletar informações de forma conversacional
- Qualificar leads automaticamente (Quente/Morno/Frio/Muito Frio)
- Distribuir leads para times especializados
- Reduzir workload do time comercial em 80%

### Estado Atual
- ✅ **Funcionalidades Core:** 100% implementadas
- ✅ **Integração WhatsApp:** Funcionando via WAHA
- ✅ **IA Conversacional:** GPT-4 Turbo operacional
- ✅ **Qualificação Automática:** Sistema de scoring implementado
- ✅ **Painel Administrativo:** Funcional (v2.0.0-patch2)
- ⚠️ **Bugs Conhecidos:** Mensagens duplicadas (patches 3 e 4 revertidos)

### Próximos Marcos
1. **v2.1.0** - Correção de bugs e otimizações (1-2 semanas)
2. **v2.2.0** - Analytics e relatórios avançados (3-4 semanas)
3. **v3.0.0** - Múltiplos modelos de IA e A/B testing (2-3 meses)

---

## 🏗️ ARQUITETURA ATUAL

### Stack Tecnológico

#### Backend
- **Framework:** Ruby on Rails 7.0.8
- **Base:** Chatwoot v4.1.0
- **Banco de Dados:** PostgreSQL 15
- **Cache:** Redis 7.x
- **Background Jobs:** Sidekiq
- **IA:** OpenAI GPT-4 Turbo

#### Frontend
- **Framework:** Vue.js 3 (Composition API)
- **Build Tool:** Vite
- **UI Components:** Chatwoot Design System
- **State Management:** Vuex

#### Infraestrutura
- **Orquestração:** Docker Swarm
- **Containers:** Docker
- **Reverse Proxy:** Nginx (presumido)
- **Integração WhatsApp:** WAHA (WhatsApp HTTP API)

### Componentes Principais

```
┌─────────────────────────────────────────────────────────────┐
│                        CHATWOOT SDR IA                       │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   WhatsApp   │──────│     WAHA     │──────│  Chatwoot    │
│   (Cliente)  │      │   Webhook    │      │   Webhook    │
└──────────────┘      └──────────────┘      └──────────────┘
                                                     │
                                                     ▼
                              ┌──────────────────────────────┐
                              │   AsyncDispatcher            │
                              │   + SdrIaListener            │
                              └──────────────────────────────┘
                                           │
                                           ▼
                              ┌──────────────────────────────┐
                              │  ConversationManagerV2       │
                              │  - Conversação Natural       │
                              │  - Qualificação Automática   │
                              │  - Distribuição para Times   │
                              └──────────────────────────────┘
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    ▼                      ▼                      ▼
           ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
           │  OpenAI     │       │ PostgreSQL  │       │   Sidekiq   │
           │  GPT-4      │       │  Database   │       │   Jobs      │
           └─────────────┘       └─────────────┘       └─────────────┘
```

### Fluxo de Qualificação

```
1. Lead envia mensagem via WhatsApp
   ↓
2. WAHA webhook → Chatwoot → AsyncDispatcher
   ↓
3. SdrIaListener detecta nova mensagem
   ↓
4. ConversationManagerV2 processa:
   - Coleta informações (nome, interesse, urgência, conhecimento, localização)
   - Mantém conversa natural via OpenAI GPT-4
   - Detecta sinais de qualificação
   ↓
5. Após 5 informações coletadas:
   - Envia histórico completo para OpenAI
   - Recebe análise estruturada (JSON)
   - Calcula score (0-130 pontos)
   - Determina temperatura (Quente/Morno/Frio/Muito Frio)
   ↓
6. Ações automáticas:
   - Atribui lead ao time apropriado
   - Envia mensagem de encerramento
   - Salva custom attributes no contato
   - Registra logs detalhados
```

---

## 🗺️ ROADMAP DE FUNCIONALIDADES

### FASE 1 - Correções e Estabilização (v2.1.0)
**Prazo:** 1-2 semanas
**Status:** 🔴 Pendente

#### Features
- [ ] **Bug Fix: Mensagens Duplicadas**
  - Reimplementar Patch3 (mensagem conversacional + closing message)
  - Reimplementar Patch4 (lead quente redundante)
  - Validação completa em staging
  - Deploy incremental com monitoramento

- [ ] **Bug Fix: Painel Administrativo**
  - Investigar problema de autenticação
  - Corrigir timeout nas requisições API
  - Adicionar logs detalhados em `check_admin_authorization?`
  - Implementar retry automático

- [ ] **Melhoria: Sistema de Logs**
  - Adicionar contexto em todos os logs
  - Implementar log rotation
  - Criar dashboard de logs (Grafana?)
  - Alertas de erro via email/Slack

#### Critérios de Aceitação
- ✅ Zero mensagens duplicadas em 100 qualificações
- ✅ Painel administrativo carrega em < 2 segundos
- ✅ API responde 100% das requisições
- ✅ Logs estruturados e query-friendly

---

### FASE 2 - Analytics e Relatórios (v2.2.0)
**Prazo:** 3-4 semanas
**Status:** 🔴 Planejamento

#### Features
- [ ] **Dashboard de Métricas**
  - Total de leads qualificados (hoje, semana, mês)
  - Distribuição por temperatura (gráfico pizza)
  - Taxa de conversão por temperatura
  - Tempo médio de qualificação
  - Procedimentos mais procurados

- [ ] **Relatórios Exportáveis**
  - CSV de leads qualificados
  - PDF com análise semanal
  - Integração com Google Sheets (opcional)
  - Agendamento de relatórios automáticos

- [ ] **Análise de Qualidade**
  - Score médio por dia/semana
  - Temperatura média dos leads
  - Taxa de qualificação bem-sucedida
  - Leads que abandonaram conversa

- [ ] **Insights de IA**
  - Palavras-chave mais comuns
  - Objeções frequentes
  - Perguntas não respondidas pela IA
  - Sugestões de melhoria de prompts

#### Critérios de Aceitação
- ✅ Dashboard atualiza em tempo real
- ✅ Exportação de relatórios em < 5 segundos
- ✅ Precisão dos dados: 100%
- ✅ Interface intuitiva e mobile-friendly

---

### FASE 3 - Otimizações de IA (v2.3.0)
**Prazo:** 2-3 semanas
**Status:** 🔴 Ideação

#### Features
- [ ] **Múltiplos Prompts**
  - Prompt A/B testing
  - Versões de prompt por segmento
  - Análise de performance por prompt
  - Rollback de prompts

- [ ] **Fine-tuning de Scoring**
  - Ajuste de pesos por performance real
  - Machine Learning para otimizar thresholds
  - Feedback loop: vendedor marca se lead era realmente quente
  - Recalibração automática mensal

- [ ] **Respostas Mais Inteligentes**
  - RAG (Retrieval Augmented Generation) com base de conhecimento
  - Embeddings de documentos da clínica
  - Respostas baseadas em FAQs
  - Contexto de conversas anteriores do mesmo lead

- [ ] **Detecção de Sentimento**
  - Análise de sentimento em tempo real
  - Ajuste de tom baseado em humor do lead
  - Escalação automática se lead irritado
  - Emojis inteligentes baseados em contexto

#### Critérios de Aceitação
- ✅ Taxa de conversão aumenta 20%
- ✅ Tempo de qualificação reduz 30%
- ✅ Satisfação do lead: NPS > 8
- ✅ Precisão da qualificação: > 85%

---

### FASE 4 - Automações Avançadas (v3.0.0)
**Prazo:** 2-3 meses
**Status:** 🔴 Conceitual

#### Features
- [ ] **Multi-canal**
  - Integração com Instagram Direct
  - Integração com Facebook Messenger
  - Integração com Telegram
  - Unified inbox para todos os canais

- [ ] **Agendamento Inteligente**
  - Integração com Google Calendar
  - Sugestão de horários disponíveis
  - Confirmação automática de consultas
  - Lembretes automáticos (24h/1h antes)

- [ ] **CRM Integration**
  - Exportação automática para Pipedrive/RD Station
  - Sincronização bidirecional de status
  - Webhook para eventos de vendas
  - Dashboards unificados

- [ ] **Workflows Personalizáveis**
  - Editor visual de fluxos (low-code)
  - Condicionais baseados em temperatura
  - Ações customizadas (enviar email, criar task, etc.)
  - Templates de workflow prontos

#### Critérios de Aceitação
- ✅ Suporte a 3+ canais simultâneos
- ✅ 90% dos agendamentos sem intervenção humana
- ✅ Sincronização CRM em < 1 minuto
- ✅ Workflows customizáveis por não-programadores

---

## ⚠️ PENDÊNCIAS TÉCNICAS

### CRÍTICAS (Alta Prioridade)

#### 1. Investigar Problema de Autenticação no Painel
**Status:** 🔴 Bloqueante
**Impacto:** Alto - Impossibilita configuração do sistema
**Esforço:** 2-4 horas

**Descrição:**
Requisições para `/api/v1/accounts/1/sdr_ia/*` travam intermitentemente.

**Hipóteses:**
1. `before_action :check_admin_authorization?` causa timeout
2. `Current.account` ou `Current.user` está nil/inválido
3. Sessão expira durante requisição
4. Pundit authorization trava em algum cenário edge

**Próximos Passos:**
```ruby
# Adicionar logs detalhados em settings_controller.rb
def show
  Rails.logger.info "[SDR IA] [DEBUG] User: #{Current.user&.id}, Account: #{Current.account&.id}"
  Rails.logger.info "[SDR IA] [DEBUG] Admin?: #{Current.account_user&.administrator?}"

  config = SdrIaConfig.for_account(Current.account)
  Rails.logger.info "[SDR IA] [DEBUG] Config: #{config.inspect}"

  render json: { settings: config.to_config_hash }
  Rails.logger.info "[SDR IA] [DEBUG] Response enviada!"
rescue => e
  Rails.logger.error "[SDR IA] [ERROR] #{e.class}: #{e.message}"
  Rails.logger.error e.backtrace.first(10).join("\n")
  render json: { error: e.message }, status: 500
end
```

**Testes:**
1. Testar com diferentes usuários (admin, agent, viewer)
2. Testar com sessão expirada
3. Testar com múltiplas abas abertas
4. Load test com 10 requisições simultâneas

---

#### 2. Reimplementar Patches 3 e 4 com Validação
**Status:** 🔴 Revertido
**Impacto:** Médio - UX degradada (mensagens duplicadas)
**Esforço:** 4-6 horas

**Abordagem:**
1. **Criar ambiente de staging**
2. **Patch3 isolado:**
   - Aplicar apenas patch3
   - Testar 50 qualificações
   - Verificar painel administrativo
   - Monitorar logs por 24h
3. **Patch4 após validação:**
   - Aplicar patch4 sobre patch3
   - Testar 50 qualificações (20 quentes, 20 mornos, 10 frios)
   - Verificar painel novamente
   - Monitorar logs por 24h
4. **Deploy gradual:**
   - Deploy em 1 container primeiro
   - Monitorar por 2h
   - Se estável, deploy completo

**Métricas de Sucesso:**
- Zero mensagens duplicadas
- Painel responde 100% das requisições
- Zero rollbacks

---

### IMPORTANTES (Média Prioridade)

#### 3. Implementar Testes Automatizados
**Status:** 🟡 Planejado
**Impacto:** Médio - Previne regressões
**Esforço:** 1-2 semanas

**Escopo:**
```ruby
# spec/services/conversation_manager_v2_spec.rb
describe ConversationManagerV2 do
  describe '#process_message' do
    context 'quando lead responde todas as perguntas' do
      it 'qualifica lead corretamente' do
        # arrange
        conversation = create(:conversation)
        messages = build_qualification_messages

        # act
        manager = ConversationManagerV2.new(conversation)
        messages.each { |msg| manager.process_message(msg) }

        # assert
        contact = conversation.contact.reload
        expect(contact.custom_attributes['sdr_ia_status']).to eq('qualificado')
        expect(contact.custom_attributes['sdr_ia_temperatura']).to be_in(['quente', 'morno', 'frio', 'muito_frio'])
      end
    end

    context 'quando lead é quente' do
      it 'não envia mensagem de closing duplicada' do
        # ...
      end
    end
  end
end
```

**Cobertura Objetivo:**
- Unit Tests: > 80%
- Integration Tests: > 60%
- E2E Tests: Principais fluxos (qualificação, handoff, timeout)

---

#### 4. Melhorar Performance de Assets
**Status:** 🟡 Em andamento (Patch5 não testado)
**Impacto:** Médio - Deploy mais lento
**Esforço:** 4-8 horas

**Problemas:**
- Assets não atualizam após rebuild
- Docker volume `chatwoot_public` sobrescreve assets novos
- Necessário cópia manual de assets

**Soluções Propostas:**

**Opção 1: Build multi-stage**
```dockerfile
# Stage 1: Compilar assets
FROM chatwoot/chatwoot:v4.1.0 as builder
COPY frontend /app/frontend
RUN pnpm install && pnpm build

# Stage 2: Runtime
FROM chatwoot/chatwoot:v4.1.0
COPY --from=builder /app/public/vite /app/public/vite
```

**Opção 2: Volume nomeado diferente**
```yaml
volumes:
  - chatwoot_public_v2:/app/public  # Novo volume
```

**Opção 3: Asset sync no entrypoint**
```bash
#!/bin/bash
# Sincronizar assets da imagem para volume
rsync -av /app/public/vite/ /shared/public/vite/
```

---

### DESEJÁVEIS (Baixa Prioridade)

#### 5. Documentação de API
**Status:** 🟢 Bônus
**Impacto:** Baixo - Facilita integrações futuras
**Esforço:** 2-3 dias

**Ferramentas:**
- Swagger/OpenAPI
- Postman Collections
- GraphQL Playground (se aplicável)

---

#### 6. Containerização com Docker Compose
**Status:** 🟢 Nice to have
**Impacto:** Baixo - Facilita desenvolvimento local
**Esforço:** 1-2 dias

**Benefícios:**
- Desenvolvedores rodam ambiente completo localmente
- Menos dependência do servidor de produção
- Testes mais rápidos

---

## 🏗️ MELHORIAS DE INFRAESTRUTURA

### CI/CD Pipeline

#### Objetivo
Automatizar testes, build e deploy com segurança

#### Proposta
```yaml
# .github/workflows/deploy.yml
name: Deploy Chatwoot SDR IA

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run RSpec
        run: bundle exec rspec
      - name: Run ESLint
        run: pnpm lint

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Build Docker Image
        run: docker build -t chatwoot-sdr-ia:${{ github.sha }} .
      - name: Push to Registry
        run: docker push localhost/chatwoot-sdr-ia:${{ github.sha }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Production
        run: |
          docker service update --image chatwoot-sdr-ia:${{ github.sha }} chatwoot_app
          docker service update --image chatwoot-sdr-ia:${{ github.sha }} chatwoot_sidekiq
      - name: Healthcheck
        run: ./scripts/healthcheck.sh
      - name: Rollback se falhar
        if: failure()
        run: ./scripts/rollback.sh
```

---

### Ambiente de Staging

#### Objetivo
Testar mudanças antes de produção

#### Infraestrutura
```yaml
# docker-compose.staging.yml
version: '3.8'

services:
  chatwoot_staging:
    image: localhost/chatwoot-sdr-ia:latest
    environment:
      - RAILS_ENV=staging
      - DATABASE_URL=postgresql://staging_db
    ports:
      - "3001:3000"
```

**URL:** `https://staging.chatteste.nexusatemporal.com`

---

### Monitoramento e Observabilidade

#### Ferramentas Propostas

**1. Application Performance Monitoring (APM)**
- **Opções:** New Relic, Datadog, Scout APM
- **Métricas:** Response time, throughput, error rate
- **Alertas:** Slack/Email quando error rate > 1%

**2. Logging Centralizado**
- **Opção 1:** ELK Stack (Elasticsearch + Logstash + Kibana)
- **Opção 2:** Grafana Loki + Promtail
- **Benefícios:** Query avançada, dashboards, alertas

**3. Uptime Monitoring**
- **Opção:** UptimeRobot, Pingdom
- **Checks:**
  - `https://chatteste.nexusatemporal.com/health`
  - `/api/v1/accounts/1/sdr_ia/settings`
- **Alertas:** SMS/Email se down > 2 minutos

---

## 📅 CRONOGRAMA

### Novembro 2025

| Semana | Foco | Deliverables |
|--------|------|--------------|
| **Sem 4 (25-30 Nov)** | Correções Críticas | ✅ Patch3 + Patch4 validados<br>✅ Painel funcionando<br>✅ Logs melhorados |

### Dezembro 2025

| Semana | Foco | Deliverables |
|--------|------|--------------|
| **Sem 1 (01-07 Dez)** | Testes + Staging | ✅ RSpec tests (>70% coverage)<br>✅ Ambiente staging<br>✅ CI/CD básico |
| **Sem 2 (08-14 Dez)** | Analytics - Backend | ✅ Endpoints de métricas<br>✅ Database queries otimizadas |
| **Sem 3 (15-21 Dez)** | Analytics - Frontend | ✅ Dashboard de métricas<br>✅ Gráficos interativos |
| **Sem 4 (22-31 Dez)** | Buffer + Docs | ✅ Documentação API<br>✅ Guias de uso<br>⚠️ Férias |

### Janeiro 2026

| Semana | Foco | Deliverables |
|--------|------|--------------|
| **Sem 1-2 (01-14 Jan)** | Otimizações IA | ✅ A/B testing de prompts<br>✅ RAG implementado |
| **Sem 3-4 (15-31 Jan)** | Fine-tuning Scoring | ✅ ML para thresholds<br>✅ Feedback loop |

### Fevereiro-Abril 2026

| Mês | Foco | Deliverables |
|-----|------|--------------|
| **Fevereiro** | Multi-canal | ✅ Instagram Direct<br>✅ Telegram |
| **Março** | CRM Integration | ✅ Pipedrive sync<br>✅ Webhooks |
| **Abril** | Workflows | ✅ Editor visual<br>✅ Templates |

---

## ⚠️ RISCOS E MITIGAÇÕES

### RISCO 1: Problema de Autenticação Não Resolvido
**Probabilidade:** Média
**Impacto:** Alto
**Mitigação:**
- Dedicar 2 dias full-time para investigação
- Consultar comunidade Chatwoot no GitHub
- Contratar consultor Ruby on Rails se necessário
- Plano B: Criar controller separado sem Pundit

---

### RISCO 2: Patches Causam Novos Bugs
**Probabilidade:** Média
**Impacto:** Médio
**Mitigação:**
- Testes rigorosos em staging (> 100 qualificações)
- Deploy gradual (1 container → 50% → 100%)
- Monitoramento intensivo nas primeiras 24h
- Script de rollback automático preparado

---

### RISCO 3: Custos de OpenAI Aumentam
**Probabilidade:** Baixa
**Impacto:** Médio
**Mitigação:**
- Implementar cache de respostas comuns
- Usar GPT-4-mini para perguntas simples
- Rate limiting por lead (max 20 mensagens)
- Alertas quando custo mensal > R$ 500

---

### RISCO 4: Performance Degrada com Escala
**Probabilidade:** Média
**Impacto:** Alto
**Mitigação:**
- Load tests mensais simulando 1000 leads/dia
- Database indexing em custom_attributes JSONB
- Redis cache para configurações SDR IA
- Horizontal scaling com Docker Swarm

---

### RISCO 5: Dependência de Serviços Externos
**Probabilidade:** Baixa
**Impacto:** Alto
**Mitigação:**
- **OpenAI down:** Fallback para Claude/Gemini
- **WAHA down:** Implementar retry com backoff exponencial
- **WhatsApp API down:** Fila de mensagens no Redis
- SLA monitoring e alertas

---

## 📚 STACK TECNOLÓGICO COMPLETO

### Backend
| Componente | Tecnologia | Versão | Justificativa |
|------------|-----------|--------|---------------|
| Framework | Ruby on Rails | 7.0.8 | Base do Chatwoot |
| Database | PostgreSQL | 15+ | Robustez e JSONB |
| Cache | Redis | 7.x | Performance |
| Background Jobs | Sidekiq | Latest | Async processing |
| IA Primary | OpenAI GPT-4 | Turbo | Melhor modelo conversacional |
| IA Fallback | Anthropic Claude | 3.5 Sonnet | Backup se OpenAI down |

### Frontend
| Componente | Tecnologia | Versão | Justificativa |
|------------|-----------|--------|---------------|
| Framework | Vue.js | 3.x | Padrão Chatwoot |
| Build Tool | Vite | Latest | Performance de build |
| State | Vuex | 4.x | Gerenciamento de estado |
| HTTP Client | Axios | Latest | Requisições API |
| Charts | Chart.js | 4.x | Visualizações |

### DevOps
| Componente | Tecnologia | Versão | Justificativa |
|------------|-----------|--------|---------------|
| Containers | Docker | Latest | Portabilidade |
| Orchestration | Docker Swarm | Latest | Simplicidade |
| Reverse Proxy | Nginx | Latest | Performance |
| SSL | Let's Encrypt | - | Segurança |
| CI/CD | GitHub Actions | - | Integração nativa |

### Integrações
| Serviço | Propósito | Status |
|---------|-----------|--------|
| WAHA | WhatsApp API | ✅ Produção |
| OpenAI | IA Conversacional | ✅ Produção |
| Chatwoot | CRM Base | ✅ Produção |
| Pipedrive | CRM Vendas | 🔴 Planejado |
| Google Calendar | Agendamento | 🔴 Planejado |

---

## 🎯 MÉTRICAS DE SUCESSO

### KPIs Técnicos
| Métrica | Baseline | Meta Q1 2026 | Meta Q2 2026 |
|---------|----------|--------------|--------------|
| Uptime | 99.5% | 99.9% | 99.95% |
| Response Time (API) | < 200ms | < 100ms | < 50ms |
| Error Rate | < 1% | < 0.1% | < 0.01% |
| Test Coverage | 0% | 70% | 85% |
| Deploy Frequency | Manual | 2x/semana | Diário |

### KPIs de Negócio
| Métrica | Baseline | Meta Q1 2026 | Meta Q2 2026 |
|---------|----------|--------------|--------------|
| Leads Qualificados/Dia | - | 50 | 100 |
| Precisão Qualificação | - | 80% | 90% |
| Taxa Conversão Quentes | - | 40% | 60% |
| Tempo Médio Qualificação | - | 5 min | 3 min |
| Custo por Lead Qualificado | - | R$ 2 | R$ 1 |

---

## 📞 PRÓXIMAS AÇÕES IMEDIATAS

### Esta Semana (25-30 Nov)
- [ ] **Segunda-feira:** Investigar problema de autenticação (4h)
- [ ] **Terça-feira:** Implementar logs detalhados + testar (4h)
- [ ] **Quarta-feira:** Aplicar patch3 em staging (4h)
- [ ] **Quinta-feira:** Validar patch3 + aplicar patch4 (4h)
- [ ] **Sexta-feira:** Deploy gradual em produção (2h) + monitoramento (2h)

### Próxima Semana (01-07 Dez)
- [ ] Setup ambiente staging
- [ ] Configurar CI/CD básico
- [ ] Iniciar testes RSpec
- [ ] Documentar APIs principais

---

## 👥 EQUIPE E RESPONSABILIDADES

### Atual
- **Desenvolvedor Full-stack:** Claude (IA)
- **Product Owner:** Everson Santos
- **QA:** Manual (Everson Santos)
- **DevOps:** Everson Santos

### Ideal (Futuro)
- **Tech Lead:** 1 pessoa (Ruby on Rails + Vue.js)
- **Backend Developer:** 1 pessoa (Ruby on Rails)
- **Frontend Developer:** 1 pessoa (Vue.js)
- **QA Engineer:** 1 pessoa (Automação)
- **DevOps Engineer:** 1 pessoa (Docker + CI/CD)
- **Product Manager:** Everson Santos

---

## 📖 REFERÊNCIAS

### Documentação Técnica
- [Chatwoot Developer Docs](https://www.chatwoot.com/developers)
- [Ruby on Rails Guides](https://guides.rubyonrails.org/)
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Docker Swarm Docs](https://docs.docker.com/engine/swarm/)

### Documentação Interna
- `CHANGELOG.md` - Histórico de versões
- `PATCH_v2.0.0-patch3.md` - Correção mensagens duplicadas
- `PATCH_v2.0.0-patch4.md` - Correção leads quentes
- `SESSAO_2025-11-22.md` - Esta sessão

---

**FIM DO PLANO DE DESENVOLVIMENTO**

*Última atualização: 22 de Novembro de 2025*
*Próxima revisão: 30 de Novembro de 2025*

# Troubleshooting - Histórico Detalhado de Erros e Correções

## Versão 1.2.0 - Implementação do AI Conversacional

### Data: 20/11/2024

---

## ERRO #1: Comportamento Robótico Apesar de Prompts Atualizados

### Descrição do Problema
Após atualizar os prompts conversacionais no painel administrativo, a IA continuava respondendo de forma mecânica e robotizada, ignorando perguntas dos leads e seguindo um script rígido de perguntas sequenciais.

### Sintomas Observados
```
Lead: "Quais vocês tem disponíveis?"
IA: "Para quando você está pensando em fazer?" ❌ (Ignorou a pergunta)
```

A IA estava:
- Ignorando perguntas dos leads
- Fazendo perguntas sequenciais sem contexto
- Não extraindo informações implícitas
- Comportamento de questionário mecânico

### Causa Raiz
Os containers Docker estavam executando a **imagem antiga (542ffce - v1.1.2)** que continha apenas o `ConversationManager` original (versão mecânica), não a nova versão `ConversationManagerV2` (conversacional).

Apesar do código ter sido atualizado no repositório Git (commits de76ea7 e d6fd50e), os containers não foram atualizados com a nova imagem.

### Análise Técnica
```bash
# Verificação dos containers
$ docker service ps chatwoot_chatwoot_app
# Mostrou: Running image 542ffce (versão antiga)

# Código esperado (não estava em execução):
# plugins/sdr_ia/app/services/conversation_manager_v2.rb
```

### Solução Aplicada

**1. Rebuild da imagem Docker:**
```bash
$ docker build -t localhost/chatwoot-sdr-ia:de76ea7 \
    --build-arg CHATWOOT_VERSION=v4.1.0 .
```

**2. Update dos serviços Docker Swarm:**
```bash
# Update app service
$ docker service update \
    --image localhost/chatwoot-sdr-ia:de76ea7 \
    chatwoot_chatwoot_app

# Update sidekiq service
$ docker service update \
    --image localhost/chatwoot-sdr-ia:de76ea7 \
    chatwoot_chatwoot_sidekiq
```

**3. Verificação da atualização:**
```bash
$ docker service ps chatwoot_chatwoot_app --no-trunc
# Confirmado: Running image de76ea7 ✅
```

### Arquivos Envolvidos
- `Dockerfile` - Build da imagem customizada
- `plugins/sdr_ia/app/services/conversation_manager_v2.rb` - Nova lógica conversacional
- `plugins/sdr_ia/app/services/openai_client.rb` - Método `generate_response()`

### Commit da Correção
- **Commit**: `de76ea7`
- **Mensagem**: "fix: Implement truly conversational AI with OpenAI realtime responses"

### Status
✅ **RESOLVIDO** - Containers atualizados com nova imagem

---

## ERRO #2: ConversationManagerV2 Class Not Found

### Descrição do Problema
Após deployment da imagem de76ea7, o sistema apresentou erro de classe não inicializada ao tentar processar mensagens de leads.

### Sintomas Observados
```ruby
# Log de erro
E, [2025-11-20T21:42:05] ERROR -- : [SDR IA Job] Erro inesperado:
uninitialized constant SdrIa::QualifyLeadJob::ConversationManagerV2

# Stack trace
/app/plugins/sdr_ia/app/jobs/qualify_lead_job.rb:23:in `perform'
```

A aplicação estava:
- Falhando ao processar mensagens incoming
- Retornando erro 500 no Sidekiq job
- ConversationManagerV2 não encontrada no namespace SdrIa

### Causa Raiz
O arquivo `config/initializers/sdr_ia.rb` **não estava carregando** a classe `ConversationManagerV2` durante a inicialização do Rails.

Apesar do arquivo existir em:
```
/app/plugins/sdr_ia/app/services/conversation_manager_v2.rb
```

O initializer só carregava:
```ruby
# config/initializers/sdr_ia.rb (ANTES)
require Rails.root.join('plugins/sdr_ia/app/services/openai_client')
require Rails.root.join('plugins/sdr_ia/app/services/lead_qualifier')
require Rails.root.join('plugins/sdr_ia/app/services/conversation_manager')
# ❌ FALTANDO: conversation_manager_v2
require Rails.root.join('plugins/sdr_ia/app/jobs/qualify_lead_job')
```

### Análise Técnica
```ruby
# qualify_lead_job.rb tentava usar a classe
module SdrIa
  class QualifyLeadJob < ApplicationJob
    def perform(contact_id, conversation_id = nil)
      # ...
      manager = ConversationManagerV2.new(...)  # ❌ Classe não carregada
      manager.process_message!
    end
  end
end
```

O Rails autoload só funciona se:
1. O arquivo estiver em `app/` (mas estava em `plugins/sdr_ia/app/`)
2. OU o arquivo for explicitamente requerido no initializer

### Solução Aplicada

**1. Atualização do initializer:**
```ruby
# config/initializers/sdr_ia.rb (DEPOIS)
require Rails.root.join('plugins/sdr_ia/app/services/openai_client')
require Rails.root.join('plugins/sdr_ia/app/services/lead_qualifier')
require Rails.root.join('plugins/sdr_ia/app/services/conversation_manager')
require Rails.root.join('plugins/sdr_ia/app/services/conversation_manager_v2')  # ✅ ADICIONADO
require Rails.root.join('plugins/sdr_ia/app/jobs/qualify_lead_job')
require Rails.root.join('plugins/sdr_ia/app/listeners/sdr_ia_listener')
```

**2. Rebuild da imagem:**
```bash
$ docker build -t localhost/chatwoot-sdr-ia:ddd9465 \
    --build-arg CHATWOOT_VERSION=v4.1.0 .
```

**3. Deployment:**
```bash
$ docker service update \
    --image localhost/chatwoot-sdr-ia:ddd9465 \
    chatwoot_chatwoot_app

$ docker service update \
    --image localhost/chatwoot-sdr-ia:ddd9465 \
    chatwoot_chatwoot_sidekiq
```

**4. Verificação:**
```bash
$ docker exec <sidekiq_container> bundle exec rails runner \
    "puts SdrIa::ConversationManagerV2"

# Output esperado:
# SdrIa::ConversationManagerV2 ✅
```

### Arquivos Envolvidos
- `config/initializers/sdr_ia.rb` - Adicionado require da classe
- `plugins/sdr_ia/app/services/conversation_manager_v2.rb` - Classe que não estava sendo carregada
- `Dockerfile` - Copia do initializer atualizado

### Commit da Correção
- **Commit**: `ddd9465`
- **Mensagem**: "fix: Add ConversationManagerV2 require to initializer"

### Status
✅ **RESOLVIDO** - Classe agora é carregada corretamente no boot

---

## ERRO #3: Database Columns Missing (default_agent_email)

### Descrição do Problema
Após correção do erro #2, novo erro apareceu relacionado a colunas inexistentes no banco de dados.

### Sintomas Observados
```ruby
# Log de erro
E, [2025-11-20T21:51:37] ERROR -- : undefined local variable or method
`default_agent_email' for an instance of SdrIaConfig

# Stack trace
/app/app/models/sdr_ia_config.rb:19:in `to_config_hash'
/app/plugins/sdr_ia/app/services/conversation_manager_v2.rb:13:in `initialize'
```

A aplicação estava:
- Falhando ao instanciar `ConversationManagerV2`
- Erro ao tentar acessar `default_agent_email` no model
- Método `to_config_hash` retornando erro

### Causa Raiz
A **migration 20251120230000** não havia sido executada no banco de dados de produção.

O código esperava as colunas:
- `default_agent_email`
- `clinic_name`
- `ai_name`
- `clinic_address`

Mas estas colunas **não existiam** na tabela `sdr_ia_configs`.

### Análise Técnica
```ruby
# models/sdr_ia_config.rb
class SdrIaConfig < ApplicationRecord
  def to_config_hash
    {
      'enabled' => enabled,
      'openai' => openai_config,
      'prompts' => prompts_config,
      'default_agent_email' => default_agent_email,  # ❌ Coluna não existe
      'clinic_name' => clinic_name,                   # ❌ Coluna não existe
      'ai_name' => ai_name,                           # ❌ Coluna não existe
      'clinic_address' => clinic_address              # ❌ Coluna não existe
    }
  end
end
```

**Verificação do schema:**
```bash
$ docker exec <app_container> bundle exec rails runner \
    "puts SdrIaConfig.column_names"

# Output (ANTES da correção):
# ["id", "account_id", "enabled", "openai_config", "prompts_config", "created_at", "updated_at"]
# ❌ Faltando: default_agent_email, clinic_name, ai_name, clinic_address
```

**Por que a migration não rodou?**

O Chatwoot em produção usa um **entrypoint script** que roda migrations automaticamente no boot. No entanto:

1. A migration foi adicionada após o primeiro deploy
2. O container foi reiniciado mas a migration não foi detectada
3. Necessário rodar manualmente ou fazer restart completo

### Solução Aplicada

**1. Executar migration manualmente:**
```bash
# Identificar container do app
$ docker ps -q -f "name=chatwoot_chatwoot_app"
797e54a5f5a7

# Rodar migration
$ docker exec 797e54a5f5a7 bundle exec rails db:migrate

# Output da migration:
== 20251120230000 AddDefaultAgentToSdrIaConfigs: migrating ====================
-- add_column(:sdr_ia_configs, :default_agent_email, :string,
   {:default=>"pedro.zoia@nexusatemporal.com"})
   -> 0.0194s
-- add_column(:sdr_ia_configs, :clinic_name, :string,
   {:default=>"Nexus Atemporal"})
   -> 0.0016s
-- add_column(:sdr_ia_configs, :ai_name, :string,
   {:default=>"Nexus IA"})
   -> 0.0018s
-- add_column(:sdr_ia_configs, :clinic_address, :text,
   {:default=>"A ser configurado"})
   -> 0.0018s
== 20251120230000 AddDefaultAgentToSdrIaConfigs: migrated (0.0267s) ===========
```

**2. Verificação do schema atualizado:**
```bash
$ docker exec 797e54a5f5a7 bundle exec rails runner \
    "puts SdrIaConfig.column_names"

# Output (DEPOIS):
# ["id", "account_id", "enabled", "openai_config", "prompts_config",
#  "default_agent_email", "clinic_name", "ai_name", "clinic_address",
#  "created_at", "updated_at"]
# ✅ Todas as colunas presentes
```

**3. Force restart do Sidekiq:**
```bash
$ docker service update --force chatwoot_chatwoot_sidekiq

# Verificar serviço
$ docker service ps chatwoot_chatwoot_sidekiq
# NAME                          IMAGE                              CURRENT STATE
# chatwoot_chatwoot_sidekiq.1   localhost/chatwoot-sdr-ia:ddd9465  Running 2 minutes ago
```

**4. Teste de configuração:**
```bash
$ docker exec 797e54a5f5a7 bundle exec rails runner \
    "config = SdrIaConfig.first;
     puts config.default_agent_email"

# Output:
# pedro.zoia@nexusatemporal.com ✅
```

### Arquivos Envolvidos
- `db/migrate/20251120230000_add_default_agent_to_sdr_ia_configs.rb` - Migration não executada
- `models/sdr_ia_config.rb` - Model usando colunas inexistentes
- `plugins/sdr_ia/app/services/conversation_manager_v2.rb` - Serviço que depende das colunas

### Migration Aplicada
```ruby
class AddDefaultAgentToSdrIaConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :sdr_ia_configs, :default_agent_email, :string,
               default: 'pedro.zoia@nexusatemporal.com'
    add_column :sdr_ia_configs, :clinic_name, :string,
               default: 'Nexus Atemporal'
    add_column :sdr_ia_configs, :ai_name, :string,
               default: 'Nexus IA'
    add_column :sdr_ia_configs, :clinic_address, :text,
               default: 'A ser configurado'
  end
end
```

### Verificação Final
```bash
# Testar módulo completo
$ docker exec 797e54a5f5a7 bundle exec rails runner "puts SdrIa.enabled?"

# Output esperado:
I, [2025-11-20T22:07:13] INFO -- : [SDR IA] Carregando módulo SDR IA...
I, [2025-11-20T22:07:13] INFO -- : [SDR IA] Módulo habilitado. Carregando classes...
I, [2025-11-20T22:07:13] INFO -- : [SDR IA] Classes carregadas. Listener será registrado.
true ✅
```

### Status
✅ **RESOLVIDO** - Migration executada com sucesso, colunas criadas

---

## Resumo dos Erros e Impacto

| Erro | Severidade | Tempo de Resolução | Impacto |
|------|-----------|-------------------|---------|
| #1: Imagem Docker Antiga | 🔴 Alta | ~15 minutos | Sistema rodando código desatualizado |
| #2: Classe não carregada | 🔴 Alta | ~20 minutos | Jobs falhando com 500 error |
| #3: Colunas inexistentes | 🔴 Alta | ~10 minutos | Impossível instanciar ConversationManager |

**Total de tempo de troubleshooting**: ~45 minutos

---

## Lições Aprendidas

### 1. Deployment em Docker Swarm
- ✅ Sempre verificar que containers estão usando a imagem atualizada
- ✅ Usar `docker service ps` para confirmar versão da imagem
- ✅ Fazer rebuild E update dos serviços após mudanças de código

### 2. Rails Class Loading
- ✅ Plugins em `plugins/` precisam de `require` explícito no initializer
- ✅ Autoload do Rails só funciona para `app/` do core
- ✅ Sempre adicionar novas classes ao initializer

### 3. Database Migrations
- ✅ Verificar que migrations rodaram antes de usar novas colunas
- ✅ Em Docker, pode ser necessário rodar manualmente após rebuild
- ✅ Sempre fazer backup antes de migrations em produção

### 4. Debugging Workflow
```
1. Verificar logs (docker service logs)
2. Identificar linha exata do erro (stack trace)
3. Verificar versão da imagem rodando (docker service ps)
4. Verificar classes carregadas (rails runner)
5. Verificar schema do banco (column_names)
6. Aplicar correção
7. Rebuild -> Deploy -> Verify
```

---

## Comandos Úteis para Troubleshooting

### Verificar versão da imagem em execução
```bash
docker service ps chatwoot_chatwoot_app --no-trunc --format "{{.Image}}"
```

### Verificar classes carregadas
```bash
docker exec <container> bundle exec rails runner "puts SdrIa.constants"
```

### Verificar schema do banco
```bash
docker exec <container> bundle exec rails runner "puts Model.column_names"
```

### Forçar reload de serviço
```bash
docker service update --force <service_name>
```

### Ler logs em tempo real
```bash
docker service logs -f chatwoot_chatwoot_sidekiq 2>&1 | grep "SDR IA"
```

---

## Testes de Validação Final

Após todas as correções, os seguintes testes foram executados:

### ✅ Teste 1: Módulo SDR IA habilitado
```bash
$ docker exec <container> bundle exec rails runner "puts SdrIa.enabled?"
# Output: true ✅
```

### ✅ Teste 2: Classes carregadas
```bash
$ docker exec <container> bundle exec rails runner \
    "puts SdrIa::ConversationManagerV2"
# Output: SdrIa::ConversationManagerV2 ✅
```

### ✅ Teste 3: Configuração presente
```bash
$ docker exec <container> bundle exec rails runner \
    "config = SdrIaConfig.first;
     puts config.default_agent_email"
# Output: pedro.zoia@nexusatemporal.com ✅
```

### ✅ Teste 4: Usuário Pedro Zoia existe
```bash
$ docker exec <container> bundle exec rails runner \
    "user = User.find_by(email: 'pedro.zoia@nexusatemporal.com');
     puts user.name"
# Output: Pedro Zoia ✅
```

### ✅ Teste 5: Comportamento conversacional
```
Lead: "Oi, queria saber sobre harmonização facial"
IA: "Olá! 😊 Temos várias técnicas de harmonização facial.
     Você já conhece alguma ou gostaria que eu explicasse as opções?"

Lead: "Vocês trabalham com quais técnicas?"
IA: "Trabalhamos com preenchimento labial, toxina botulínica,
     bioestimuladores e fios de PDO. Qual área você tem mais interesse?"

✅ IA respondeu perguntas ANTES de fazer perguntas
✅ Mensagens enviadas por "Pedro Zoia"
✅ Comportamento 100% conversacional
```

---

**Documentação criada em**: 20/11/2024
**Versão do sistema**: 1.2.0
**Status**: Todos os erros resolvidos ✅

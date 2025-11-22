# 🚀 Guia de Deploy - Chatwoot SDR IA v2.0.0

## ✅ O que está no GitHub

**Repositório**: https://github.com/eversonsantos-dev/chatwoot-sdr-ia

### Estrutura Completa:

```
chatwoot-sdr-ia/
├── Dockerfile                    # Build da imagem customizada
├── rebuild.sh                    # Script para rebuild automático
├── deploy.sh                     # Script para deploy no Swarm
├── plugins/sdr_ia/               # Módulo completo SDR IA
├── models/                       # Models (SdrIaConfig)
├── controllers/                  # Controllers da API
├── frontend/                     # Interface Vue.js
│   ├── routes/dashboard/settings/sdr-ia/
│   │   └── Index.vue            # ✅ COM aba Base de Conhecimento
│   ├── settings.routes.js
│   └── sidebar-settings.js
├── db/migrate/                   # Migrations do banco
├── config/                       # Configurações Rails
├── patches/                      # Patches do Chatwoot
├── CHANGELOG.md                  # Histórico completo
├── RELEASE_NOTES_v2.0.0.md      # Notas da v2.0.0
├── MELHORIAS_v1.3.0.md          # Documentação técnica
└── README.md                     # Documentação principal
```

---

## 📋 Deploy em Novo Servidor (Passo a Passo)

### **Pré-requisitos:**
- Ubuntu 20.04+ ou similar
- Docker 20.10+
- Docker Swarm inicializado OU Docker Compose
- Git instalado
- 4GB+ RAM (recomendado 8GB)
- PostgreSQL e Redis (podem ser containers)

---

## 🔧 Opção 1: Deploy com Docker Swarm (Recomendado)

### **1. Clonar o Repositório**

```bash
git clone https://github.com/eversonsantos-dev/chatwoot-sdr-ia.git
cd chatwoot-sdr-ia
git checkout v2.0.0
```

### **2. Configurar Variáveis de Ambiente**

Crie um arquivo `.env` ou configure no stack:

```bash
# Chatwoot Base
POSTGRES_PASSWORD=sua_senha_segura
REDIS_PASSWORD=sua_senha_redis
SECRET_KEY_BASE=$(openssl rand -hex 64)
FRONTEND_URL=https://seu-dominio.com

# OpenAI (para SDR IA)
OPENAI_API_KEY=sk-...

# Email (opcional)
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=seu@email.com
SMTP_PASSWORD=senha_app
```

### **3. Build da Imagem**

```bash
chmod +x rebuild.sh
./rebuild.sh
```

**O script vai:**
- ✅ Verificar se Dockerfile existe
- ✅ Mostrar configurações de build
- ✅ Pedir confirmação
- ✅ Fazer build completo com Vite
- ✅ Compilar todos os assets do frontend
- ✅ Criar tags: `latest`, `v2.0.0`, `<git-commit>`, `<date>`

**Tempo estimado:** 5-10 minutos

### **4. Criar Stack do Chatwoot**

Crie `docker-stack.yml` (ou use docker-compose.yml):

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_DB: chatwoot_production
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - chatwoot

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - chatwoot

  chatwoot_app:
    image: localhost/chatwoot-sdr-ia:v2.0.0
    environment:
      # Database
      POSTGRES_HOST: postgres
      POSTGRES_DATABASE: chatwoot_production
      POSTGRES_USERNAME: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      
      # Redis
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379
      
      # Rails
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
      RAILS_ENV: production
      RAILS_LOG_TO_STDOUT: "true"
      
      # Chatwoot
      FRONTEND_URL: ${FRONTEND_URL}
      INSTALLATION_NAME: "SDR IA"
      
      # OpenAI (SDR IA)
      OPENAI_API_KEY: ${OPENAI_API_KEY}
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - redis
    volumes:
      - chatwoot_storage:/app/storage
      - chatwoot_public:/app/public  # ⚠️ IMPORTANTE para assets
      - chatwoot_mailer:/app/app/views/devise/mailer
      - chatwoot_mailers:/app/app/views/mailers
    networks:
      - chatwoot
    command: bundle exec rails server -b 0.0.0.0

  chatwoot_sidekiq:
    image: localhost/chatwoot-sdr-ia:v2.0.0
    environment:
      # (mesmas env vars do chatwoot_app)
      POSTGRES_HOST: postgres
      POSTGRES_DATABASE: chatwoot_production
      POSTGRES_USERNAME: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
      RAILS_ENV: production
      OPENAI_API_KEY: ${OPENAI_API_KEY}
    depends_on:
      - postgres
      - redis
    volumes:
      - chatwoot_storage:/app/storage
    networks:
      - chatwoot
    command: bundle exec sidekiq -C config/sidekiq.yml

volumes:
  postgres_data:
  redis_data:
  chatwoot_storage:
  chatwoot_public:
  chatwoot_mailer:
  chatwoot_mailers:

networks:
  chatwoot:
```

### **5. Deploy no Swarm**

```bash
# Inicializar Swarm (se ainda não inicializou)
docker swarm init

# Deploy
docker stack deploy -c docker-stack.yml chatwoot

# OU usar o script automatizado:
chmod +x deploy.sh
./deploy.sh
```

### **6. Executar Migrations**

```bash
# Encontrar container do app
CONTAINER_ID=$(docker ps | grep chatwoot_app | awk '{print $1}')

# Executar migrations
docker exec $CONTAINER_ID bundle exec rails db:create db:migrate

# Criar coluna knowledge_base (v2.0.0)
docker exec $CONTAINER_ID bundle exec rails runner \
  "ActiveRecord::Migration.add_column :sdr_ia_configs, :knowledge_base, :text, default: ''"

# Instalar custom attributes
docker exec $CONTAINER_ID bundle exec rails runner plugins/sdr_ia/install.rb
```

### **7. Criar Usuário Admin**

```bash
docker exec -it $CONTAINER_ID bundle exec rails console

# No console Rails:
user = User.create!(
  email: 'admin@seudominio.com',
  name: 'Admin',
  password: 'senha_segura_aqui',
  password_confirmation: 'senha_segura_aqui',
  role: :administrator
)

account = Account.create!(name: 'Minha Empresa')
AccountUser.create!(account: account, user: user, role: :administrator)
```

---

## 🔧 Opção 2: Deploy com Docker Compose

```bash
# 1. Clonar e build
git clone https://github.com/eversonsantos-dev/chatwoot-sdr-ia.git
cd chatwoot-sdr-ia
git checkout v2.0.0
./rebuild.sh

# 2. Usar docker-compose.yml ao invés de stack
docker-compose up -d

# 3. Migrations (mesmo processo acima)
```

---

## ⚙️ Configuração Pós-Deploy

### **1. Acessar Painel**
```
https://seu-dominio.com
Login: admin@seudominio.com
Senha: (a que você criou)
```

### **2. Configurar SDR IA**

**Ir em:** `Configurações → SDR IA`

**Aba Configurações Gerais:**
- ✅ Selecionar Time para Leads Quentes
- ✅ Selecionar Time para Leads Mornos
- ✅ Configurar Agente Padrão (email do agente SDR IA)

**Aba Base de Conhecimento (NOVA v2.0.0!):**
- ✅ Adicionar informações da empresa:
  - Horários de funcionamento
  - Endereço e telefone
  - Valores e formas de pagamento
  - Procedimentos oferecidos
  - FAQ

**Aba Prompts da IA:**
- ✅ Personalizar prompts (opcional)

**Aba Sistema de Scoring:**
- ✅ Ajustar pesos do scoring (opcional)

### **3. Criar Inbox e Testar**

```
1. Configurações → Inboxes → Criar Website
2. Copiar código do widget
3. Testar conversa com SDR IA
4. Verificar qualificação automática
```

---

## 🔄 Atualização Futura (v2.1.0, v2.2.0, etc)

```bash
# 1. Pull nova versão
cd chatwoot-sdr-ia
git fetch --tags
git checkout v2.1.0  # ou versão desejada

# 2. Rebuild
./rebuild.sh

# 3. Deploy
./deploy.sh

# 4. Executar migrations (se houver)
docker exec $CONTAINER_ID bundle exec rails db:migrate
```

---

## 📊 Verificação de Saúde

```bash
# Ver logs
docker service logs -f chatwoot_chatwoot_app | grep "SDR IA"
docker service logs -f chatwoot_chatwoot_sidekiq | grep "SDR IA"

# Verificar módulo carregado
docker exec $CONTAINER_ID bundle exec rails runner "puts SdrIa.enabled?"
# Deve retornar: true

# Verificar custom attributes
docker exec $CONTAINER_ID bundle exec rails runner \
  "puts CustomAttributeDefinition.where(attribute_key: 'estagio_funil').exists?"
# Deve retornar: true
```

---

## 🐛 Troubleshooting

### **Aba Base de Conhecimento não aparece:**

```bash
# 1. Verificar se assets foram compilados
docker exec $CONTAINER_ID ls -lh /app/public/vite/assets/ | grep dashboard

# 2. Atualizar volume public se necessário
docker run --rm -v chatwoot_public:/public \
  localhost/chatwoot-sdr-ia:v2.0.0 \
  sh -c "rm -rf /public/vite && cp -r /app/public/vite /public/"

# 3. Reiniciar app
docker service update --force chatwoot_chatwoot_app
```

### **Labels não são criadas:**

```bash
# Executar install.rb novamente
docker exec $CONTAINER_ID bundle exec rails runner plugins/sdr_ia/install.rb
```

### **Nota privada não é criada:**

```bash
# Verificar logs do Sidekiq
docker service logs chatwoot_chatwoot_sidekiq -f | grep "Nota privada"
```

---

## 📦 O que já vem incluído no GitHub:

✅ **Código completo do módulo SDR IA**
✅ **Dockerfile otimizado** com build multi-stage
✅ **Scripts de automação** (rebuild.sh, deploy.sh)
✅ **Migrations do banco de dados**
✅ **Frontend Vue.js** com todas as abas (incluindo Base de Conhecimento v2.0.0)
✅ **Prompts padrão** da IA
✅ **Sistema de scoring** configurável
✅ **Labels e custom attributes** automáticos
✅ **Documentação completa** (CHANGELOG, Release Notes, Melhorias)

---

## 🎯 Resumo: Deploy em Novo Servidor

**Comandos rápidos:**

```bash
# 1. Clone
git clone https://github.com/eversonsantos-dev/chatwoot-sdr-ia.git
cd chatwoot-sdr-ia && git checkout v2.0.0

# 2. Build
./rebuild.sh

# 3. Deploy (Swarm)
docker stack deploy -c docker-stack.yml chatwoot

# 4. Migrations
CONTAINER=$(docker ps | grep chatwoot_app | awk '{print $1}')
docker exec $CONTAINER bundle exec rails db:create db:migrate
docker exec $CONTAINER bundle exec rails runner \
  "ActiveRecord::Migration.add_column :sdr_ia_configs, :knowledge_base, :text, default: ''"
docker exec $CONTAINER bundle exec rails runner plugins/sdr_ia/install.rb

# 5. Criar admin e usar!
```

**Tempo total:** ~15 minutos ⚡

---

## 📞 Suporte

- **GitHub Issues**: https://github.com/eversonsantos-dev/chatwoot-sdr-ia/issues
- **Documentação**: Ver arquivos .md no repositório
- **Changelog**: CHANGELOG.md
- **Release Notes**: RELEASE_NOTES_v2.0.0.md

---

**Desenvolvido com ❤️ - Pronto para produção!** 🚀

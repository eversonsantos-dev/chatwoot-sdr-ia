# Changelog - Chatwoot SDR IA

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

---

## [3.1.4] - 2025-11-27 - CORRECAO CUSTOM ATTRIBUTES

### Status da Versao
- **VERSAO ESTAVEL**
- **RECOMENDADA PARA PRODUCAO (LATEST)**
- Data: 27 de Novembro de 2025
- Tag Git: `v3.1.4`
- Docker Hub: `eversonsantosdev/chatwoot-sdr-ia:3.1.4` e `:latest`

### Correcoes

#### Custom Attributes do SDR IA
**Problema:**
- Atributos personalizados do SDR IA nao eram criados automaticamente
- Campos como temperatura, score, status nao apareciam nos contatos

**Causa:**
- O script `install.rb` nao era executado no startup do container

**Solucao:**
- Entrypoint atualizado para executar `install.rb` automaticamente
- Custom Attributes sao criados na primeira inicializacao
- Execucao apenas no container principal (rails s), nao no sidekiq

**Atributos Criados Automaticamente:**
```
sdr_ia_status        - Status da qualificacao (em_andamento, qualificado, etc)
sdr_ia_progresso     - Progresso (ex: 3/6)
sdr_ia_temperatura   - Temperatura do lead (quente, morno, frio, muito_frio)
sdr_ia_score         - Score de 0-100
sdr_ia_nome          - Nome extraido pela IA
sdr_ia_interesse     - Procedimento de interesse
sdr_ia_urgencia      - Urgencia do lead
sdr_ia_conhecimento  - Nivel de conhecimento
sdr_ia_motivacao     - Motivacao/objetivo
sdr_ia_localizacao   - Localizacao
sdr_ia_comportamento - Comportamento (cooperativo, evasivo, resistente)
sdr_ia_resumo        - Resumo para o closer
sdr_ia_proximo_passo - Proxima acao recomendada
estagio_funil        - Estagio do funil de vendas
```

---

## [3.1.3] - 2025-11-27 - VERSAO ESTAVEL FINAL

### Status da Versao
- **VERSAO ESTAVEL E TESTADA EM PRODUCAO**
- **RECOMENDADA PARA PRODUCAO (LATEST)**
- **DEPLOY VIA PORTAINER TESTADO E VALIDADO**
- Data: 27 de Novembro de 2025
- Tag Git: `v3.1.3`
- Docker Hub: `eversonsantosdev/chatwoot-sdr-ia:3.1.3` e `:latest`

### Novidades Principais

#### Documentacao Completa de Erros e Solucoes
Esta versao documenta todos os erros encontrados durante a implantacao em producao e suas solucoes definitivas.

### ERROS ENCONTRADOS E CORRECOES

#### ERRO 1: Tela Branca Apos Login
**Sintomas:**
- Login funciona (HTTP 200)
- Apos autenticar, tela fica completamente branca
- Console do navegador sem erros visiveis
- Assets carregando normalmente

**Causa Raiz:**
- Usuario SuperAdmin criado SEM Account associada
- Chatwoot requer pelo menos uma Account para o dashboard funcionar
- Sem Account, Vue.js nao consegue renderizar o dashboard

**Solucao:**
```ruby
# No Rails Console (bundle exec rails console):
account = Account.create!(name: "Nome da Empresa", locale: "pt_BR")
user = User.find_by(email: "admin@seudominio.com")
AccountUser.create!(account: account, user: user, role: :administrator)
```

**Prevencao:** Sempre criar Account junto com SuperAdmin

---

#### ERRO 2: Traefik - "client version 1.24 is too old"
**Sintomas:**
```
ERR error="client version 1.24 is too old. Minimum supported API version is 1.44"
```

**Causa:**
- Traefik v3.2+ requer Docker API 1.44
- Servidor com Docker versao anterior

**Solucao:**
Adicionar variavel de ambiente no Traefik:
```yaml
environment:
  - DOCKER_API_VERSION=1.44
```

---

#### ERRO 3: Traefik Label Deprecada
**Sintomas:**
```
WRN Labels traefik.docker.* for Swarm provider are deprecated
```

**Causa:**
- Label `traefik.docker.network` deprecada no Traefik v3

**Solucao:**
```yaml
# ERRADO (deprecado):
- traefik.docker.network=network_public

# CORRETO (Traefik v3 + Swarm):
- traefik.swarm.network=network_public
```

---

#### ERRO 4: Espaco no Host do Traefik
**Sintomas:**
```
ERR error="invalid value for HostSNI matcher, \"dominio.com \" is not a valid hostname"
```

**Causa:**
- Espaco extra no final do dominio na label do Traefik

**Solucao:**
Verificar se nao ha espacos em:
```yaml
- traefik.http.routers.chatwoot.rule=Host(`dominio.com`)  # Sem espaco!
```

---

#### ERRO 5: Sidekiq com Imagem Diferente
**Sintomas:**
- Sistema instavel
- Jobs nao processados corretamente

**Causa:**
- chatwoot_app e chatwoot_sidekiq com imagens diferentes
- Incompatibilidade de versoes

**Solucao:**
Garantir que ambos usem a MESMA imagem:
```yaml
chatwoot_app:
  image: eversonsantosdev/chatwoot-sdr-ia:3.1.3

chatwoot_sidekiq:
  image: eversonsantosdev/chatwoot-sdr-ia:3.1.3  # MESMA imagem!
```

---

#### ERRO 6: Senha sem Caractere Especial
**Sintomas:**
```
Validation failed: Password must contain at least 1 special character
```

**Causa:**
- Chatwoot v4 requer caractere especial na senha

**Solucao:**
Usar senhas com caracteres especiais:
```ruby
# ERRADO:
password = 'Admin2024'

# CORRETO:
password = 'Admin@2024'
```

---

#### ERRO 7: pgvector Extension Not Available
**Sintomas:**
```
PG::UndefinedObject: ERROR: extension "vector" is not available
```

**Causa:**
- Imagem postgres:16-alpine nao tem pgvector
- Chatwoot v4 requer pgvector

**Solucao:**
Usar imagem com pgvector:
```yaml
chatwoot_postgres:
  image: pgvector/pgvector:pg16  # NAO usar postgres:16-alpine
```

---

#### ERRO 8: pnpm Version Mismatch
**Sintomas:**
```
ERR_PNPM_UNSUPPORTED_ENGINE project requires pnpm v10.2.0
```

**Causa:**
- Dockerfile usando pnpm 9.x mas projeto requer 10.2.0

**Solucao no Dockerfile:**
```dockerfile
RUN npm install -g pnpm@10.2.0  # Versao correta
```

---

#### ERRO 9: Assets Nao Compilados
**Sintomas:**
- Menu SDR IA nao aparece
- Frontend original do Chatwoot funciona

**Causa:**
- Assets Vue.js do SDR IA nao foram recompilados

**Solucao:**
Usar multi-stage build no Dockerfile:
```dockerfile
# Stage 1: Compilar assets
FROM chatwoot/chatwoot:v4.1.0 AS builder
RUN pnpm install && bundle exec rake assets:precompile

# Stage 2: Copiar assets compilados
COPY --from=builder /app/public/vite /app/public/vite
```

---

#### ERRO 10: constraint node.role == manager1
**Sintomas:**
- Traefik ou servico nao inicia
- Nenhum no disponivel

**Causa:**
- Erro de digitacao: `manager1` em vez de `manager`

**Solucao:**
```yaml
placement:
  constraints:
    - node.role == manager  # NAO manager1!
```

---

### Stack de Deploy Corrigida (v3.1.3)

```yaml
version: '3.8'

services:
  chatwoot_app:
    image: eversonsantosdev/chatwoot-sdr-ia:3.1.3
    command: bundle exec rails s -p 3000 -b 0.0.0.0
    environment:
      - RAILS_ENV=production
      - NODE_ENV=production
      - INSTALLATION_ENV=docker
      - RAILS_LOG_TO_STDOUT=true
      - POSTGRES_HOST=chatwoot_postgres
      - POSTGRES_PORT=5432
      - POSTGRES_DATABASE=chatwoot_production
      - POSTGRES_USERNAME=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-SuaSenhaSegura}
      - REDIS_URL=redis://chatwoot_redis:6379
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - FRONTEND_URL=${FRONTEND_URL}
      - DEFAULT_LOCALE=pt_BR
    volumes:
      - chatwoot_storage:/app/storage
    networks:
      - chatwoot_internal
      - network_public
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 10s
        max_attempts: 5
      labels:
        - traefik.enable=true
        - traefik.http.routers.chatwoot.rule=Host(`${CHATWOOT_DOMAIN}`)
        - traefik.http.routers.chatwoot.entrypoints=websecure
        - traefik.http.routers.chatwoot.tls.certresolver=letsencryptresolver
        - traefik.http.routers.chatwoot.service=chatwoot
        - traefik.http.services.chatwoot.loadbalancer.server.port=3000
        - traefik.swarm.network=network_public

  chatwoot_sidekiq:
    image: eversonsantosdev/chatwoot-sdr-ia:3.1.3
    command: bundle exec sidekiq -C config/sidekiq.yml
    environment:
      - RAILS_ENV=production
      - NODE_ENV=production
      - INSTALLATION_ENV=docker
      - RAILS_LOG_TO_STDOUT=true
      - POSTGRES_HOST=chatwoot_postgres
      - POSTGRES_PORT=5432
      - POSTGRES_DATABASE=chatwoot_production
      - POSTGRES_USERNAME=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-SuaSenhaSegura}
      - REDIS_URL=redis://chatwoot_redis:6379
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - FRONTEND_URL=${FRONTEND_URL}
      - DEFAULT_LOCALE=pt_BR
    volumes:
      - chatwoot_storage:/app/storage
    networks:
      - chatwoot_internal
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 10s
        max_attempts: 5

  chatwoot_postgres:
    image: pgvector/pgvector:pg16
    environment:
      - POSTGRES_DB=chatwoot_production
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-SuaSenhaSegura}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - chatwoot_internal
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager

  chatwoot_redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - chatwoot_internal
    deploy:
      mode: replicated
      replicas: 1

networks:
  chatwoot_internal:
    driver: overlay
  network_public:
    external: true

volumes:
  postgres_data:
  redis_data:
  chatwoot_storage:
```

### Guia de Instalacao Completo

#### 1. Pre-requisitos
- Docker Swarm inicializado
- Traefik configurado com network_public
- Dominio apontando para o servidor

#### 2. Configurar Variaveis
```bash
# Gerar SECRET_KEY_BASE
openssl rand -hex 64

# Variaveis necessarias:
SECRET_KEY_BASE=<gerado acima>
FRONTEND_URL=https://seudominio.com
CHATWOOT_DOMAIN=seudominio.com
POSTGRES_PASSWORD=SuaSenhaSegura@2024
```

#### 3. Deploy via Portainer
1. Stacks > Add Stack
2. Cole a stack YAML acima
3. Configure as Environment Variables
4. Deploy

#### 4. Criar Super Admin
```bash
# Acessar console do container
docker exec -it <container_chatwoot_app> bundle exec rails console

# No Rails console:
account = Account.create!(name: "Minha Empresa", locale: "pt_BR")
u = User.new
u.name = "Admin"
u.email = "admin@meudominio.com"
u.password = "MinhaSenh@Segura"
u.password_confirmation = "MinhaSenh@Segura"
u.type = "SuperAdmin"
u.skip_confirmation!
u.save!
AccountUser.create!(account: account, user: user, role: :administrator)
exit
```

#### 5. Acessar Sistema
- URL: https://seudominio.com
- Email: admin@meudominio.com
- Senha: MinhaSenh@Segura

---

## [3.1.2] - 2025-11-27 - VERSAO COM PROBLEMAS

### Status
- **DEPRECADA** - Substituida pela v3.1.3
- Problemas: Labels do Traefik incorretas

---

## [3.1.1] - 2025-11-27

### Status
- **FALHOU** - Versao pnpm incorreta

---

## [3.1.0] - 2025-11-27

### Status
- **FALHOU** - corepack nao disponivel

---

## [3.0.x] - Versoes Anteriores

Consulte o historico do repositorio para versoes anteriores.

---

## Versoes Anteriores Estaveis

| Versao | Status | Notas |
|--------|--------|-------|
| 2.1.1 | Estavel | Correcao de transcricao de audio |
| 2.1.0 | Estavel | Buffer de mensagens, Round Robin |
| 2.0.0 | Estavel | Base de conhecimento, Notas privadas |
| 1.2.0 | Estavel | IA conversacional em tempo real |

---

**Repositorio:** https://github.com/eversonsantos-dev/chatwoot-sdr-ia
**Docker Hub:** https://hub.docker.com/r/eversonsantosdev/chatwoot-sdr-ia
**Mantenedor:** Everson Santos (@eversonsantos-dev)
**Licenca:** MIT

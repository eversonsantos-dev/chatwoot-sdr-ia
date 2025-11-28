# Guia de Deploy - Chatwoot SDR IA v3.1.4

## Pre-requisitos

Antes de iniciar, certifique-se de ter:

1. **Servidor com Docker Swarm inicializado**
   ```bash
   docker swarm init
   ```

2. **Traefik configurado** com:
   - Rede externa (ex: `excellencenexus` ou `network_public`)
   - Certificado SSL via Let's Encrypt
   - Entrypoints `web` (80) e `websecure` (443)

3. **Dominio apontando para o servidor**
   - DNS tipo A apontando para o IP do servidor

---

## Passo 1: Identificar a Rede do Traefik

**IMPORTANTE:** Voce precisa saber qual rede o Traefik usa.

Verifique na configuracao do seu Traefik:
```bash
docker service inspect traefik_traefik --format '{{json .Spec.TaskTemplate.ContainerSpec.Command}}' | grep network
```

Ou veja no arquivo de stack do Traefik a linha:
```yaml
"--providers.docker.network=NOME_DA_REDE"
```

Exemplos comuns:
- `excellencenexus`
- `network_public`
- `traefik_public`

**Anote o nome da rede, voce vai precisar!**

---

## Passo 2: Gerar SECRET_KEY_BASE

Execute no servidor:
```bash
openssl rand -hex 64
```

Copie o resultado (128 caracteres). Exemplo:
```
a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef12345678901234567890abcdef1234567890abcdef12345678
```

---

## Passo 3: Preparar Variaveis de Ambiente

Anote os seguintes valores:

| Variavel | Exemplo | Descricao |
|----------|---------|-----------|
| SECRET_KEY_BASE | (gerado no passo 2) | Chave secreta do Rails |
| FRONTEND_URL | https://chat.seudominio.com | URL completa com https |
| CHATWOOT_DOMAIN | chat.seudominio.com | Apenas dominio, sem https |
| POSTGRES_PASSWORD | MinhaSenh@Segura2024 | Senha do banco (com caractere especial) |

---

## Passo 4: Deploy via Portainer

### 4.1 Acessar Portainer
- Va em: **Stacks** > **Add Stack**
- Nome da stack: `chatwoot`

### 4.2 Colar a Stack YAML

**ATENCAO:** Substitua `NOME_DA_SUA_REDE` pela rede do seu Traefik (identificada no Passo 1)

```yaml
version: '3.8'

services:
  # ========================================
  # CHATWOOT APP (Rails Server)
  # ========================================
  chatwoot_app:
    image: eversonsantosdev/chatwoot-sdr-ia:3.1.4
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
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - REDIS_URL=redis://chatwoot_redis:6379
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - FRONTEND_URL=${FRONTEND_URL}
      - DEFAULT_LOCALE=pt_BR
    volumes:
      - chatwoot_storage:/app/storage
    networks:
      - chatwoot_internal
      - NOME_DA_SUA_REDE    # <-- SUBSTITUA AQUI
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
        - traefik.swarm.network=NOME_DA_SUA_REDE    # <-- SUBSTITUA AQUI

  # ========================================
  # CHATWOOT SIDEKIQ (Background Jobs)
  # ========================================
  chatwoot_sidekiq:
    image: eversonsantosdev/chatwoot-sdr-ia:3.1.4
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
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
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

  # ========================================
  # POSTGRESQL (com pgvector)
  # ========================================
  chatwoot_postgres:
    image: pgvector/pgvector:pg16
    environment:
      - POSTGRES_DB=chatwoot_production
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - chatwoot_internal
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
      placement:
        constraints:
          - node.role == manager
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  # ========================================
  # REDIS
  # ========================================
  chatwoot_redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    networks:
      - chatwoot_internal
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

# ========================================
# NETWORKS
# ========================================
networks:
  chatwoot_internal:
    driver: overlay
    attachable: true
  NOME_DA_SUA_REDE:    # <-- SUBSTITUA AQUI
    external: true

# ========================================
# VOLUMES
# ========================================
volumes:
  postgres_data:
  redis_data:
  chatwoot_storage:
```

### 4.3 Configurar Environment Variables no Portainer

Na secao "Environment variables", adicione:

| Name | Value |
|------|-------|
| SECRET_KEY_BASE | (cole o valor gerado no passo 2) |
| FRONTEND_URL | https://chat.seudominio.com |
| CHATWOOT_DOMAIN | chat.seudominio.com |
| POSTGRES_PASSWORD | MinhaSenh@Segura2024 |

### 4.4 Deploy

Clique em **Deploy the stack**

---

## Passo 5: Aguardar Inicializacao

Aguarde 2-3 minutos para os containers iniciarem.

Verifique os logs em **Services** > **chatwoot_chatwoot_app** > **Logs**

Voce deve ver:
```
==========================================
 Chatwoot SDR IA - Iniciando...
==========================================
[OK] PostgreSQL conectado!
[OK] Migrations atualizadas!
[INFO] Instalando Custom Attributes do SDR IA...
  Nenhuma conta encontrada!        <-- NORMAL na primeira vez
[OK] Custom Attributes verificados!
==========================================
 Chatwoot SDR IA - Pronto!
==========================================
Puma starting in single mode...
* Listening on http://0.0.0.0:3000
```

**NOTA:** A mensagem "Nenhuma conta encontrada!" e normal na primeira instalacao.

---

## Passo 6: Criar SuperAdmin e Account

### 6.1 Acessar o Container

No Portainer:
1. Va em **Containers**
2. Encontre `chatwoot_chatwoot_app.1.xxxxx`
3. Clique em **Console**
4. Selecione `/bin/sh` e clique **Connect**

Ou via SSH no servidor:
```bash
docker exec -it $(docker ps -q -f name=chatwoot_chatwoot_app) /bin/sh
```

### 6.2 Abrir Rails Console

Dentro do container (voce vera `/app #`), execute:
```bash
bundle exec rails console
```

### 6.3 Criar Account e SuperAdmin

**IMPORTANTE:** Copie e cole linha por linha, nao tudo de uma vez!

```ruby
# 1. Criar Account (empresa)
account = Account.create!(name: "Nome da Sua Empresa", locale: "pt_BR")
```

```ruby
# 2. Criar usuario SuperAdmin
u = User.new
u.name = "Administrador"
u.email = "admin@seudominio.com"
u.password = "SuaSenh@Segura2024"
u.password_confirmation = "SuaSenh@Segura2024"
u.type = "SuperAdmin"
u.skip_confirmation!
u.save!
```

```ruby
# 3. Associar usuario a conta
AccountUser.create!(account: account, user: u, role: :administrator)
```

```ruby
# 4. Sair do console
exit
```

**ATENCAO sobre a senha:**
- Minimo 6 caracteres
- Precisa ter pelo menos 1 caractere especial (@, #, $, %, etc)
- Exemplos validos: `Admin@2024`, `Senh#Forte123`, `MinhaSenha$2024`
- Exemplos invalidos: `admin2024`, `senhafraca` (sem caractere especial)

---

## Passo 7: Instalar Custom Attributes do SDR IA

Ainda dentro do container (`/app #`), execute:
```bash
bundle exec rails runner /app/plugins/sdr_ia/install.rb
```

Voce deve ver:
```
Instalando SDR IA Module para Chatwoot...
  SDR IA - Status
  SDR IA - Progresso
  SDR IA - Temperatura
  ... (mais atributos)
Instalacao concluida!
```

---

## Passo 8: Acessar o Sistema

1. Abra no navegador: `https://chat.seudominio.com`
2. Faca login com:
   - Email: `admin@seudominio.com`
   - Senha: `SuaSenh@Segura2024`

---

## Solucao de Problemas

### Problema: Pagina nao carrega / Timeout

**Causa:** Rede do Traefik incorreta

**Solucao:**
1. Verifique a rede do Traefik (Passo 1)
2. Atualize a stack com o nome correto da rede
3. Redeploy

### Problema: Tela branca apos login

**Causa:** Usuario sem Account associada

**Solucao:**
```bash
bundle exec rails console
```
```ruby
account = Account.first || Account.create!(name: "Empresa", locale: "pt_BR")
user = User.find_by(email: "seu@email.com")
AccountUser.create!(account: account, user: user, role: :administrator)
exit
```

### Problema: "Password must contain at least 1 special character"

**Causa:** Senha sem caractere especial

**Solucao:** Use senha com @, #, $, %, etc.
```ruby
u.password = "Senh@Segura2024"  # Correto
u.password = "SenhaSemEspecial"  # Errado
```

### Problema: Custom Attributes nao aparecem

**Causa:** Script install.rb nao foi executado

**Solucao:**
```bash
bundle exec rails runner /app/plugins/sdr_ia/install.rb
```

### Problema: "Nenhuma conta encontrada" ao instalar Custom Attributes

**Causa:** Account nao existe ainda

**Solucao:** Crie a Account primeiro (Passo 6), depois execute o install.rb (Passo 7)

---

## Checklist Final

- [ ] Traefik configurado e rodando
- [ ] Rede do Traefik identificada
- [ ] Stack deployada com rede correta
- [ ] Containers rodando (app, sidekiq, postgres, redis)
- [ ] Account criada
- [ ] SuperAdmin criado e associado a Account
- [ ] Custom Attributes instalados
- [ ] Login funcionando
- [ ] Menu SDR IA visivel em Settings

---

## Links Uteis

- **Docker Hub:** https://hub.docker.com/r/eversonsantosdev/chatwoot-sdr-ia
- **GitHub:** https://github.com/eversonsantos-dev/chatwoot-sdr-ia
- **Versao Atual:** v3.1.4

---

## Backup da Imagem

Se precisar restaurar de backup:

```bash
# Configurar AWS CLI para iDrive E2
aws configure
# Access Key: 9UZd6zdKU8JK3SkQRsbe
# Secret Key: eKTLlj5t0p6AfGQOmjavu53x1umWR5kIOoPEzlQq
# Region: us-east-1

# Baixar imagem
aws s3 cp s3://chatwootsdria/docker-images/chatwoot-sdr-ia-v3.1.4.tar.gz . \
  --endpoint-url=https://o0m5.va.idrivee2-26.com

# Carregar no Docker
gunzip -c chatwoot-sdr-ia-v3.1.4.tar.gz | docker load
```

---

## Gerenciamento de Usuarios

### Acessar Rails Console

```bash
# Entrar no container
docker exec -it $(docker ps -q -f name=chatwoot_app | head -1) /bin/sh

# Abrir Rails Console
bundle exec rails console
```

### Criar Usuario SuperAdmin (Passo a Passo)

Execute linha por linha no Rails Console:

```ruby
u = User.new
```

```ruby
u.name = "Nome do Admin"
```

```ruby
u.email = "admin@empresa.com"
```

```ruby
u.password = "Senh@Segura2024"
```

```ruby
u.password_confirmation = "Senh@Segura2024"
```

```ruby
u.type = "SuperAdmin"
```

```ruby
u.skip_confirmation!
```

```ruby
u.save!
```

### Associar Usuario a Account Existente

```ruby
account = Account.first
```

```ruby
AccountUser.create!(account: account, user: u, role: :administrator)
```

### Verificar Usuario Criado

```ruby
puts "Usuario: #{u.email}"
puts "Account: #{account.name}"
puts "Associado: #{u.account_users.count > 0}"
```

### Sair do Console

```ruby
exit
```

---

### Versao Rapida (Copiar Tudo)

```ruby
# Criar usuario SuperAdmin
u = User.new
u.name = "Admin"
u.email = "admin@empresa.com"
u.password = "Senh@2024"
u.password_confirmation = "Senh@2024"
u.type = "SuperAdmin"
u.skip_confirmation!
u.save!

# Associar a conta existente
account = Account.first
AccountUser.create!(account: account, user: u, role: :administrator)

exit
```

---

### Criar Account + Usuario (Instalacao Nova)

```ruby
# Criar Account
account = Account.create!(name: "Nome da Empresa", locale: "pt_BR")

# Criar SuperAdmin
u = User.new
u.name = "Admin"
u.email = "admin@empresa.com"
u.password = "Senh@2024"
u.password_confirmation = "Senh@2024"
u.type = "SuperAdmin"
u.skip_confirmation!
u.save!

# Associar
AccountUser.create!(account: account, user: u, role: :administrator)

exit
```

---

### Redefinir Senha de Usuario

```ruby
u = User.find_by(email: "admin@empresa.com")
u.password = "NovaSenha@2024"
u.password_confirmation = "NovaSenha@2024"
u.save!
exit
```

---

### Listar Todos os Usuarios

```ruby
User.all.each { |u| puts "#{u.email} - #{u.type}" }
```

### Listar Todas as Accounts

```ruby
Account.all.each { |a| puts "#{a.id} - #{a.name}" }
```

### Verificar Associacoes de Usuario

```ruby
u = User.find_by(email: "admin@empresa.com")
puts "Accounts: #{u.account_users.count}"
u.accounts.each { |a| puts "  - #{a.name}" }
```

---

### Regras de Senha

- Minimo 6 caracteres
- **OBRIGATORIO:** Pelo menos 1 caractere especial (@, #, $, %, &, !)
- Exemplos validos: `Admin@2024`, `Senh#Forte123`, `MinhaSenha$2024`
- Exemplos invalidos: `admin2024`, `senhafraca`

---

**Documento atualizado em:** 28 de Novembro de 2025
**Versao do documento:** 1.1

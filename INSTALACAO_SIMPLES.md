# Instalação Simplificada - Chatwoot SDR IA v3.0

## Seu cenário: Docker Swarm / Portainer

O Chatwoot está rodando **dentro de containers Docker**, gerenciados pelo **Docker Swarm** (via Portainer ou CLI).

Isso significa que:
- O caminho `/app` existe **dentro do container**, não no host
- Para instalar, precisamos **injetar arquivos no container rodando**
- Ou **rebuildar a imagem Docker** com o plugin incluído

---

## Opção 1: Instalação Rápida (Recomendada)

### 1. Baixar e executar o instalador inteligente

```bash
# Conectar no servidor
ssh root@seu-servidor

# Baixar o pacote (se ainda não tem)
cd /root
git clone https://github.com/eversonsantos-dev/chatwoot-sdr-ia.git

# Ou se já tem, atualizar
cd /root/chatwoot-sdr-ia
git pull

# Executar instalador inteligente
./install-smart.sh
```

### 2. O que acontece automaticamente:

```
┌─────────────────────────────────────────────────────────────┐
│  DETECÇÃO AUTOMÁTICA                                        │
├─────────────────────────────────────────────────────────────┤
│  ✓ Detecta Docker Swarm                                     │
│  ✓ Encontra stack/containers do Chatwoot                    │
│  ✓ Identifica container "app" e "sidekiq"                   │
│  ✓ Cria backup                                              │
│  ✓ Injeta arquivos via docker cp                            │
│  ✓ Executa migrations                                       │
│  ✓ Reinicia serviços (docker service update --force)        │
└─────────────────────────────────────────────────────────────┘
```

---

## Opção 2: Instalação Manual (Para entender o processo)

### Passo 1: Encontrar o container do Chatwoot

```bash
# Listar containers rodando
docker ps | grep chatwoot

# Resultado típico:
# chatwoot_chatwoot_app.1.xxx    localhost/chatwoot:latest   Up 3 hours
# chatwoot_chatwoot_sidekiq.1.xxx   localhost/chatwoot:latest   Up 3 hours
```

### Passo 2: Copiar arquivos para dentro do container

```bash
# Definir nome do container
CONTAINER="chatwoot_chatwoot_app.1.l49vi1pc1mzwnuwo6qhb7mpql"

# Criar diretório do plugin
docker exec $CONTAINER mkdir -p /app/plugins

# Copiar plugin
docker cp /root/chatwoot-sdr-ia/plugins/sdr_ia $CONTAINER:/app/plugins/

# Copiar migrations
docker cp /root/chatwoot-sdr-ia/db/migrate/. $CONTAINER:/app/db/migrate/

# Copiar initializer
docker cp /root/chatwoot-sdr-ia/config_initializers_sdr_ia.rb $CONTAINER:/app/config/initializers/sdr_ia.rb

# Copiar controller
docker exec $CONTAINER mkdir -p /app/app/controllers/api/v1/accounts/sdr_ia
docker cp /root/chatwoot-sdr-ia/controllers/api/v1/accounts/sdr_ia/settings_controller.rb \
    $CONTAINER:/app/app/controllers/api/v1/accounts/sdr_ia/
```

### Passo 3: Executar migrations

```bash
docker exec $CONTAINER bundle exec rails db:migrate RAILS_ENV=production
```

### Passo 4: Reiniciar serviços

```bash
# Docker Swarm
docker service update --force chatwoot_chatwoot_app
docker service update --force chatwoot_chatwoot_sidekiq

# OU Docker Compose
docker-compose restart

# OU Container individual
docker restart $CONTAINER
```

---

## Configurar OPENAI_API_KEY

### No Docker Swarm (via Portainer):

1. Acesse Portainer → Stacks → chatwoot
2. Edite o stack YAML
3. Adicione nas variáveis de ambiente:

```yaml
services:
  chatwoot_app:
    environment:
      - OPENAI_API_KEY=sk-sua-chave-aqui

  chatwoot_sidekiq:
    environment:
      - OPENAI_API_KEY=sk-sua-chave-aqui
```

4. Faça Update/Deploy do stack

### Via CLI:

```bash
# Editar o arquivo do stack
nano /root/chatwoot-stack.yaml

# Adicionar OPENAI_API_KEY no environment

# Redeployar
docker stack deploy -c chatwoot-stack.yaml chatwoot
```

---

## Verificar se instalou corretamente

```bash
# Ver se arquivos estão no container
docker exec chatwoot_chatwoot_app.1.xxx ls -la /app/plugins/sdr_ia/

# Ver logs do SDR IA
docker logs -f chatwoot_chatwoot_sidekiq.1.xxx | grep "\[SDR IA\]"

# Ver se migrations foram executadas
docker exec chatwoot_chatwoot_app.1.xxx bundle exec rails runner "puts 'SDR IA OK'"
```

---

## Problemas Comuns

### "Container não encontrado"

```bash
# Listar todos os containers
docker ps --format "{{.Names}}"

# Usar o nome correto
./install-smart.sh --container=NOME_CORRETO
```

### "Arquivos não persistem após restart"

Isso acontece porque Docker Swarm recria o container do zero.

**Solução:** Fazer rebuild da imagem Docker com o plugin incluído.

```bash
# 1. Criar Dockerfile customizado
cd /root/chatwoot-sdr-ia
cat > Dockerfile.sdr-ia <<'EOF'
FROM chatwoot/chatwoot:latest

# Adicionar plugin SDR IA
COPY plugins/sdr_ia /app/plugins/sdr_ia
COPY db/migrate/* /app/db/migrate/
COPY config_initializers_sdr_ia.rb /app/config/initializers/sdr_ia.rb
COPY controllers/api/v1/accounts/sdr_ia /app/app/controllers/api/v1/accounts/sdr_ia

EOF

# 2. Build da imagem
docker build -f Dockerfile.sdr-ia -t localhost/chatwoot-sdr-ia:v2.1.1 .

# 3. Atualizar stack para usar nova imagem
# Edite seu stack YAML e mude:
# image: chatwoot/chatwoot:latest
# Para:
# image: localhost/chatwoot-sdr-ia:v2.1.1

# 4. Redeploy
docker stack deploy -c chatwoot-stack.yaml chatwoot
```

---

## Modo Automático (sem interação)

```bash
./install-smart.sh --auto --api-key=sk-sua-chave
```

---

## Resumo dos Comandos

| Ação | Comando |
|------|---------|
| Instalar | `./install-smart.sh` |
| Instalar automático | `./install-smart.sh --auto` |
| Especificar container | `./install-smart.sh --container=nome` |
| Ver logs | `docker logs -f CONTAINER \| grep SDR` |
| Reiniciar Swarm | `docker service update --force SERVICE` |
| Reiniciar Compose | `docker-compose restart` |

---

**Versão:** 3.0
**Última atualização:** Novembro 2025

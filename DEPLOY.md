# 🚀 Guia de Deploy - Chatwoot SDR IA

Este guia explica como fazer o deploy da imagem customizada do Chatwoot com o módulo SDR IA.

## 📋 Índice

- [Pré-requisitos](#pré-requisitos)
- [Build da Imagem](#build-da-imagem)
- [Deploy no Docker Swarm](#deploy-no-docker-swarm)
- [Verificação](#verificação)
- [Configuração Inicial](#configuração-inicial)
- [Atualização](#atualização)
- [Troubleshooting](#troubleshooting)

---

## 🔧 Pré-requisitos

- ✅ Docker 20.10+
- ✅ Docker Swarm inicializado
- ✅ Git instalado
- ✅ Chatwoot v4.1.0 rodando (ou pronto para deploy)
- ✅ Acesso ao servidor onde o Chatwoot está rodando

---

## 🏗️ Build da Imagem

### Passo 1: Clone o repositório

```bash
cd /root
git clone https://github.com/eversonsantos-dev/chatwoot-sdr-ia.git
cd chatwoot-sdr-ia
```

### Passo 2: Execute o script de build

```bash
chmod +x rebuild.sh
./rebuild.sh
```

O script vai:
- ✅ Verificar todos os arquivos necessários
- ✅ Fazer build da imagem Docker
- ✅ Criar múltiplas tags (latest, commit, data)
- ✅ Mostrar o tamanho da imagem

**Tempo estimado:** 5-10 minutos

**Output esperado:**
```
╔════════════════════════════════════════════════════╗
║       Chatwoot SDR IA - Image Rebuild Tool        ║
╚════════════════════════════════════════════════════╝

[INFO] Configurações de Build:
  Registry: localhost
  Image: chatwoot-sdr-ia
  Chatwoot Version: v4.1.0
  ...

[INFO] ✅ Build completado com sucesso!
```

---

## 🚢 Deploy no Docker Swarm

### Método 1: Script Automatizado (Recomendado)

```bash
chmod +x deploy.sh
./deploy.sh
```

O script vai:
- ✅ Verificar se a imagem existe
- ✅ Fazer backup da configuração atual
- ✅ Atualizar o serviço `chatwoot_app`
- ✅ Atualizar o serviço `chatwoot_sidekiq`
- ✅ Verificar se o módulo carregou corretamente

### Método 2: Manual

#### 2a. Atualizar serviço app

```bash
docker service update \
  --image localhost/chatwoot-sdr-ia:latest \
  --update-parallelism 1 \
  --update-delay 10s \
  chatwoot_chatwoot_app
```

#### 2b. Atualizar serviço sidekiq

```bash
docker service update \
  --image localhost/chatwoot-sdr-ia:latest \
  --update-parallelism 1 \
  --update-delay 10s \
  chatwoot_chatwoot_sidekiq
```

### Método 3: Atualizar Stack (Primeira vez)

Se você ainda não tem o Chatwoot rodando, use o stack file:

```bash
# 1. Copie o exemplo
cp chatwoot-stack-example.yaml chatwoot.yaml

# 2. Edite com suas configurações
nano chatwoot.yaml

# 3. Deploy
docker stack deploy -c chatwoot.yaml chatwoot
```

---

## ✅ Verificação

### 1. Verificar status dos serviços

```bash
docker service ps chatwoot_chatwoot_app
docker service ps chatwoot_chatwoot_sidekiq
```

**Status esperado:** `Running`

### 2. Verificar logs

```bash
# Ver logs do módulo SDR IA
docker service logs chatwoot_chatwoot_app -f | grep "SDR IA"
```

**Output esperado:**
```
[INFO] [SDR IA] Carregando módulo SDR IA...
[INFO] [SDR IA] Rotas carregadas
[INFO] [SDR IA] Módulo habilitado. Registrando listener...
[INFO] [SDR IA] Classes carregadas. Listener pronto.
```

### 3. Testar no container

```bash
# Encontrar container
CONTAINER=$(docker ps --filter "name=chatwoot_app" --format "{{.ID}}" | head -1)

# Testar módulo
docker exec $CONTAINER bundle exec rails runner "
  puts 'SDR IA enabled: ' + SdrIa.enabled?.to_s
  puts 'Config ID: ' + SdrIaConfig.first&.id.to_s
"
```

**Output esperado:**
```
SDR IA enabled: true
Config ID: 1
```

---

## ⚙️ Configuração Inicial

### 1. Acesse a interface web

```
https://chatteste.nexusatemporal.com
```

### 2. Faça login como administrador

### 3. Navegue para Configurações

```
Menu Lateral → Configurações → SDR IA
```

**IMPORTANTE:** Se o menu não aparecer:
- Faça hard refresh: `Ctrl + Shift + R` (Windows/Linux) ou `Cmd + Shift + R` (Mac)
- Limpe o cache do navegador
- Tente em aba anônima

### 4. Configure sua OpenAI API Key

1. No campo **"OpenAI API Key"**, cole sua chave
2. Escolha o modelo (recomendado: **GPT-4 Turbo**)
3. Ajuste os thresholds se desejar
4. Clique em **"Salvar Configurações"**

### 5. Teste a qualificação

1. Digite o ID de um contato existente
2. Clique em **"Testar"**
3. Aguarde a análise
4. Verifique o resultado!

---

## 🔄 Atualização

Quando houver uma nova versão do módulo:

```bash
# 1. Atualizar código
cd /root/chatwoot-sdr-ia
git pull origin main

# 2. Rebuild
./rebuild.sh

# 3. Deploy
./deploy.sh
```

**Tempo total:** ~10-15 minutos

**Zero downtime:** O deploy usa `update-parallelism: 1` e `order: start-first`

---

## 🐛 Troubleshooting

### Problema: Menu não aparece

**Causa:** Cache do navegador

**Solução:**
```
1. Hard refresh: Ctrl + Shift + R
2. Limpar cache do navegador
3. Tentar em aba anônima
4. Verificar logs: docker service logs chatwoot_chatwoot_app | grep "SDR IA"
```

### Problema: Erro ao salvar API Key

**Causa:** Tabela não foi criada

**Solução:**
```bash
# Rodar migration
CONTAINER=$(docker ps --filter "name=chatwoot_app" --format "{{.ID}}" | head -1)
docker exec $CONTAINER bundle exec rails db:migrate
```

### Problema: Jobs de qualificação não executam

**Causa:** Sidekiq não foi atualizado

**Solução:**
```bash
docker service update --image localhost/chatwoot-sdr-ia:latest chatwoot_chatwoot_sidekiq
```

### Problema: Build falha

**Causa 1:** Falta de espaço em disco

**Solução:**
```bash
# Limpar imagens antigas
docker system prune -a
```

**Causa 2:** Arquivos faltando

**Solução:**
```bash
# Verificar estrutura
ls -R plugins/ controllers/ models/ db/ config/ frontend/

# Deve mostrar todos os arquivos necessários
```

### Problema: Deploy falha

**Causa:** Serviço não existe

**Solução:**
```bash
# Ver todos os serviços
docker service ls

# Ajustar nomes no deploy.sh:
export SERVICE_APP="seu_servico_app"
export SERVICE_SIDEKIQ="seu_servico_sidekiq"
./deploy.sh
```

---

## 📊 Monitoramento

### Ver estatísticas em tempo real

```bash
# Leads qualificados
docker exec $(docker ps -q -f name=chatwoot_app) bundle exec rails runner "
  total = Contact.where(\"custom_attributes->>'sdr_ia_status' = 'qualificado'\").count
  quente = Contact.where(\"custom_attributes->>'sdr_ia_temperatura' = 'quente'\").count
  puts \"Total qualificados: #{total}\"
  puts \"Quentes: #{quente}\"
"
```

### Monitorar jobs

```bash
docker service logs -f chatwoot_chatwoot_sidekiq | grep "SDR IA"
```

---

## 🆘 Suporte

- **GitHub Issues:** https://github.com/eversonsantos-dev/chatwoot-sdr-ia/issues
- **Documentação completa:** [README.md](README.md)
- **Logs:** Sempre inclua os logs ao reportar problemas

---

## ✨ Próximos Passos

Após o deploy bem-sucedido:

1. ✅ Configure sua API Key
2. ✅ Teste com alguns contatos
3. ✅ Ajuste thresholds conforme necessário
4. ✅ Configure atribuição de times
5. ✅ Monitore as qualificações
6. ✅ Ajuste prompts se necessário (em `plugins/config/prompts.yml`)

---

**Desenvolvido com ❤️ para automatizar qualificação de leads**

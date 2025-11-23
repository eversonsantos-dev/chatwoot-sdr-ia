# Backup - aa4bd4f

**Data:** Sat Nov 22 21:24:50 -03 2025
**Descrição:** Versão estável v2.0.0-patch2 - Última versão funcional antes dos patches 3-5
**Commit:** aa4bd4f12b0eda7725cc4d1b3dc8a150ca8ca575

---

## 📦 CONTEÚDO DO BACKUP

### Arquivos
- `backup_20251122_212036.tar.gz` - Código fonte completo (114KB)
- `manifest_20251122_212036.json` - Metadados da versão
- `docker_image_20251122_212036.tar.gz` - Imagem Docker (850MB - **APENAS LOCAL**, não versionado no GitHub)
- `README.md` - Este arquivo

### Tamanho Total
```
850M
```

---

## 🔄 COMO RESTAURAR

### 1. Restaurar Código Fonte

```bash
# Extrair backup
cd /root
tar -xzf /root/chatwoot-sdr-ia/docs/backups/aa4bd4f/backup_20251122_212036.tar.gz

# Ou restaurar em novo diretório
mkdir -p /root/chatwoot-sdr-ia-restored
tar -xzf /root/chatwoot-sdr-ia/docs/backups/aa4bd4f/backup_20251122_212036.tar.gz -C /root/chatwoot-sdr-ia-restored
```

### 2. Restaurar Imagem Docker

```bash
# Carregar imagem Docker
gunzip -c docker_image_20251122_212036.tar.gz | docker load

# Verificar
docker images localhost/chatwoot-sdr-ia:aa4bd4f
```

### 3. Fazer Deploy

```bash
cd /root/chatwoot-sdr-ia

# Atualizar services
docker service update --image localhost/chatwoot-sdr-ia:aa4bd4f chatwoot_chatwoot_app
docker service update --image localhost/chatwoot-sdr-ia:aa4bd4f chatwoot_chatwoot_sidekiq

# Verificar status
docker service ps chatwoot_chatwoot_app
docker service ps chatwoot_chatwoot_sidekiq
```

---

## ✅ VERIFICAÇÃO PÓS-RESTAURAÇÃO

### 1. Verificar Containers
```bash
docker ps --filter "name=chatwoot" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
```

### 2. Verificar Logs
```bash
docker service logs chatwoot_chatwoot_app --tail 50
docker service logs chatwoot_chatwoot_sidekiq --tail 50
```

### 3. Testar API
```bash
curl https://chatteste.nexusatemporal.com/api/v1/accounts/1/sdr_ia/settings
```

### 4. Testar Painel
Acessar: https://chatteste.nexusatemporal.com/app/accounts/1/settings/sdr-ia

---

## 📊 INFORMAÇÕES DA VERSÃO

### Git Info
- **Commit:** aa4bd4f12b0eda7725cc4d1b3dc8a150ca8ca575
- **Branch:** HEAD
- **Tag:** aa4bd4f

### Arquivos Principais Incluídos
- Plugins SDR IA
- Controllers API
- Models
- Migrations
- Frontend (Vue.js)
- Dockerfile
- Scripts de deploy

---

## ⚠️ NOTAS IMPORTANTES

1. **Banco de Dados NÃO está incluído** - Migrations serão re-executadas
2. **Volumes Docker são preservados** - Dados do Chatwoot mantidos
3. **Redis cache será limpo** - Normal após restart
4. **Assets podem precisar recompilação** - Se houver problemas de cache
5. **Imagem Docker (850MB) armazenada apenas localmente** - Não versionada no GitHub devido ao limite de 100MB por arquivo. Disponível em `/root/chatwoot-sdr-ia/docs/backups/aa4bd4f/`

---

**Backup criado por:** backup-version.sh
**Sistema:** Chatwoot SDR IA vaa4bd4f

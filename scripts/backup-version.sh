#!/bin/bash
#
# SCRIPT DE BACKUP DE VERSÃO ESTÁVEL
# Chatwoot SDR IA
#
# Uso: ./scripts/backup-version.sh [tag_version] [description]
# Exemplo: ./scripts/backup-version.sh v2.0.0-patch2 "Versão estável antes dos patches 3-5"
#

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
BACKUP_DIR="/root/chatwoot-sdr-ia/docs/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Parâmetros
VERSION_TAG=${1:-$(git describe --tags --abbrev=0 2>/dev/null || git rev-parse --short HEAD)}
DESCRIPTION=${2:-"Backup automático"}

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════╗"
echo "║     Chatwoot SDR IA - Backup de Versão Tool       ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${GREEN}[INFO]${NC} Criando backup da versão: ${VERSION_TAG}"
echo -e "${GREEN}[INFO]${NC} Descrição: ${DESCRIPTION}"
echo -e "${GREEN}[INFO]${NC} Timestamp: ${TIMESTAMP}"
echo ""

# Criar diretório de backup se não existir
mkdir -p "${BACKUP_DIR}/${VERSION_TAG}"

# Nome do arquivo de backup
BACKUP_FILE="${BACKUP_DIR}/${VERSION_TAG}/backup_${TIMESTAMP}.tar.gz"

echo -e "${GREEN}[INFO]${NC} Criando arquivo de backup..."

# Criar backup completo do código (exceto node_modules, .git grande demais)
tar -czf "${BACKUP_FILE}" \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='public/packs' \
  --exclude='public/vite' \
  --exclude='tmp' \
  --exclude='log' \
  -C /root/chatwoot-sdr-ia \
  .

echo -e "${GREEN}[INFO]${NC} Backup criado: ${BACKUP_FILE}"

# Criar manifest com informações da versão
MANIFEST_FILE="${BACKUP_DIR}/${VERSION_TAG}/manifest_${TIMESTAMP}.json"

cat > "${MANIFEST_FILE}" <<EOF
{
  "version": "${VERSION_TAG}",
  "description": "${DESCRIPTION}",
  "timestamp": "${TIMESTAMP}",
  "date": "$(date -Iseconds)",
  "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'N/A')",
  "git_branch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'N/A')",
  "backup_file": "$(basename ${BACKUP_FILE})",
  "backup_size": "$(du -h ${BACKUP_FILE} | cut -f1)",
  "files_included": [
    "plugins/sdr_ia/**/*",
    "controllers/api/v1/accounts/sdr_ia/**/*",
    "models/sdr_ia_config.rb",
    "db/migrate/*sdr_ia*",
    "config/initializers/sdr_ia.rb",
    "config/routes.rb",
    "patches/async_dispatcher.rb",
    "frontend/routes/dashboard/settings/sdr-ia/**/*",
    "Dockerfile",
    "docker-compose.yml",
    "rebuild.sh",
    "deploy.sh",
    "docs/**/*"
  ],
  "docker_images": $(docker images localhost/chatwoot-sdr-ia:${VERSION_TAG} --format '{"repository":"{{.Repository}}","tag":"{{.Tag}}","id":"{{.ID}}","created":"{{.CreatedAt}}","size":"{{.Size}}"}' 2>/dev/null || echo '{}')
}
EOF

echo -e "${GREEN}[INFO]${NC} Manifest criado: ${MANIFEST_FILE}"

# Exportar imagem Docker se existir
if docker images | grep -q "localhost/chatwoot-sdr-ia.*${VERSION_TAG}"; then
  echo -e "${GREEN}[INFO]${NC} Exportando imagem Docker..."
  DOCKER_IMAGE_FILE="${BACKUP_DIR}/${VERSION_TAG}/docker_image_${TIMESTAMP}.tar"
  docker save -o "${DOCKER_IMAGE_FILE}" "localhost/chatwoot-sdr-ia:${VERSION_TAG}"
  gzip "${DOCKER_IMAGE_FILE}"
  echo -e "${GREEN}[INFO]${NC} Imagem Docker exportada: ${DOCKER_IMAGE_FILE}.gz"
else
  echo -e "${YELLOW}[WARN]${NC} Imagem Docker não encontrada: localhost/chatwoot-sdr-ia:${VERSION_TAG}"
fi

# Criar README do backup
README_FILE="${BACKUP_DIR}/${VERSION_TAG}/README.md"

cat > "${README_FILE}" <<EOF
# Backup - ${VERSION_TAG}

**Data:** $(date)
**Descrição:** ${DESCRIPTION}
**Commit:** $(git rev-parse HEAD 2>/dev/null || echo 'N/A')

---

## 📦 CONTEÚDO DO BACKUP

### Arquivos
- \`backup_${TIMESTAMP}.tar.gz\` - Código fonte completo
- \`manifest_${TIMESTAMP}.json\` - Metadados da versão
- \`docker_image_${TIMESTAMP}.tar.gz\` - Imagem Docker (se disponível)
- \`README.md\` - Este arquivo

### Tamanho Total
\`\`\`
$(du -sh ${BACKUP_DIR}/${VERSION_TAG} | cut -f1)
\`\`\`

---

## 🔄 COMO RESTAURAR

### 1. Restaurar Código Fonte

\`\`\`bash
# Extrair backup
cd /root
tar -xzf ${BACKUP_FILE}

# Ou restaurar em novo diretório
mkdir -p /root/chatwoot-sdr-ia-restored
tar -xzf ${BACKUP_FILE} -C /root/chatwoot-sdr-ia-restored
\`\`\`

### 2. Restaurar Imagem Docker

\`\`\`bash
# Carregar imagem Docker
gunzip -c docker_image_${TIMESTAMP}.tar.gz | docker load

# Verificar
docker images localhost/chatwoot-sdr-ia:${VERSION_TAG}
\`\`\`

### 3. Fazer Deploy

\`\`\`bash
cd /root/chatwoot-sdr-ia

# Atualizar services
docker service update --image localhost/chatwoot-sdr-ia:${VERSION_TAG} chatwoot_chatwoot_app
docker service update --image localhost/chatwoot-sdr-ia:${VERSION_TAG} chatwoot_chatwoot_sidekiq

# Verificar status
docker service ps chatwoot_chatwoot_app
docker service ps chatwoot_chatwoot_sidekiq
\`\`\`

---

## ✅ VERIFICAÇÃO PÓS-RESTAURAÇÃO

### 1. Verificar Containers
\`\`\`bash
docker ps --filter "name=chatwoot" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
\`\`\`

### 2. Verificar Logs
\`\`\`bash
docker service logs chatwoot_chatwoot_app --tail 50
docker service logs chatwoot_chatwoot_sidekiq --tail 50
\`\`\`

### 3. Testar API
\`\`\`bash
curl https://chatteste.nexusatemporal.com/api/v1/accounts/1/sdr_ia/settings
\`\`\`

### 4. Testar Painel
Acessar: https://chatteste.nexusatemporal.com/app/accounts/1/settings/sdr-ia

---

## 📊 INFORMAÇÕES DA VERSÃO

### Git Info
- **Commit:** $(git rev-parse HEAD 2>/dev/null || echo 'N/A')
- **Branch:** $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'N/A')
- **Tag:** ${VERSION_TAG}

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

---

**Backup criado por:** backup-version.sh
**Sistema:** Chatwoot SDR IA v${VERSION_TAG}
EOF

echo -e "${GREEN}[INFO]${NC} README criado: ${README_FILE}"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              BACKUP CONCLUÍDO COM SUCESSO          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Localização:${NC} ${BACKUP_DIR}/${VERSION_TAG}/"
echo -e "${BLUE}Arquivos:${NC}"
ls -lh "${BACKUP_DIR}/${VERSION_TAG}/" | tail -n +2 | awk '{printf "  - %s (%s)\n", $9, $5}'
echo ""
echo -e "${GREEN}[INFO]${NC} Para restaurar, consulte: ${README_FILE}"
echo ""

# Listar todos os backups disponíveis
echo -e "${BLUE}Backups Disponíveis:${NC}"
echo ""
for backup_version in $(ls -d ${BACKUP_DIR}/*/ 2>/dev/null | sort -r); do
  version_name=$(basename ${backup_version})
  backup_count=$(ls ${backup_version}backup_*.tar.gz 2>/dev/null | wc -l)
  total_size=$(du -sh ${backup_version} 2>/dev/null | cut -f1)
  echo -e "  📦 ${YELLOW}${version_name}${NC} - ${backup_count} backup(s) - ${total_size}"
done
echo ""

#!/bin/bash
# Chatwoot SDR IA - Rebuild Script
# Este script automatiza o processo de build da imagem customizada

set -e  # Exit on error

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
DOCKER_REGISTRY="${DOCKER_REGISTRY:-localhost}"
IMAGE_NAME="${IMAGE_NAME:-chatwoot-sdr-ia}"
CHATWOOT_VERSION="${CHATWOOT_VERSION:-v4.1.0}"
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Banner
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════╗"
echo "║       Chatwoot SDR IA - Image Rebuild Tool        ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Função de log
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se está no diretório correto
if [ ! -f "Dockerfile" ]; then
    log_error "Dockerfile não encontrado! Execute este script do diretório chatwoot-sdr-ia/"
    exit 1
fi

# Mostrar configurações
log_info "Configurações de Build:"
echo "  Registry: $DOCKER_REGISTRY"
echo "  Image: $IMAGE_NAME"
echo "  Chatwoot Version: $CHATWOOT_VERSION"
echo "  Git Commit: $GIT_COMMIT"
echo "  Build Date: $BUILD_DATE"
echo ""

# Perguntar confirmação
read -p "Deseja continuar com o build? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log_warn "Build cancelado pelo usuário"
    exit 0
fi

# Limpar builds anteriores (opcional)
log_info "Limpando builds anteriores..."
docker image prune -f > /dev/null 2>&1 || true

# Build da imagem
log_info "Iniciando build da imagem..."
docker build \
    --build-arg CHATWOOT_VERSION=$CHATWOOT_VERSION \
    --label "build.date=$BUILD_DATE" \
    --label "build.commit=$GIT_COMMIT" \
    --label "build.version=1.0.0" \
    -t $DOCKER_REGISTRY/$IMAGE_NAME:latest \
    -t $DOCKER_REGISTRY/$IMAGE_NAME:$GIT_COMMIT \
    -t $DOCKER_REGISTRY/$IMAGE_NAME:$(date +%Y%m%d) \
    .

if [ $? -eq 0 ]; then
    log_info "✅ Build completado com sucesso!"
    echo ""
    log_info "Tags criadas:"
    echo "  - $DOCKER_REGISTRY/$IMAGE_NAME:latest"
    echo "  - $DOCKER_REGISTRY/$IMAGE_NAME:$GIT_COMMIT"
    echo "  - $DOCKER_REGISTRY/$IMAGE_NAME:$(date +%Y%m%d)"
    echo ""

    # Mostrar tamanho da imagem
    IMAGE_SIZE=$(docker images $DOCKER_REGISTRY/$IMAGE_NAME:latest --format "{{.Size}}")
    log_info "Tamanho da imagem: $IMAGE_SIZE"

    # Próximos passos
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    log_info "Próximos passos:"
    echo "  1. Testar a imagem localmente:"
    echo "     docker run -it --rm $DOCKER_REGISTRY/$IMAGE_NAME:latest bundle exec rails runner 'puts SdrIa.enabled?'"
    echo ""
    echo "  2. Fazer deploy no Swarm:"
    echo "     ./deploy.sh"
    echo ""
    echo "  3. Ou atualizar manualmente:"
    echo "     docker service update --image $DOCKER_REGISTRY/$IMAGE_NAME:latest chatwoot_chatwoot_app"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
else
    log_error "❌ Falha no build!"
    exit 1
fi

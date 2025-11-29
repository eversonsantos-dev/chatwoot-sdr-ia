#!/bin/bash
# ============================================================
# Build and Push Script - Chatwoot SDR IA Latest
# ============================================================
# Este script faz o build e push da imagem Docker para o Docker Hub
#
# Uso:
#   ./build-and-push.sh                    # Build com Chatwoot v4.8.0 (default)
#   ./build-and-push.sh v4.9.0             # Build com versão específica
# ============================================================

set -e

# Configurações
DOCKER_USER="eversonsantosdev"
IMAGE_NAME="chatwoot-sdr-ia-latest"
CHATWOOT_VERSION="${1:-v4.8.0}"
SDR_IA_VERSION="4.0.0"

echo "=============================================="
echo " Chatwoot SDR IA - Build & Push"
echo "=============================================="
echo " Docker User: $DOCKER_USER"
echo " Image: $IMAGE_NAME"
echo " SDR IA Version: $SDR_IA_VERSION"
echo " Chatwoot Version: $CHATWOOT_VERSION"
echo "=============================================="

# Login no Docker Hub
echo ""
echo "[1/4] Fazendo login no Docker Hub..."
echo "Digite seu token Docker Hub quando solicitado:"
docker login -u $DOCKER_USER

# Build da imagem
echo ""
echo "[2/4] Fazendo build da imagem..."
docker build \
    -f Dockerfile.latest \
    --build-arg CHATWOOT_VERSION=$CHATWOOT_VERSION \
    -t $DOCKER_USER/$IMAGE_NAME:$SDR_IA_VERSION \
    -t $DOCKER_USER/$IMAGE_NAME:latest \
    -t $DOCKER_USER/$IMAGE_NAME:chatwoot-$CHATWOOT_VERSION \
    .

# Push das tags
echo ""
echo "[3/4] Fazendo push das imagens..."
docker push $DOCKER_USER/$IMAGE_NAME:$SDR_IA_VERSION
docker push $DOCKER_USER/$IMAGE_NAME:latest
docker push $DOCKER_USER/$IMAGE_NAME:chatwoot-$CHATWOOT_VERSION

# Verificar
echo ""
echo "[4/4] Verificando imagens no Docker Hub..."
docker images | grep $IMAGE_NAME

echo ""
echo "=============================================="
echo " BUILD E PUSH CONCLUÍDOS COM SUCESSO!"
echo "=============================================="
echo ""
echo " Imagens disponíveis:"
echo "   - $DOCKER_USER/$IMAGE_NAME:$SDR_IA_VERSION"
echo "   - $DOCKER_USER/$IMAGE_NAME:latest"
echo "   - $DOCKER_USER/$IMAGE_NAME:chatwoot-$CHATWOOT_VERSION"
echo ""
echo " Para usar:"
echo "   docker pull $DOCKER_USER/$IMAGE_NAME:latest"
echo ""

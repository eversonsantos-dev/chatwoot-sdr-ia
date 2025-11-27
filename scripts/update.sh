#!/bin/bash

# ============================================================
# Chatwoot SDR IA - Script de Atualização
# ============================================================
# Atualiza o Chatwoot SDR IA para a versão mais recente
#
# Uso: ./update.sh [versão]
# Exemplos:
#   ./update.sh           # Atualiza para latest
#   ./update.sh v2.2.0    # Atualiza para versão específica
# ============================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Versão
VERSION=${1:-latest}

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║           CHATWOOT SDR IA - ATUALIZAÇÃO                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}[INFO] Atualizando para versão: ${VERSION}${NC}"
echo ""

# Verificar se os serviços existem
if ! docker service ls | grep -q chatwoot_app; then
    echo -e "${RED}[ERRO] Serviço chatwoot_app não encontrado${NC}"
    echo "Certifique-se de que o Chatwoot está instalado"
    exit 1
fi

# Pull da nova imagem
echo -e "${BLUE}[INFO] Baixando nova imagem...${NC}"
docker pull eversonsantosdev/chatwoot-sdr-ia:${VERSION}

# Atualizar app
echo -e "${BLUE}[INFO] Atualizando chatwoot_app...${NC}"
docker service update \
    --image eversonsantosdev/chatwoot-sdr-ia:${VERSION} \
    --update-parallelism 1 \
    --update-delay 10s \
    --update-failure-action rollback \
    chatwoot_app

# Atualizar sidekiq
echo -e "${BLUE}[INFO] Atualizando chatwoot_sidekiq...${NC}"
docker service update \
    --image eversonsantosdev/chatwoot-sdr-ia:${VERSION} \
    --update-parallelism 1 \
    --update-delay 10s \
    --update-failure-action rollback \
    chatwoot_sidekiq

# Aguardar
echo -e "${BLUE}[INFO] Aguardando serviços reiniciarem...${NC}"
sleep 15

# Status
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ATUALIZAÇÃO CONCLUÍDA!                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Status dos serviços:${NC}"
docker service ls | grep chatwoot
echo ""
echo -e "${BLUE}Para ver os logs:${NC}"
echo "  docker service logs chatwoot_app -f"
echo ""

#!/bin/bash

# ============================================================
# Chatwoot SDR IA - Script de Instalação
# ============================================================
# Instala o Chatwoot com módulo SDR IA em Docker Swarm
#
# Uso: curl -sSL https://raw.githubusercontent.com/eversonsantos-dev/chatwoot-sdr-ia/main/scripts/install.sh | bash
# ============================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║       CHATWOOT SDR IA - INSTALAÇÃO AUTOMÁTICA             ║"
echo "║                                                            ║"
echo "║       Qualificação Automática de Leads com IA             ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERRO] Execute este script como root (sudo)${NC}"
    exit 1
fi

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[ERRO] Docker não está instalado${NC}"
    echo "Instale o Docker primeiro: https://docs.docker.com/engine/install/"
    exit 1
fi

# Verificar Docker Swarm
if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
    echo -e "${YELLOW}[INFO] Inicializando Docker Swarm...${NC}"
    docker swarm init 2>/dev/null || docker swarm init --advertise-addr $(hostname -I | awk '{print $1}')
fi

echo -e "${GREEN}[OK] Docker Swarm ativo${NC}"

# Criar diretório de instalação
INSTALL_DIR="/opt/chatwoot-sdr-ia"
echo -e "${BLUE}[INFO] Criando diretório de instalação: ${INSTALL_DIR}${NC}"
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# Baixar arquivos
echo -e "${BLUE}[INFO] Baixando arquivos de configuração...${NC}"

curl -sSL -o chatwoot-sdr-ia.yml \
    https://raw.githubusercontent.com/eversonsantos-dev/chatwoot-sdr-ia/main/stack/chatwoot-sdr-ia.yml

curl -sSL -o .env.example \
    https://raw.githubusercontent.com/eversonsantos-dev/chatwoot-sdr-ia/main/stack/.env.example

# Criar .env se não existir
if [ ! -f .env ]; then
    echo -e "${YELLOW}[INFO] Criando arquivo .env...${NC}"
    cp .env.example .env

    # Gerar SECRET_KEY_BASE
    SECRET_KEY=$(openssl rand -hex 64)
    sed -i "s/SECRET_KEY_BASE=.*/SECRET_KEY_BASE=${SECRET_KEY}/" .env

    # Gerar POSTGRES_PASSWORD
    PG_PASS=$(openssl rand -hex 32)
    sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${PG_PASS}/" .env

    echo -e "${GREEN}[OK] Arquivo .env criado com chaves geradas automaticamente${NC}"
else
    echo -e "${YELLOW}[INFO] Arquivo .env já existe, mantendo configuração atual${NC}"
fi

# Perguntar URL
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
read -p "Digite a URL do seu Chatwoot (ex: chat.suaempresa.com): " CHATWOOT_URL

if [ ! -z "$CHATWOOT_URL" ]; then
    sed -i "s|FRONTEND_URL=.*|FRONTEND_URL=https://${CHATWOOT_URL}|" .env
    sed -i "s|FRONTEND_URL_HOST=.*|FRONTEND_URL_HOST=${CHATWOOT_URL}|" .env
    echo -e "${GREEN}[OK] URL configurada: https://${CHATWOOT_URL}${NC}"
fi

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Fazer pull da imagem
echo -e "${BLUE}[INFO] Baixando imagem Docker (pode demorar alguns minutos)...${NC}"
docker pull eversonsantosdev/chatwoot-sdr-ia:latest

# Deploy da stack
echo -e "${BLUE}[INFO] Fazendo deploy da stack...${NC}"
docker stack deploy -c chatwoot-sdr-ia.yml chatwoot

# Aguardar serviços
echo -e "${BLUE}[INFO] Aguardando serviços iniciarem...${NC}"
sleep 10

# Verificar status
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  INSTALAÇÃO CONCLUÍDA!                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Status dos serviços:${NC}"
docker service ls | grep chatwoot
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. Configure o arquivo .env em: ${INSTALL_DIR}/.env"
echo "2. Atualize a stack: docker stack deploy -c chatwoot-sdr-ia.yml chatwoot"
echo "3. Acesse: https://${CHATWOOT_URL:-seu-dominio.com}"
echo ""
echo -e "${BLUE}Comandos úteis:${NC}"
echo "  Ver logs:     docker service logs chatwoot_app -f"
echo "  Ver status:   docker service ls | grep chatwoot"
echo "  Atualizar:    docker service update --image eversonsantosdev/chatwoot-sdr-ia:latest chatwoot_app"
echo ""

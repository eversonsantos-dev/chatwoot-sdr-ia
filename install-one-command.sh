#!/bin/bash

# ============================================================================
# CHATWOOT SDR IA - INSTALAÇÃO DE 1 COMANDO
# ============================================================================
#
# Execute diretamente com:
#
#   curl -sSL https://raw.githubusercontent.com/SEU-USUARIO/chatwoot-sdr-ia/main/install-one-command.sh | bash
#
# Ou com parâmetros:
#
#   curl -sSL ... | bash -s -- --api-key=sk-xxx
#
# ============================================================================

set -e

VERSION="2.1.1"
REPO_URL="https://github.com/eversonsantos-dev/chatwoot-sdr-ia"
INSTALL_DIR="/tmp/chatwoot-sdr-ia-install"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║        CHATWOOT SDR IA - INSTALAÇÃO AUTOMÁTICA v${VERSION}            ║"
echo "║                    (Instalação de 1 Comando)                       ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar se é root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[✗]${NC} Este script precisa ser executado como root"
   echo "    Execute: sudo bash ou acesse como root"
   exit 1
fi

# Verificar dependências
echo -e "${BLUE}[INFO]${NC} Verificando dependências..."

for cmd in curl git docker; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}[✗]${NC} $cmd não encontrado"
        echo "    Instale com: apt install $cmd"
        exit 1
    fi
done

echo -e "${GREEN}[✓]${NC} Dependências OK"

# Limpar instalação anterior
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Clonar repositório
echo ""
echo -e "${BLUE}[INFO]${NC} Baixando SDR IA..."

# Tentar clone público primeiro
if git clone --depth 1 "$REPO_URL" . 2>/dev/null; then
    echo -e "${GREEN}[✓]${NC} Repositório clonado"
else
    # Se falhar, pedir token
    echo -e "${YELLOW}[!]${NC} Repositório privado detectado"
    echo ""
    read -p "Digite o TOKEN DE ACESSO do GitHub: " GH_TOKEN

    if [ -z "$GH_TOKEN" ]; then
        echo -e "${RED}[✗]${NC} Token obrigatório para repositório privado"
        exit 1
    fi

    # Clone com token
    REPO_WITH_TOKEN=$(echo "$REPO_URL" | sed "s|https://|https://${GH_TOKEN}@|")

    if git clone --depth 1 "$REPO_WITH_TOKEN" . 2>/dev/null; then
        echo -e "${GREEN}[✓]${NC} Repositório clonado"
    else
        echo -e "${RED}[✗]${NC} Falha ao clonar. Verifique o token."
        exit 1
    fi
fi

# Verificar se instalador existe
if [ ! -f "install-smart.sh" ]; then
    if [ -f "install.sh" ]; then
        echo -e "${YELLOW}[!]${NC} Usando instalador legado"
        chmod +x install.sh
        ./install.sh "$@"
        exit $?
    else
        echo -e "${RED}[✗]${NC} Instalador não encontrado no pacote"
        exit 1
    fi
fi

# Executar instalador inteligente
echo ""
echo -e "${GREEN}[✓]${NC} Executando instalador..."
chmod +x install-smart.sh
./install-smart.sh "$@"

# Limpar
echo ""
echo -e "${BLUE}[INFO]${NC} Limpando arquivos temporários..."
cd /
rm -rf "$INSTALL_DIR"

echo ""
echo -e "${GREEN}[✓]${NC} Instalação concluída!"
echo ""

#!/bin/bash

# 🚀 Instalação Remota - Chatwoot SDR IA v2.1.1
# Baixa e instala diretamente do repositório privado

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     CHATWOOT SDR IA - INSTALAÇÃO REMOTA (1 COMANDO)      ║"
echo "║                     Versão 2.1.1                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[✗]${NC} Este script precisa ser executado como root (use sudo)"
   exit 1
fi

# Pedir token de acesso
echo ""
echo -e "${YELLOW}[!]${NC} Para baixar o plugin, você precisa do TOKEN DE ACESSO fornecido pelo vendedor."
echo ""
read -p "Digite o TOKEN DE ACESSO: " ACCESS_TOKEN

if [ -z "$ACCESS_TOKEN" ]; then
    echo -e "${RED}[✗]${NC} Token de acesso é obrigatório"
    exit 1
fi

# Baixar pacote do repositório privado
echo ""
echo -e "${BLUE}[INFO]${NC} Baixando plugin do repositório..."

cd /tmp
rm -rf chatwoot-sdr-ia-v2.1.1.tar.gz chatwoot-sdr-ia-v2.1.1

# Baixar usando o token
curl -L -H "Authorization: token ${ACCESS_TOKEN}" \
  -H "Accept: application/vnd.github.v3.raw" \
  "https://api.github.com/repos/eversonsantos-dev/chatwoot-sdr-ia/tarball/v2.1.1" \
  -o chatwoot-sdr-ia-v2.1.1.tar.gz

if [ $? -ne 0 ]; then
    echo -e "${RED}[✗]${NC} Erro ao baixar o plugin. Verifique seu token de acesso."
    exit 1
fi

echo -e "${GREEN}[✓]${NC} Plugin baixado com sucesso"

# Extrair
echo -e "${BLUE}[INFO]${NC} Extraindo arquivos..."
mkdir -p chatwoot-sdr-ia-v2.1.1
tar -xzf chatwoot-sdr-ia-v2.1.1.tar.gz -C chatwoot-sdr-ia-v2.1.1 --strip-components=1

cd chatwoot-sdr-ia-v2.1.1

# Verificar se install.sh existe
if [ ! -f "install.sh" ]; then
    echo -e "${RED}[✗]${NC} Arquivo install.sh não encontrado no pacote"
    exit 1
fi

# Executar instalador
echo ""
echo -e "${GREEN}[✓]${NC} Iniciando instalação..."
echo ""
chmod +x install.sh
./install.sh

# Limpar arquivos temporários
cd /tmp
rm -rf chatwoot-sdr-ia-v2.1.1.tar.gz chatwoot-sdr-ia-v2.1.1

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              INSTALAÇÃO CONCLUÍDA COM SUCESSO!            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

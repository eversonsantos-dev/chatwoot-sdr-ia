#!/bin/bash

# Script para criar pacote de distribuição do Chatwoot SDR IA
# Para venda/distribuição comercial

VERSION="2.1.1"
PACKAGE_NAME="chatwoot-sdr-ia-v${VERSION}"

echo "🚀 Criando pacote de distribuição..."
echo "Versão: $VERSION"
echo ""

# Criar diretório temporário
TEMP_DIR="/tmp/${PACKAGE_NAME}"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Copiar arquivos necessários
echo "📦 Copiando arquivos..."

# Plugin principal
cp -r plugins "$TEMP_DIR/"

# Migrations
mkdir -p "$TEMP_DIR/db"
cp -r db/migrate "$TEMP_DIR/db/"

# Script de instalação
cp install.sh "$TEMP_DIR/"
chmod +x "$TEMP_DIR/install.sh"

# Documentação
cp INSTALACAO.md "$TEMP_DIR/"
cp CHANGELOG.md "$TEMP_DIR/"
cp RELEASE_v2.1.1.md "$TEMP_DIR/README.md"

# Criar arquivo de versão
echo "v${VERSION}" > "$TEMP_DIR/VERSION"

# Criar README de instalação rápida
cat > "$TEMP_DIR/LEIA-ME.txt" <<'LEIAME'
╔════════════════════════════════════════════════════════════╗
║        CHATWOOT SDR IA - INSTALAÇÃO                       ║
║                   Versão 2.1.1                             ║
╚════════════════════════════════════════════════════════════╝

📋 REQUISITOS:
- Chatwoot instalado (versão 2.x ou superior)
- Acesso root ao servidor
- API Key da OpenAI

⚡ INSTALAÇÃO RÁPIDA:

1. Fazer upload deste pacote para o servidor:
   scp chatwoot-sdr-ia-v2.1.1.tar.gz root@seu-servidor:/root/

2. Conectar ao servidor:
   ssh root@seu-servidor

3. Extrair e instalar:
   cd /root
   tar -xzf chatwoot-sdr-ia-v2.1.1.tar.gz
   cd chatwoot-sdr-ia-v2.1.1
   sudo ./install.sh

O instalador vai:
✅ Detectar automaticamente o Chatwoot
✅ Criar backup antes de instalar
✅ Copiar todos os arquivos necessários
✅ Configurar variáveis de ambiente
✅ Executar migrations do banco
✅ Criar documentação

📚 DOCUMENTAÇÃO COMPLETA:
Após instalar, leia: INSTALACAO.md

🎯 FUNCIONALIDADES:
- IA Conversacional automática
- Transcrição de áudio (WhatsApp)
- Qualificação inteligente de leads (0-130 pontos)
- Round Robin automático
- Buffer de mensagens (35s) - Reduz custos em 70%

📞 SUPORTE:
Entre em contato para suporte técnico, atualizações ou customizações.

═══════════════════════════════════════════════════════════
Desenvolvido para Chatwoot | Versão 2.1.1 | Novembro 2025
═══════════════════════════════════════════════════════════
LEIAME

# Criar estrutura de diretórios esperada
echo ""
echo "📁 Estrutura do pacote:"
tree -L 2 "$TEMP_DIR" 2>/dev/null || find "$TEMP_DIR" -maxdepth 2 -type d | head -20

# Criar arquivo TAR.GZ
echo ""
echo "🗜️  Comprimindo pacote..."
cd /tmp
tar -czf "${PACKAGE_NAME}.tar.gz" "${PACKAGE_NAME}"

# Mover para diretório de builds
BUILDS_DIR="/root/builds"
mkdir -p "$BUILDS_DIR"
mv "${PACKAGE_NAME}.tar.gz" "$BUILDS_DIR/"

# Calcular hash
cd "$BUILDS_DIR"
SHA256=$(sha256sum "${PACKAGE_NAME}.tar.gz" | awk '{print $1}')

# Limpar temporários
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Pacote criado com sucesso!"
echo ""
echo "📦 Arquivo: $BUILDS_DIR/${PACKAGE_NAME}.tar.gz"
echo "📊 Tamanho: $(du -h "$BUILDS_DIR/${PACKAGE_NAME}.tar.gz" | awk '{print $1}')"
echo "🔐 SHA256: $SHA256"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "INSTRUÇÕES PARA DISTRIBUIÇÃO:"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "1. Envie o arquivo para o cliente:"
echo "   $BUILDS_DIR/${PACKAGE_NAME}.tar.gz"
echo ""
echo "2. Cliente deve extrair:"
echo "   tar -xzf ${PACKAGE_NAME}.tar.gz"
echo "   cd ${PACKAGE_NAME}"
echo ""
echo "3. Cliente executa instalador:"
echo "   sudo ./install.sh"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""

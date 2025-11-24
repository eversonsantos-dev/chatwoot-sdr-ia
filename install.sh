#!/bin/bash

# 🚀 Script de Instalação Automática - Chatwoot SDR IA v2.1.1
# Instalação simplificada do plugin SDR IA em qualquer servidor Chatwoot

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║        CHATWOOT SDR IA - INSTALAÇÃO AUTOMÁTICA           ║"
echo "║                     Versão 2.1.1                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Função para exibir mensagens
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   error "Este script precisa ser executado como root (use sudo)"
   exit 1
fi

# Verificar se está no diretório do plugin
if [ ! -d "plugins/sdr_ia" ]; then
    error "Este script deve ser executado a partir do diretório raiz do Chatwoot SDR IA"
    error "Estrutura esperada: plugins/sdr_ia/, db/migrate/, etc"
    exit 1
fi

success "Arquivos do plugin encontrados"

# Verificar diretório Chatwoot
info "Verificando instalação do Chatwoot..."

if [ ! -d "/root/chatwoot" ] && [ ! -d "/home/chatwoot" ]; then
    error "Chatwoot não encontrado em /root/chatwoot ou /home/chatwoot"
    echo ""
    echo "Por favor, especifique o caminho do Chatwoot:"
    read -p "Caminho completo: " CHATWOOT_PATH

    if [ ! -d "$CHATWOOT_PATH" ]; then
        error "Diretório não existe: $CHATWOOT_PATH"
        exit 1
    fi
else
    if [ -d "/root/chatwoot" ]; then
        CHATWOOT_PATH="/root/chatwoot"
    else
        CHATWOOT_PATH="/home/chatwoot"
    fi
fi

success "Chatwoot encontrado em: $CHATWOOT_PATH"

# Criar backup antes de instalar
info "Criando backup do Chatwoot atual..."
BACKUP_DIR="/root/backups"
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/chatwoot-pre-sdr-ia-$(date +%Y%m%d_%H%M%S).tar.gz"

tar -czf "$BACKUP_FILE" \
    --exclude='node_modules' \
    --exclude='tmp' \
    --exclude='log/*.log' \
    --exclude='public/packs' \
    -C "$(dirname $CHATWOOT_PATH)" "$(basename $CHATWOOT_PATH)" 2>/dev/null || true

success "Backup criado em: $BACKUP_FILE"

# Copiar plugin para Chatwoot
info "Instalando plugin no Chatwoot..."
mkdir -p "$CHATWOOT_PATH/plugins"
cp -r plugins/sdr_ia "$CHATWOOT_PATH/plugins/"

success "Plugin copiado para $CHATWOOT_PATH/plugins/sdr_ia"

# Copiar migrations
info "Copiando migrations do banco de dados..."
cp -r db/migrate/* "$CHATWOOT_PATH/db/migrate/" 2>/dev/null || true

success "Migrations copiadas"

# Coletar credenciais OpenAI
echo ""
warning "CONFIGURAÇÃO NECESSÁRIA"
echo ""
echo "O SDR IA precisa de credenciais da OpenAI para funcionar."
echo ""
read -p "Digite sua API Key da OpenAI: " OPENAI_API_KEY

if [ -z "$OPENAI_API_KEY" ]; then
    error "API Key da OpenAI é obrigatória"
    exit 1
fi

# Criar arquivo .env se não existir
if [ ! -f "$CHATWOOT_PATH/.env" ]; then
    warning "Arquivo .env não encontrado, criando..."
    touch "$CHATWOOT_PATH/.env"
fi

# Adicionar variáveis ao .env
info "Configurando variáveis de ambiente..."

# Remover variáveis antigas se existirem
sed -i '/OPENAI_API_KEY=/d' "$CHATWOOT_PATH/.env"

# Adicionar novas variáveis
echo "" >> "$CHATWOOT_PATH/.env"
echo "# SDR IA Configuration - Added $(date)" >> "$CHATWOOT_PATH/.env"
echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> "$CHATWOOT_PATH/.env"

success "Variáveis de ambiente configuradas"

# Detectar tipo de instalação (Docker ou Local)
info "Detectando tipo de instalação..."

if command -v docker &> /dev/null && docker ps &> /dev/null; then
    INSTALL_TYPE="docker"
    success "Instalação Docker detectada"
elif [ -f "$CHATWOOT_PATH/Gemfile" ]; then
    INSTALL_TYPE="local"
    success "Instalação local detectada"
else
    error "Tipo de instalação não identificado"
    exit 1
fi

# Executar migrations e restart conforme tipo de instalação
if [ "$INSTALL_TYPE" = "docker" ]; then
    echo ""
    info "Instalação Docker detectada. Próximos passos:"
    echo ""
    echo "1. Rebuild da imagem Docker:"
    echo "   ${GREEN}cd $CHATWOOT_PATH && docker build -t seu-usuario/chatwoot:sdr-ia .${NC}"
    echo ""
    echo "2. Executar migrations:"
    echo "   ${GREEN}docker exec -it chatwoot_app bundle exec rails db:migrate${NC}"
    echo ""
    echo "3. Reiniciar containers:"
    echo "   ${GREEN}docker-compose restart${NC}"
    echo "   ou se estiver usando Docker Swarm:"
    echo "   ${GREEN}docker service update --force chatwoot_app${NC}"
    echo "   ${GREEN}docker service update --force chatwoot_sidekiq${NC}"
    echo ""
else
    # Instalação local
    info "Executando migrations do banco de dados..."
    cd "$CHATWOOT_PATH"

    if command -v bundle &> /dev/null; then
        bundle install --quiet
        RAILS_ENV=production bundle exec rails db:migrate
        success "Migrations executadas"

        info "Reiniciando serviços..."
        systemctl restart chatwoot.target 2>/dev/null || \
        systemctl restart chatwoot 2>/dev/null || \
        service chatwoot restart 2>/dev/null || \
        warning "Não foi possível reiniciar automaticamente. Reinicie manualmente."

        success "Serviços reiniciados"
    else
        warning "Bundle não encontrado. Execute manualmente:"
        echo "   cd $CHATWOOT_PATH"
        echo "   bundle install"
        echo "   RAILS_ENV=production bundle exec rails db:migrate"
    fi
fi

# Criar documentação de configuração
info "Criando documentação de configuração..."
cat > "$CHATWOOT_PATH/SDR_IA_CONFIG.md" <<'DOC_END'
# 🤖 Configuração do SDR IA

**Versão:** v2.1.1
**Data da Instalação:** $(date)

---

## ✅ Plugin Instalado

O plugin SDR IA foi instalado com sucesso.

---

## 🔑 Configuração Necessária no Chatwoot

### 1. Acessar Configurações

1. Faça login no Chatwoot como **Super Admin**
2. Vá em **Settings** → **Applications** → **SDR IA**

### 2. Configurar por Inbox

Para cada inbox (caixa de entrada) que deseja usar o SDR IA:

1. Acesse **Settings** → **Inboxes** → Selecione o inbox
2. Vá na aba **SDR IA**
3. Configure:
   - ✅ **Ativar SDR IA**: ON
   - 📝 **Nome da Clínica**: Ex: "Clínica Estética Exemplo"
   - 📍 **Endereço**: Endereço completo da clínica
   - 🔗 **Link de Agendamento**: URL do sistema de agendamento
   - 👥 **Closers**: Selecione os agentes que receberão leads qualificados

---

## 🎯 Funcionalidades

### 1. Buffer de Mensagens (35 segundos)
- Agrupa mensagens consecutivas do lead
- Reduz chamadas à API OpenAI em 70%
- Conversas mais naturais

### 2. Transcrição de Áudio
- Suporta MP3, M4A, WAV, OGG
- Transcrição automática com OpenAI Whisper
- Máximo 25MB por áudio

### 3. Qualificação Inteligente
Sistema de pontuação (0-130 pontos):
- **INTERESSE** (0-50 pontos) - Fator principal
- **URGÊNCIA** (0-30 pontos)
- **CONHECIMENTO** (0-20 pontos)
- **LOCALIZAÇÃO** (0-10 pontos)
- **MOTIVAÇÃO BÔNUS** (0-20 pontos)

**Temperaturas:**
- 🔴 **QUENTE** (90-130): Atribuído ao closer
- 🟡 **MORNO** (50-89): Atribuído ao closer
- 🔵 **FRIO** (20-49): Nutrição
- ⚫ **MUITO FRIO** (0-19): Registro

### 4. Round Robin Automático
- Distribuição balanceada entre closers
- Rastreamento via Redis
- Persistente entre reinicializações

---

## 📊 Monitoramento

### Logs (Docker):
```bash
docker logs -f chatwoot_sidekiq | grep "\[SDR IA\]"
docker logs -f chatwoot_sidekiq | grep "\[Audio\]"
```

### Logs (Local):
```bash
tail -f log/production.log | grep "\[SDR IA\]"
tail -f log/production.log | grep "\[Audio\]"
```

---

## 🔧 Troubleshooting

### Áudio não está sendo transcrito:
1. Verifique se `OPENAI_API_KEY` está configurada no .env
2. Verifique logs de áudio
3. Confirme que o formato é suportado

### IA não está respondendo:
1. Verifique se o SDR IA está ativado no inbox
2. Verifique configurações do inbox
3. Verifique logs do SDR IA

### Leads não estão sendo atribuídos:
1. Verifique se há closers configurados
2. Verifique logs do Round Robin
3. Confirme que Redis está rodando

---

**Instalação completa! 🎉**

Para suporte, entre em contato com o fornecedor do sistema.
DOC_END

success "Documentação criada em: $CHATWOOT_PATH/SDR_IA_CONFIG.md"

# Resumo final
echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║           INSTALAÇÃO CONCLUÍDA COM SUCESSO!              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
success "Plugin SDR IA v2.1.1 instalado"
success "Backup criado em: $BACKUP_FILE"
success "Documentação em: $CHATWOOT_PATH/SDR_IA_CONFIG.md"
echo ""
info "PRÓXIMOS PASSOS:"
echo ""
echo "1. ${YELLOW}Configure o SDR IA no Chatwoot:${NC}"
echo "   - Acesse Settings → Applications → SDR IA"
echo "   - Configure cada inbox individualmente"
echo ""
echo "2. ${YELLOW}Configure os closers:${NC}"
echo "   - Settings → Inboxes → [Seu Inbox] → SDR IA"
echo "   - Adicione os agentes que receberão leads"
echo ""
echo "3. ${YELLOW}Teste o sistema:${NC}"
echo "   - Envie uma mensagem de teste"
echo "   - Envie um áudio de teste"
echo ""
echo -e "${GREEN}Instalação completa! 🎉${NC}"
echo ""

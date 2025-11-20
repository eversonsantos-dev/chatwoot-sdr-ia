#!/bin/bash

# ============================================================================
# Chatwoot SDR IA Module - Script de Atualização
# ============================================================================
#
# Este script atualiza o módulo SDR IA para a versão mais recente do GitHub.
#
# Uso: ./update.sh [opções]
#
# Opções:
#   --container <id>    Especifica o ID/nome do container manualmente
#   --skip-backup       Pula o backup (não recomendado)
#   --no-restart        Não reinicia os serviços após atualização
#   --help              Mostra esta ajuda
#
# ============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funções
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Variáveis
CONTAINER_ID=""
SKIP_BACKUP=false
NO_RESTART=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --container) CONTAINER_ID="$2"; shift 2 ;;
        --skip-backup) SKIP_BACKUP=true; shift ;;
        --no-restart) NO_RESTART=true; shift ;;
        --help)
            grep '^#' "$0" | grep -v '#!/bin/bash' | sed 's/^# //'
            exit 0
            ;;
        *)
            print_error "Opção desconhecida: $1"
            exit 1
            ;;
    esac
done

# Banner
clear
print_header "🔄 ATUALIZADOR - SDR IA MODULE"

# Verificar se estamos em um repositório git
if [ ! -d "$SCRIPT_DIR/.git" ]; then
    print_error "Este diretório não é um repositório git!"
    print_info "Clone o repositório primeiro:"
    print_info "git clone https://github.com/eversonsantos-dev/chatwoot-sdr-ia.git"
    exit 1
fi

# Verificar versão atual
print_info "Verificando versão atual..."
cd "$SCRIPT_DIR"
CURRENT_COMMIT=$(git rev-parse --short HEAD)
CURRENT_BRANCH=$(git branch --show-current)
print_info "Branch: $CURRENT_BRANCH"
print_info "Commit: $CURRENT_COMMIT"

# Buscar atualizações
print_header "1️⃣ BUSCANDO ATUALIZAÇÕES DO GITHUB"

print_info "Fazendo fetch do repositório..."
git fetch origin

LATEST_COMMIT=$(git rev-parse --short origin/$CURRENT_BRANCH)

if [ "$CURRENT_COMMIT" = "$LATEST_COMMIT" ]; then
    print_success "Você já está na versão mais recente!"
    print_info "Nada para atualizar."
    exit 0
fi

print_warning "Nova versão disponível!"
echo ""
echo "  Versão atual:  $CURRENT_COMMIT"
echo "  Nova versão:   $LATEST_COMMIT"
echo ""

# Mostrar mudanças
print_info "Mudanças:"
git log --oneline --decorate --color $CURRENT_COMMIT..$LATEST_COMMIT | head -10

echo ""
read -p "Deseja continuar com a atualização? (s/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
    print_warning "Atualização cancelada pelo usuário"
    exit 0
fi

# Pull das mudanças
print_header "2️⃣ BAIXANDO NOVA VERSÃO"

print_info "Fazendo pull..."
git pull origin $CURRENT_BRANCH || {
    print_error "Erro ao fazer pull!"
    print_warning "Pode haver conflitos locais."
    print_info "Tente: git stash && git pull"
    exit 1
}

print_success "Código atualizado!"

# Detectar container
print_header "3️⃣ DETECTANDO CONTAINER CHATWOOT"

if [ -z "$CONTAINER_ID" ]; then
    CONTAINER_ID=$(docker ps --filter "name=chatwoot" --filter "name=app" --format "{{.Names}}" | head -1)
    if [ -z "$CONTAINER_ID" ]; then
        print_error "Container não encontrado!"
        exit 1
    fi
fi

print_success "Container: $CONTAINER_ID"

# Backup
if [ "$SKIP_BACKUP" = false ]; then
    print_header "4️⃣ CRIANDO BACKUP"

    BACKUP_DIR="$SCRIPT_DIR/backups/update_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    docker exec "$CONTAINER_ID" test -d /app/plugins/sdr_ia && \
        docker cp "$CONTAINER_ID:/app/plugins/sdr_ia" "$BACKUP_DIR/" 2>/dev/null && \
        print_success "Backup criado em: $BACKUP_DIR"
fi

# Atualizar arquivos
print_header "5️⃣ ATUALIZANDO ARQUIVOS NO CONTAINER"

print_info "Atualizando plugin..."
docker cp "$SCRIPT_DIR/plugins/sdr_ia" "$CONTAINER_ID:/app/plugins/"
print_success "Plugin atualizado"

print_info "Atualizando controller..."
docker cp "$SCRIPT_DIR/controllers/api/v1/accounts/sdr_ia/settings_controller.rb" \
    "$CONTAINER_ID:/app/app/controllers/api/v1/accounts/sdr_ia/"
print_success "Controller atualizado"

print_info "Atualizando frontend..."
docker cp "$SCRIPT_DIR/frontend/routes/dashboard/settings/sdr-ia/Index.vue" \
    "$CONTAINER_ID:/app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia/"
docker cp "$SCRIPT_DIR/frontend/routes/dashboard/settings/sdr-ia/sdr-ia.routes.js" \
    "$CONTAINER_ID:/app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia/"
print_success "Frontend atualizado"

print_info "Atualizando initializer..."
docker cp "$SCRIPT_DIR/config_initializers_sdr_ia.rb" \
    "$CONTAINER_ID:/app/config/initializers/sdr_ia.rb"
print_success "Initializer atualizado"

# Reiniciar
if [ "$NO_RESTART" = false ]; then
    print_header "6️⃣ REINICIANDO SERVIÇOS"

    if docker stack ls 2>/dev/null | grep -q chatwoot; then
        print_info "Reiniciando via Docker Swarm..."
        docker service update --force chatwoot_chatwoot_app >/dev/null 2>&1
        docker service update --force chatwoot_chatwoot_sidekiq >/dev/null 2>&1 || true
    else
        print_info "Reiniciando via Docker..."
        docker restart "$CONTAINER_ID"
    fi

    print_success "Serviços reiniciados"
    print_info "Aguardando inicialização (15s)..."
    sleep 15
else
    print_warning "Reinicialização pulada (--no-restart)"
    print_warning "Lembre-se de reiniciar os serviços manualmente!"
fi

# Conclusão
print_header "✅ ATUALIZAÇÃO CONCLUÍDA!"

echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│                    RESUMO DA ATUALIZAÇÃO                        │"
echo "├─────────────────────────────────────────────────────────────────┤"
echo "│                                                                 │"
echo "│  ✅ Código atualizado: $CURRENT_COMMIT → $LATEST_COMMIT                │"
echo "│  ✅ Arquivos copiados para o container                          │"
echo "│  ✅ Serviços reiniciados                                         │"
echo "│                                                                 │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""

print_info "Ver mudanças detalhadas:"
print_info "git log $CURRENT_COMMIT..$LATEST_COMMIT"
echo ""

print_success "Atualização finalizada! 🎉"
echo ""

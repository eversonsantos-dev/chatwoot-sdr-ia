#!/bin/bash

# ============================================================================
# Chatwoot SDR IA Module - Script de Desinstalação
# ============================================================================
#
# Este script remove completamente o módulo SDR IA do Chatwoot.
#
# Uso: ./uninstall.sh [opções]
#
# Opções:
#   --container <id>       Especifica o ID/nome do container manualmente
#   --keep-data            Mantém custom attributes e labels
#   --force                Não pede confirmação
#   --help                 Mostra esta ajuda
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
KEEP_DATA=false
FORCE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --container) CONTAINER_ID="$2"; shift 2 ;;
        --keep-data) KEEP_DATA=true; shift ;;
        --force) FORCE=true; shift ;;
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
print_header "🗑️  DESINSTALADOR - SDR IA MODULE"

echo ""
print_warning "ATENÇÃO: Este script irá remover:"
echo "  • Arquivos do módulo SDR IA"
echo "  • Controller da API"
echo "  • Interface administrativa"
echo "  • Initializer"
echo "  • Modificações no menu e rotas"
if [ "$KEEP_DATA" = false ]; then
    echo "  • Custom Attributes (dados dos contatos)"
    echo "  • Labels"
fi
echo ""

if [ "$FORCE" = false ]; then
    read -p "Tem certeza que deseja continuar? (digite 'REMOVER' para confirmar) " -r
    echo
    if [ "$REPLY" != "REMOVER" ]; then
        print_warning "Desinstalação cancelada"
        exit 0
    fi
fi

# Detectar container
print_header "1️⃣ DETECTANDO CONTAINER CHATWOOT"

if [ -z "$CONTAINER_ID" ]; then
    CONTAINER_ID=$(docker ps --filter "name=chatwoot" --filter "name=app" --format "{{.Names}}" | head -1)
    if [ -z "$CONTAINER_ID" ]; then
        print_error "Container não encontrado!"
        exit 1
    fi
fi

print_success "Container: $CONTAINER_ID"

# Backup antes de remover
print_header "2️⃣ CRIANDO BACKUP FINAL"

BACKUP_DIR="$SCRIPT_DIR/backups/uninstall_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

print_info "Salvando backup em: $BACKUP_DIR"

docker exec "$CONTAINER_ID" test -d /app/plugins/sdr_ia && \
    docker cp "$CONTAINER_ID:/app/plugins/sdr_ia" "$BACKUP_DIR/" 2>/dev/null || true

docker exec "$CONTAINER_ID" test -f /app/config/initializers/sdr_ia.rb && \
    docker cp "$CONTAINER_ID:/app/config/initializers/sdr_ia.rb" "$BACKUP_DIR/" 2>/dev/null || true

print_success "Backup criado"

# Remover dados (custom attributes e labels)
if [ "$KEEP_DATA" = false ]; then
    print_header "3️⃣ REMOVENDO DADOS DO BANCO"

    print_warning "Removendo custom attributes..."
    docker exec "$CONTAINER_ID" bundle exec rails runner "
        account = Account.first
        deleted = account.custom_attribute_definitions.where('attribute_key LIKE ?', 'sdr_ia_%').destroy_all
        puts \"Custom attributes removidos: #{deleted.count}\"
    " 2>/dev/null | tail -1

    print_warning "Removendo labels..."
    docker exec "$CONTAINER_ID" bundle exec rails runner "
        account = Account.first
        deleted = account.labels.where('title LIKE ? OR title LIKE ? OR title LIKE ?',
                                       'temperatura-%', 'procedimento-%', 'urgencia-%').destroy_all
        puts \"Labels removidas: #{deleted.count}\"
    " 2>/dev/null | tail -1

    print_success "Dados removidos do banco"
else
    print_info "Dados mantidos no banco (--keep-data)"
fi

# Remover arquivos
print_header "4️⃣ REMOVENDO ARQUIVOS DO MÓDULO"

print_info "Removendo plugin..."
docker exec "$CONTAINER_ID" rm -rf /app/plugins/sdr_ia
print_success "Plugin removido"

print_info "Removendo controller..."
docker exec "$CONTAINER_ID" rm -rf /app/app/controllers/api/v1/accounts/sdr_ia
print_success "Controller removido"

print_info "Removendo frontend..."
docker exec "$CONTAINER_ID" rm -rf /app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia
print_success "Frontend removido"

print_info "Removendo initializer..."
docker exec "$CONTAINER_ID" rm -f /app/config/initializers/sdr_ia.rb
print_success "Initializer removido"

# Reverter modificações
print_header "5️⃣ REVERTENDO MODIFICAÇÕES NO CHATWOOT"

print_info "Removendo entrada do menu..."
docker exec "$CONTAINER_ID" sh -c "sed -i '/sdr_ia_settings/d' /app/app/javascript/dashboard/components/layout/config/sidebarItems/settings.js" || true
docker exec "$CONTAINER_ID" sh -c "sed -i '/SDR_IA/,/sdr_ia_settings/d' /app/app/javascript/dashboard/components/layout/config/sidebarItems/settings.js" || true
print_success "Menu limpo"

print_info "Removendo rotas..."
docker exec "$CONTAINER_ID" sh -c "sed -i '/sdr-ia/d' /app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js" || true
docker exec "$CONTAINER_ID" sh -c "sed -i '/sdrIa/d' /app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js" || true
print_success "Rotas limpas"

print_info "Removendo traduções..."
docker exec "$CONTAINER_ID" sh -c "sed -i '/SDR_IA/d' /app/app/javascript/dashboard/i18n/locale/pt_BR/settings.json" || true
docker exec "$CONTAINER_ID" sh -c "sed -i '/SDR_IA/d' /app/app/javascript/dashboard/i18n/locale/en/settings.json" || true
print_success "Traduções removidas"

# Reiniciar serviços
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

# Conclusão
print_header "✅ DESINSTALAÇÃO CONCLUÍDA!"

echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│                  RESUMO DA DESINSTALAÇÃO                        │"
echo "├─────────────────────────────────────────────────────────────────┤"
echo "│                                                                 │"
echo "│  ✅ Módulo SDR IA removido completamente                        │"
echo "│  ✅ Arquivos do sistema limpos                                   │"
echo "│  ✅ Configurações revertidas                                     │"

if [ "$KEEP_DATA" = false ]; then
    echo "│  ✅ Dados do banco removidos                                    │"
else
    echo "│  ⚠️  Dados do banco mantidos                                    │"
fi

echo "│                                                                 │"
echo "│  💾 Backup salvo em:                                            │"
echo "│     $BACKUP_DIR"
echo "│                                                                 │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""

print_info "Para reinstalar, execute: ./install.sh"
print_info "Para restaurar do backup: docker cp $BACKUP_DIR/sdr_ia $CONTAINER_ID:/app/plugins/"
echo ""

print_success "Desinstalação finalizada! 👋"
echo ""

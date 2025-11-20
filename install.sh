#!/bin/bash

# ============================================================================
# Chatwoot SDR IA Module - Script de Instalação Automatizado
# ============================================================================
#
# Este script automatiza a instalação completa do módulo SDR IA no Chatwoot.
#
# Uso: ./install.sh [opções]
#
# Opções:
#   --container <id>    Especifica o ID/nome do container manualmente
#   --skip-backup       Pula o backup (não recomendado)
#   --help              Mostra esta ajuda
#
# ============================================================================

set -e  # Para em qualquer erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de utilidade
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Variáveis
CONTAINER_ID=""
SKIP_BACKUP=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --container)
            CONTAINER_ID="$2"
            shift 2
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --help)
            grep '^#' "$0" | grep -v '#!/bin/bash' | sed 's/^# //'
            exit 0
            ;;
        *)
            print_error "Opção desconhecida: $1"
            echo "Use --help para ver opções disponíveis"
            exit 1
            ;;
    esac
done

# Banner
clear
print_header "🚀 INSTALADOR AUTOMÁTICO - SDR IA MODULE"

echo "Este script irá:"
echo "  1. Detectar seu container Chatwoot"
echo "  2. Fazer backup dos arquivos existentes"
echo "  3. Instalar o módulo SDR IA"
echo "  4. Configurar custom attributes e labels"
echo "  5. Atualizar arquivos de configuração"
echo "  6. Reiniciar serviços"
echo "  7. Testar a instalação"
echo ""

# Detectar container
print_header "1️⃣ DETECTANDO CONTAINER CHATWOOT"

if [ -z "$CONTAINER_ID" ]; then
    print_info "Procurando container do Chatwoot..."
    CONTAINER_ID=$(docker ps --filter "name=chatwoot" --filter "name=app" --format "{{.Names}}" | head -1)

    if [ -z "$CONTAINER_ID" ]; then
        print_error "Nenhum container do Chatwoot encontrado!"
        print_info "Containers disponíveis:"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
        echo ""
        echo "Use: ./install.sh --container <nome_do_container>"
        exit 1
    fi
fi

# Verificar se container existe e está rodando
if ! docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_ID}$"; then
    print_error "Container '$CONTAINER_ID' não encontrado ou não está rodando!"
    exit 1
fi

print_success "Container encontrado: $CONTAINER_ID"

# Verificar versão do Chatwoot
print_info "Verificando versão do Chatwoot..."
CHATWOOT_VERSION=$(docker exec "$CONTAINER_ID" cat /app/app/views/layouts/application.html.erb 2>/dev/null | grep -oP 'chatwoot.*?v\K[0-9.]+' | head -1 || echo "desconhecida")
print_info "Versão detectada: $CHATWOOT_VERSION"

# Backup
if [ "$SKIP_BACKUP" = false ]; then
    print_header "2️⃣ CRIANDO BACKUP"

    BACKUP_DIR="$SCRIPT_DIR/backups/backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    print_info "Backup será salvo em: $BACKUP_DIR"

    # Backup de arquivos que serão modificados (se existirem)
    docker exec "$CONTAINER_ID" test -d /app/plugins/sdr_ia && \
        docker cp "$CONTAINER_ID:/app/plugins/sdr_ia" "$BACKUP_DIR/" 2>/dev/null && \
        print_success "Backup do plugin existente criado" || true

    docker exec "$CONTAINER_ID" test -f /app/config/initializers/sdr_ia.rb && \
        docker cp "$CONTAINER_ID:/app/config/initializers/sdr_ia.rb" "$BACKUP_DIR/" 2>/dev/null && \
        print_success "Backup do initializer criado" || true

    print_success "Backup concluído!"
else
    print_warning "Backup foi pulado (--skip-backup)"
fi

# Instalação dos arquivos
print_header "3️⃣ INSTALANDO MÓDULO SDR IA"

print_info "Copiando arquivos do plugin..."
docker cp "$SCRIPT_DIR/plugins/sdr_ia" "$CONTAINER_ID:/app/plugins/" || {
    print_error "Falha ao copiar plugin!"
    exit 1
}
print_success "Plugin copiado"

print_info "Copiando controller da API..."
docker exec "$CONTAINER_ID" mkdir -p /app/app/controllers/api/v1/accounts/sdr_ia
docker cp "$SCRIPT_DIR/controllers/api/v1/accounts/sdr_ia/settings_controller.rb" \
    "$CONTAINER_ID:/app/app/controllers/api/v1/accounts/sdr_ia/" || {
    print_error "Falha ao copiar controller!"
    exit 1
}
print_success "Controller copiado"

print_info "Copiando frontend Vue.js..."
docker exec "$CONTAINER_ID" mkdir -p /app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia
docker cp "$SCRIPT_DIR/frontend/routes/dashboard/settings/sdr-ia/Index.vue" \
    "$CONTAINER_ID:/app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia/" || {
    print_error "Falha ao copiar frontend!"
    exit 1
}
docker cp "$SCRIPT_DIR/frontend/routes/dashboard/settings/sdr-ia/sdr-ia.routes.js" \
    "$CONTAINER_ID:/app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia/" || {
    print_error "Falha ao copiar rotas do frontend!"
    exit 1
}
print_success "Frontend copiado"

print_info "Copiando initializer..."
docker cp "$SCRIPT_DIR/config_initializers_sdr_ia.rb" \
    "$CONTAINER_ID:/app/config/initializers/sdr_ia.rb" || {
    print_error "Falha ao copiar initializer!"
    exit 1
}
print_success "Initializer copiado"

# Atualizar arquivos de configuração do Chatwoot
print_header "4️⃣ ATUALIZANDO CONFIGURAÇÕES DO CHATWOOT"

print_info "Atualizando settings routes..."
docker exec "$CONTAINER_ID" sh -c 'grep -q "sdr-ia" /app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js 2>/dev/null' || {
    docker exec "$CONTAINER_ID" sh -c "sed -i \"/import profile from/a import sdrIa from './sdr-ia/sdr-ia.routes';\" /app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js"
    docker exec "$CONTAINER_ID" sh -c "sed -i '/...profile.routes,/a\    ...sdrIa.routes,' /app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js"
    print_success "Routes atualizadas"
}

print_info "Atualizando sidebar menu..."
docker exec "$CONTAINER_ID" sh -c 'grep -q "sdr_ia_settings" /app/app/javascript/dashboard/components/layout/config/sidebarItems/settings.js 2>/dev/null' || {
    docker exec "$CONTAINER_ID" sh -c "sed -i \"/    'custom_roles_list',/a\    'sdr_ia_settings',' /app/app/javascript/dashboard/components/layout/config/sidebarItems/settings.js"
    docker exec "$CONTAINER_ID" sh -c "sed -i \"/icon: 'bot',/,/featureFlag.*AGENT_BOTS/a\    {\n      icon: 'sparkles',\n      label: 'SDR_IA',\n      hasSubMenu: false,\n      meta: {\n        permissions: ['administrator'],\n      },\n      toState: frontendURL(\\\`accounts/\\\${accountId}/settings/sdr-ia\\\`),\n      toStateName: 'sdr_ia_settings',\n    }," /app/app/javascript/dashboard/components/layout/config/sidebarItems/settings.js"
    print_success "Sidebar atualizada"
}

print_info "Adicionando traduções PT-BR..."
docker exec "$CONTAINER_ID" sh -c 'grep -q "SDR_IA" /app/app/javascript/dashboard/i18n/locale/pt_BR/settings.json 2>/dev/null' || {
    docker exec "$CONTAINER_ID" sh -c "sed -i '/\"AGENT_BOTS\":/a\    \"SDR_IA\": \"SDR IA\",' /app/app/javascript/dashboard/i18n/locale/pt_BR/settings.json"
    print_success "Tradução PT-BR adicionada"
}

print_info "Adicionando traduções EN..."
docker exec "$CONTAINER_ID" sh -c 'grep -q "SDR_IA" /app/app/javascript/dashboard/i18n/locale/en/settings.json 2>/dev/null' || {
    docker exec "$CONTAINER_ID" sh -c "sed -i '/\"AGENT_BOTS\":/a\    \"SDR_IA\": \"SDR AI\",' /app/app/javascript/dashboard/i18n/locale/en/settings.json"
    print_success "Tradução EN adicionada"
}

# Executar script de instalação (custom attributes e labels)
print_header "5️⃣ CRIANDO CUSTOM ATTRIBUTES E LABELS"

print_info "Executando install.rb..."
docker exec "$CONTAINER_ID" bundle exec rails runner /app/plugins/sdr_ia/install.rb || {
    print_error "Falha ao executar install.rb!"
    print_warning "Você pode executar manualmente depois:"
    print_warning "docker exec $CONTAINER_ID bundle exec rails runner /app/plugins/sdr_ia/install.rb"
}

# Reiniciar serviços
print_header "6️⃣ REINICIANDO SERVIÇOS"

print_info "Detectando tipo de deploy (Docker Swarm ou Docker Compose)..."

if docker stack ls 2>/dev/null | grep -q chatwoot; then
    print_info "Docker Swarm detectado"
    print_info "Reiniciando chatwoot_app..."
    docker service update --force chatwoot_chatwoot_app >/dev/null 2>&1 || {
        print_warning "Falha ao reiniciar via Swarm, tentando método alternativo..."
        docker restart "$CONTAINER_ID" || print_error "Falha ao reiniciar container!"
    }
    print_success "Serviço reiniciado"

    print_info "Reiniciando chatwoot_sidekiq..."
    docker service update --force chatwoot_chatwoot_sidekiq >/dev/null 2>&1 || {
        print_warning "Não foi possível reiniciar sidekiq automaticamente"
    }
else
    print_info "Docker Compose detectado"
    print_info "Reiniciando container..."
    docker restart "$CONTAINER_ID" || {
        print_error "Falha ao reiniciar container!"
        exit 1
    }
    print_success "Container reiniciado"
fi

# Aguardar container ficar pronto
print_info "Aguardando container inicializar (30s)..."
sleep 30

# Testes
print_header "7️⃣ TESTANDO INSTALAÇÃO"

print_info "Verificando se módulo foi carregado..."
if docker exec "$CONTAINER_ID" test -f /app/plugins/sdr_ia/lib/sdr_ia.rb; then
    print_success "Arquivos do módulo presentes"
else
    print_error "Arquivos do módulo não encontrados!"
    exit 1
fi

print_info "Verificando custom attributes..."
ATTR_COUNT=$(docker exec "$CONTAINER_ID" bundle exec rails runner "puts Account.first.custom_attribute_definitions.where('attribute_key LIKE ?', 'sdr_ia_%').count" 2>/dev/null | tail -1)
if [ "$ATTR_COUNT" -ge 10 ]; then
    print_success "$ATTR_COUNT custom attributes criados"
else
    print_warning "Apenas $ATTR_COUNT custom attributes encontrados (esperado: 16)"
fi

print_info "Verificando labels..."
LABEL_COUNT=$(docker exec "$CONTAINER_ID" bundle exec rails runner "puts Account.first.labels.where('title LIKE ? OR title LIKE ? OR title LIKE ?', 'temperatura-%', 'procedimento-%', 'urgencia-%').count" 2>/dev/null | tail -1)
if [ "$LABEL_COUNT" -ge 10 ]; then
    print_success "$LABEL_COUNT labels criadas"
else
    print_warning "Apenas $LABEL_COUNT labels encontradas (esperado: 14)"
fi

# Relatório Final
print_header "✅ INSTALAÇÃO CONCLUÍDA!"

echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│                    RESUMO DA INSTALAÇÃO                         │"
echo "├─────────────────────────────────────────────────────────────────┤"
echo "│                                                                 │"
echo "│  ✅ Módulo SDR IA instalado com sucesso!                        │"
echo "│  ✅ Custom Attributes: $ATTR_COUNT criados                                  │"
echo "│  ✅ Labels: $LABEL_COUNT criadas                                           │"
echo "│  ✅ Interface administrativa disponível                         │"
echo "│  ✅ API Controller configurada                                  │"
echo "│                                                                 │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""

print_warning "PRÓXIMOS PASSOS IMPORTANTES:"
echo ""
echo "1. Configure a OpenAI API Key:"
echo "   Edite seu chatwoot.yaml e adicione:"
echo "   environment:"
echo "     - OPENAI_API_KEY=sk-proj-SUA_CHAVE_AQUI"
echo ""
echo "2. Redeploy o stack:"
echo "   docker stack deploy -c chatwoot.yaml chatwoot"
echo ""
echo "3. Acesse a interface:"
echo "   Chatwoot → Configurações → SDR IA"
echo ""
echo "4. Execute o teste (opcional):"
echo "   bash $SCRIPT_DIR/docs/testar_sdr_ia.sh"
echo ""

if [ "$SKIP_BACKUP" = false ]; then
    print_info "Backup salvo em: $BACKUP_DIR"
fi

print_success "Instalação finalizada! 🎉"
echo ""

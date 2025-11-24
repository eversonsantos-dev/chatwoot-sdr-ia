#!/bin/bash

# ============================================================================
# CHATWOOT SDR IA - INSTALADOR INTELIGENTE v3.0
# ============================================================================
#
# Este script detecta automaticamente o ambiente e instala o plugin SDR IA
# de forma adequada para cada cenário.
#
# CENÁRIOS SUPORTADOS:
#   - Docker Swarm (via Portainer ou CLI)
#   - Docker Compose
#   - Container standalone
#   - Instalação local (sem Docker)
#
# USO:
#   ./install-smart.sh                    # Interativo
#   ./install-smart.sh --auto             # Automático (detecta tudo)
#   ./install-smart.sh --api-key=sk-xxx   # Com API key
#   ./install-smart.sh --help             # Ajuda
#
# ============================================================================

set -e

VERSION="3.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Variáveis globais
INSTALL_MODE=""           # swarm, compose, standalone, local
CONTAINER_NAME=""
CONTAINER_ID=""
CHATWOOT_PATH=""
OPENAI_API_KEY=""
AUTO_MODE=false
SKIP_BACKUP=false
REBUILD_IMAGE=false
IMAGE_NAME=""
STACK_NAME=""

# ============================================================================
# FUNÇÕES DE OUTPUT
# ============================================================================

banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                    ║"
    echo "║     ██████╗██████╗ ██████╗     ██╗ █████╗                         ║"
    echo "║    ██╔════╝██╔══██╗██╔══██╗    ██║██╔══██╗                        ║"
    echo "║    ╚█████╗ ██║  ██║██████╔╝    ██║███████║                        ║"
    echo "║     ╚═══██╗██║  ██║██╔══██╗    ██║██╔══██║                        ║"
    echo "║    ██████╔╝██████╔╝██║  ██║    ██║██║  ██║                        ║"
    echo "║    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝    ╚═╝╚═╝  ╚═╝                        ║"
    echo "║                                                                    ║"
    echo "║              INSTALADOR INTELIGENTE v${VERSION}                       ║"
    echo "║                                                                    ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_step() { echo -e "\n${BOLD}${CYAN}━━━ $1 ━━━${NC}\n"; }

# ============================================================================
# FUNÇÕES DE DETECÇÃO
# ============================================================================

detect_environment() {
    log_step "DETECTANDO AMBIENTE"

    # Verificar se Docker está instalado
    if ! command -v docker &> /dev/null; then
        log_info "Docker não encontrado, verificando instalação local..."
        detect_local_install
        return
    fi

    # Verificar se é Docker Swarm
    if docker info 2>/dev/null | grep -q "Swarm: active"; then
        log_info "Docker Swarm detectado"
        detect_swarm_chatwoot
        return
    fi

    # Verificar Docker Compose ou standalone
    detect_docker_chatwoot
}

detect_swarm_chatwoot() {
    log_info "Buscando serviços Chatwoot no Swarm..."

    # Buscar stack do Chatwoot
    local stacks=$(docker stack ls --format "{{.Name}}" 2>/dev/null)

    for stack in $stacks; do
        local services=$(docker stack services "$stack" --format "{{.Name}}" 2>/dev/null)
        if echo "$services" | grep -qi "chatwoot"; then
            STACK_NAME="$stack"
            log_success "Stack encontrada: $STACK_NAME"
            break
        fi
    done

    if [ -z "$STACK_NAME" ]; then
        log_warning "Nenhuma stack Chatwoot encontrada no Swarm"
        detect_docker_chatwoot
        return
    fi

    # Buscar container app
    CONTAINER_NAME=$(docker ps --filter "name=${STACK_NAME}" --filter "name=app" --format "{{.Names}}" | head -1)

    if [ -z "$CONTAINER_NAME" ]; then
        CONTAINER_NAME=$(docker ps --filter "name=chatwoot" --filter "name=app" --format "{{.Names}}" | head -1)
    fi

    if [ -n "$CONTAINER_NAME" ]; then
        CONTAINER_ID=$(docker ps -q --filter "name=$CONTAINER_NAME" | head -1)
        IMAGE_NAME=$(docker inspect --format='{{.Config.Image}}' "$CONTAINER_ID" 2>/dev/null)
        INSTALL_MODE="swarm"
        log_success "Container: $CONTAINER_NAME"
        log_success "Imagem: $IMAGE_NAME"
        log_success "Modo: Docker Swarm"
    fi
}

detect_docker_chatwoot() {
    log_info "Buscando containers Chatwoot..."

    # Buscar container chatwoot (vários padrões)
    local patterns=("chatwoot" "cwoot" "chatwoot_app" "chatwoot-app" "rails" "sidekiq")

    for pattern in "${patterns[@]}"; do
        CONTAINER_NAME=$(docker ps --format "{{.Names}}" 2>/dev/null | grep -i "$pattern" | grep -vi "redis\|postgres\|sidekiq" | head -1)
        if [ -n "$CONTAINER_NAME" ]; then
            break
        fi
    done

    # Se não encontrou app, tenta sidekiq (mesmo código)
    if [ -z "$CONTAINER_NAME" ]; then
        CONTAINER_NAME=$(docker ps --format "{{.Names}}" 2>/dev/null | grep -i "chatwoot" | head -1)
    fi

    if [ -z "$CONTAINER_NAME" ]; then
        log_warning "Nenhum container Chatwoot encontrado"
        detect_local_install
        return
    fi

    CONTAINER_ID=$(docker ps -q --filter "name=$CONTAINER_NAME" | head -1)
    IMAGE_NAME=$(docker inspect --format='{{.Config.Image}}' "$CONTAINER_ID" 2>/dev/null)

    # Verificar se é compose
    local compose_project=$(docker inspect --format='{{index .Config.Labels "com.docker.compose.project"}}' "$CONTAINER_ID" 2>/dev/null)

    if [ -n "$compose_project" ] && [ "$compose_project" != "<no value>" ]; then
        INSTALL_MODE="compose"
        log_success "Docker Compose detectado (projeto: $compose_project)"
    else
        INSTALL_MODE="standalone"
        log_success "Container standalone detectado"
    fi

    log_success "Container: $CONTAINER_NAME"
    log_success "Imagem: $IMAGE_NAME"
}

detect_local_install() {
    log_info "Buscando instalação local do Chatwoot..."

    # Caminhos comuns
    local paths=(
        "/root/chatwoot"
        "/home/chatwoot"
        "/home/chatwoot/chatwoot"
        "/var/www/chatwoot"
        "/opt/chatwoot"
        "/srv/chatwoot"
    )

    for path in "${paths[@]}"; do
        if [ -f "$path/Gemfile" ] && [ -d "$path/app" ]; then
            CHATWOOT_PATH="$path"
            INSTALL_MODE="local"
            log_success "Chatwoot encontrado: $CHATWOOT_PATH"
            return
        fi
    done

    log_error "Chatwoot não encontrado automaticamente"
    INSTALL_MODE="manual"
}

# ============================================================================
# FUNÇÕES DE INSTALAÇÃO
# ============================================================================

verify_plugin_files() {
    log_step "VERIFICANDO ARQUIVOS DO PLUGIN"

    local required_dirs=("plugins/sdr_ia" "db/migrate")
    local missing=false

    for dir in "${required_dirs[@]}"; do
        if [ -d "$SCRIPT_DIR/$dir" ]; then
            log_success "Encontrado: $dir"
        else
            log_error "Faltando: $dir"
            missing=true
        fi
    done

    if [ "$missing" = true ]; then
        log_error "Arquivos do plugin incompletos!"
        log_info "Certifique-se de executar este script do diretório raiz do chatwoot-sdr-ia"
        exit 1
    fi
}

get_openai_key() {
    log_step "CONFIGURAÇÃO OPENAI"

    if [ -n "$OPENAI_API_KEY" ]; then
        log_success "API Key fornecida via parâmetro"
        return
    fi

    # Verificar se já existe no container/sistema
    if [ "$INSTALL_MODE" != "local" ] && [ -n "$CONTAINER_ID" ]; then
        local existing_key=$(docker exec "$CONTAINER_ID" printenv OPENAI_API_KEY 2>/dev/null || true)
        if [ -n "$existing_key" ] && [ "$existing_key" != "" ]; then
            log_success "API Key já configurada no container"
            OPENAI_API_KEY="$existing_key"
            return
        fi
    fi

    if [ "$AUTO_MODE" = true ]; then
        log_error "Modo automático requer --api-key=xxx ou API Key já configurada"
        exit 1
    fi

    echo ""
    echo -e "${YELLOW}O SDR IA precisa de uma API Key da OpenAI para funcionar.${NC}"
    echo ""
    echo "Obtenha sua chave em: https://platform.openai.com/api-keys"
    echo ""
    read -p "Digite sua API Key da OpenAI (sk-...): " OPENAI_API_KEY

    if [ -z "$OPENAI_API_KEY" ]; then
        log_error "API Key é obrigatória"
        exit 1
    fi

    # Validar formato básico
    if [[ ! "$OPENAI_API_KEY" =~ ^sk- ]]; then
        log_warning "API Key não parece válida (deve começar com 'sk-')"
        read -p "Continuar mesmo assim? (s/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
            exit 1
        fi
    fi
}

create_backup() {
    if [ "$SKIP_BACKUP" = true ]; then
        log_warning "Backup pulado (--skip-backup)"
        return
    fi

    log_step "CRIANDO BACKUP"

    local backup_dir="$SCRIPT_DIR/backups/install_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    if [ "$INSTALL_MODE" != "local" ] && [ -n "$CONTAINER_ID" ]; then
        # Backup do container
        docker exec "$CONTAINER_ID" test -d /app/plugins/sdr_ia && \
            docker cp "$CONTAINER_ID:/app/plugins/sdr_ia" "$backup_dir/" 2>/dev/null || true

        docker exec "$CONTAINER_ID" test -f /app/config/initializers/sdr_ia.rb && \
            docker cp "$CONTAINER_ID:/app/config/initializers/sdr_ia.rb" "$backup_dir/" 2>/dev/null || true
    elif [ -n "$CHATWOOT_PATH" ]; then
        # Backup local
        [ -d "$CHATWOOT_PATH/plugins/sdr_ia" ] && \
            cp -r "$CHATWOOT_PATH/plugins/sdr_ia" "$backup_dir/" 2>/dev/null || true
    fi

    log_success "Backup criado: $backup_dir"
}

install_to_container() {
    log_step "INSTALANDO NO CONTAINER"

    if [ -z "$CONTAINER_ID" ]; then
        log_error "Container não identificado"
        exit 1
    fi

    # 1. Criar diretório do plugin
    log_info "Criando diretório do plugin..."
    docker exec "$CONTAINER_ID" mkdir -p /app/plugins

    # 2. Copiar plugin
    log_info "Copiando plugin SDR IA..."
    docker cp "$SCRIPT_DIR/plugins/sdr_ia" "$CONTAINER_ID:/app/plugins/"
    log_success "Plugin copiado"

    # 3. Copiar migrations
    log_info "Copiando migrations..."
    for migration in "$SCRIPT_DIR"/db/migrate/*.rb; do
        if [ -f "$migration" ]; then
            docker cp "$migration" "$CONTAINER_ID:/app/db/migrate/"
        fi
    done
    log_success "Migrations copiadas"

    # 4. Copiar initializer
    log_info "Configurando initializer..."
    docker cp "$SCRIPT_DIR/config_initializers_sdr_ia.rb" "$CONTAINER_ID:/app/config/initializers/sdr_ia.rb"
    log_success "Initializer configurado"

    # 5. Copiar controller
    log_info "Instalando controller API..."
    docker exec "$CONTAINER_ID" mkdir -p /app/app/controllers/api/v1/accounts/sdr_ia
    docker cp "$SCRIPT_DIR/controllers/api/v1/accounts/sdr_ia/settings_controller.rb" \
        "$CONTAINER_ID:/app/app/controllers/api/v1/accounts/sdr_ia/"
    log_success "Controller instalado"

    # 6. Configurar API Key
    if [ -n "$OPENAI_API_KEY" ]; then
        log_info "Verificando variável OPENAI_API_KEY..."
        # A variável precisa estar no environment do container/service
        log_warning "IMPORTANTE: Adicione OPENAI_API_KEY ao seu docker-compose.yml ou stack"
    fi
}

run_migrations() {
    log_step "EXECUTANDO MIGRATIONS"

    if [ "$INSTALL_MODE" = "local" ]; then
        cd "$CHATWOOT_PATH"
        RAILS_ENV=production bundle exec rails db:migrate
    else
        log_info "Executando migrations no container..."
        docker exec "$CONTAINER_ID" bundle exec rails db:migrate RAILS_ENV=production 2>&1 || {
            log_warning "Migrations podem já estar aplicadas ou houve erro não crítico"
        }
    fi

    log_success "Migrations processadas"
}

restart_services_swarm() {
    log_step "REINICIANDO SERVIÇOS (SWARM)"

    log_info "Atualizando serviço app..."
    docker service update --force "${STACK_NAME}_chatwoot_app" 2>/dev/null || \
    docker service update --force "chatwoot_chatwoot_app" 2>/dev/null || {
        log_warning "Não foi possível atualizar automaticamente"
        log_info "Execute manualmente: docker service update --force <nome_do_servico>"
    }

    log_info "Atualizando serviço sidekiq..."
    docker service update --force "${STACK_NAME}_chatwoot_sidekiq" 2>/dev/null || \
    docker service update --force "chatwoot_chatwoot_sidekiq" 2>/dev/null || true

    log_success "Serviços atualizados"
    log_info "Aguardando reinicialização (30s)..."
    sleep 30
}

restart_services_compose() {
    log_step "REINICIANDO SERVIÇOS (COMPOSE)"

    # Tentar encontrar docker-compose.yml
    local compose_file=""
    local search_paths=(
        "/root"
        "/home"
        "/opt"
        "/srv"
    )

    for path in "${search_paths[@]}"; do
        local found=$(find "$path" -maxdepth 3 -name "docker-compose*.yml" -exec grep -l "chatwoot" {} \; 2>/dev/null | head -1)
        if [ -n "$found" ]; then
            compose_file="$found"
            break
        fi
    done

    if [ -n "$compose_file" ]; then
        local compose_dir=$(dirname "$compose_file")
        log_info "Reiniciando via docker-compose em $compose_dir..."
        cd "$compose_dir"
        docker-compose restart 2>/dev/null || docker compose restart 2>/dev/null || {
            log_warning "Falha ao reiniciar via compose"
            docker restart "$CONTAINER_ID"
        }
    else
        log_info "Reiniciando container diretamente..."
        docker restart "$CONTAINER_ID"
    fi

    log_success "Serviços reiniciados"
}

restart_services_standalone() {
    log_step "REINICIANDO CONTAINER"

    docker restart "$CONTAINER_ID"
    log_success "Container reiniciado"
    log_info "Aguardando inicialização (20s)..."
    sleep 20
}

restart_services_local() {
    log_step "REINICIANDO SERVIÇOS LOCAIS"

    systemctl restart chatwoot.target 2>/dev/null || \
    systemctl restart chatwoot 2>/dev/null || \
    service chatwoot restart 2>/dev/null || {
        log_warning "Não foi possível reiniciar automaticamente"
        log_info "Execute: sudo systemctl restart chatwoot"
    }
}

# ============================================================================
# MENU INTERATIVO
# ============================================================================

show_detected_info() {
    echo ""
    echo -e "${BOLD}Ambiente Detectado:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    case $INSTALL_MODE in
        swarm)
            echo -e "  Tipo:      ${GREEN}Docker Swarm${NC}"
            echo -e "  Stack:     ${CYAN}$STACK_NAME${NC}"
            echo -e "  Container: ${CYAN}$CONTAINER_NAME${NC}"
            echo -e "  Imagem:    ${CYAN}$IMAGE_NAME${NC}"
            ;;
        compose)
            echo -e "  Tipo:      ${GREEN}Docker Compose${NC}"
            echo -e "  Container: ${CYAN}$CONTAINER_NAME${NC}"
            echo -e "  Imagem:    ${CYAN}$IMAGE_NAME${NC}"
            ;;
        standalone)
            echo -e "  Tipo:      ${GREEN}Container Standalone${NC}"
            echo -e "  Container: ${CYAN}$CONTAINER_NAME${NC}"
            echo -e "  Imagem:    ${CYAN}$IMAGE_NAME${NC}"
            ;;
        local)
            echo -e "  Tipo:      ${GREEN}Instalação Local${NC}"
            echo -e "  Caminho:   ${CYAN}$CHATWOOT_PATH${NC}"
            ;;
        manual)
            echo -e "  Tipo:      ${YELLOW}Não detectado automaticamente${NC}"
            ;;
    esac
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

ask_confirmation() {
    if [ "$AUTO_MODE" = true ]; then
        return 0
    fi

    show_detected_info

    echo -e "${YELLOW}A instalação irá:${NC}"
    echo "  1. Criar backup dos arquivos atuais"
    echo "  2. Copiar plugin SDR IA para o Chatwoot"
    echo "  3. Executar migrations do banco de dados"
    echo "  4. Reiniciar os serviços"
    echo ""

    read -p "Deseja continuar? (S/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_warning "Instalação cancelada"
        exit 0
    fi
}

manual_container_selection() {
    echo ""
    log_warning "Não foi possível detectar o Chatwoot automaticamente."
    echo ""
    echo "Containers Docker disponíveis:"
    echo ""
    docker ps --format "  {{.Names}}" 2>/dev/null | head -20
    echo ""
    read -p "Digite o nome do container do Chatwoot: " CONTAINER_NAME

    if [ -z "$CONTAINER_NAME" ]; then
        log_error "Nome do container é obrigatório"
        exit 1
    fi

    CONTAINER_ID=$(docker ps -q --filter "name=$CONTAINER_NAME" 2>/dev/null | head -1)

    if [ -z "$CONTAINER_ID" ]; then
        log_error "Container não encontrado: $CONTAINER_NAME"
        exit 1
    fi

    IMAGE_NAME=$(docker inspect --format='{{.Config.Image}}' "$CONTAINER_ID" 2>/dev/null)
    INSTALL_MODE="standalone"

    log_success "Container selecionado: $CONTAINER_NAME"
}

# ============================================================================
# MAIN
# ============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto)
                AUTO_MODE=true
                shift
                ;;
            --api-key=*)
                OPENAI_API_KEY="${1#*=}"
                shift
                ;;
            --container=*)
                CONTAINER_NAME="${1#*=}"
                shift
                ;;
            --skip-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --rebuild)
                REBUILD_IMAGE=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    echo "Uso: $0 [opções]"
    echo ""
    echo "Opções:"
    echo "  --auto              Modo automático (sem interação)"
    echo "  --api-key=KEY       API Key da OpenAI"
    echo "  --container=NAME    Nome do container (se não detectar)"
    echo "  --skip-backup       Não criar backup"
    echo "  --rebuild           Rebuild da imagem Docker (Swarm)"
    echo "  --help, -h          Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0                              # Interativo"
    echo "  $0 --auto --api-key=sk-xxx     # Automático com API key"
    echo "  $0 --container=chatwoot_app    # Especificar container"
}

show_final_instructions() {
    log_step "INSTALAÇÃO CONCLUÍDA!"

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    SDR IA INSTALADO COM SUCESSO!                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${BOLD}Próximos Passos:${NC}"
    echo ""
    echo "1. ${YELLOW}Verificar OPENAI_API_KEY${NC}"

    if [ "$INSTALL_MODE" = "swarm" ]; then
        echo "   Adicione no seu stack YAML:"
        echo -e "   ${CYAN}environment:${NC}"
        echo -e "   ${CYAN}  - OPENAI_API_KEY=$OPENAI_API_KEY${NC}"
        echo ""
        echo "   E faça redeploy:"
        echo -e "   ${CYAN}docker stack deploy -c <seu-arquivo.yaml> chatwoot${NC}"
    elif [ "$INSTALL_MODE" = "compose" ]; then
        echo "   Adicione no docker-compose.yml:"
        echo -e "   ${CYAN}environment:${NC}"
        echo -e "   ${CYAN}  - OPENAI_API_KEY=$OPENAI_API_KEY${NC}"
    fi

    echo ""
    echo "2. ${YELLOW}Configurar no Chatwoot${NC}"
    echo "   - Acesse: Settings → Inboxes → [Seu Inbox]"
    echo "   - Ative o SDR IA e configure os parâmetros"
    echo ""
    echo "3. ${YELLOW}Testar${NC}"
    echo "   - Envie uma mensagem de teste"
    echo "   - Verifique os logs: docker logs -f $CONTAINER_NAME | grep SDR"
    echo ""

    log_success "Instalação finalizada!"
}

main() {
    banner
    parse_args "$@"

    verify_plugin_files
    detect_environment

    # Se não detectou, pedir manualmente
    if [ "$INSTALL_MODE" = "manual" ]; then
        if [ "$AUTO_MODE" = true ]; then
            log_error "Modo automático falhou: Chatwoot não detectado"
            exit 1
        fi
        manual_container_selection
    fi

    get_openai_key
    ask_confirmation
    create_backup

    # Instalar baseado no modo
    case $INSTALL_MODE in
        swarm|compose|standalone)
            install_to_container
            run_migrations

            case $INSTALL_MODE in
                swarm)      restart_services_swarm ;;
                compose)    restart_services_compose ;;
                standalone) restart_services_standalone ;;
            esac
            ;;
        local)
            # Instalação local (código original)
            log_info "Copiando arquivos para $CHATWOOT_PATH..."
            mkdir -p "$CHATWOOT_PATH/plugins"
            cp -r "$SCRIPT_DIR/plugins/sdr_ia" "$CHATWOOT_PATH/plugins/"
            cp -r "$SCRIPT_DIR"/db/migrate/* "$CHATWOOT_PATH/db/migrate/"

            run_migrations
            restart_services_local
            ;;
    esac

    show_final_instructions
}

# Executar
main "$@"

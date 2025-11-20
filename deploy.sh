#!/bin/bash
# Chatwoot SDR IA - Deploy Script para Docker Swarm
# Este script automatiza o deploy da imagem customizada no Swarm

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configurações
IMAGE_NAME="${IMAGE_NAME:-localhost/chatwoot-sdr-ia:latest}"
STACK_NAME="${STACK_NAME:-chatwoot}"
SERVICE_APP="${SERVICE_APP:-chatwoot_chatwoot_app}"
SERVICE_SIDEKIQ="${SERVICE_SIDEKIQ:-chatwoot_chatwoot_sidekiq}"

# Banner
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════╗"
echo "║      Chatwoot SDR IA - Deploy to Swarm Tool       ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se a imagem existe
log_info "Verificando se a imagem existe..."
if ! docker image inspect $IMAGE_NAME > /dev/null 2>&1; then
    log_error "Imagem $IMAGE_NAME não encontrada!"
    log_warn "Execute ./rebuild.sh primeiro"
    exit 1
fi

log_info "Imagem encontrada: $IMAGE_NAME"
echo ""

# Mostrar configurações
log_info "Configurações de Deploy:"
echo "  Image: $IMAGE_NAME"
echo "  Stack: $STACK_NAME"
echo "  Service App: $SERVICE_APP"
echo "  Service Sidekiq: $SERVICE_SIDEKIQ"
echo ""

# Confirmar
read -p "Deseja fazer o deploy agora? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log_warn "Deploy cancelado pelo usuário"
    exit 0
fi

# Backup da configuração atual
log_info "Fazendo backup da configuração atual..."
BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).txt"
docker service inspect $SERVICE_APP > "/tmp/$BACKUP_FILE" 2>/dev/null || true
log_info "Backup salvo em /tmp/$BACKUP_FILE"

# Atualizar serviço app
log_info "Atualizando serviço $SERVICE_APP..."
docker service update \
    --image $IMAGE_NAME \
    --update-parallelism 1 \
    --update-delay 10s \
    $SERVICE_APP

if [ $? -eq 0 ]; then
    log_info "✅ Serviço app atualizado com sucesso!"
else
    log_error "❌ Falha ao atualizar serviço app"
    exit 1
fi

# Atualizar serviço sidekiq
log_info "Atualizando serviço $SERVICE_SIDEKIQ..."
docker service update \
    --image $IMAGE_NAME \
    --update-parallelism 1 \
    --update-delay 10s \
    $SERVICE_SIDEKIQ

if [ $? -eq 0 ]; then
    log_info "✅ Serviço sidekiq atualizado com sucesso!"
else
    log_error "❌ Falha ao atualizar serviço sidekiq"
    exit 1
fi

# Aguardar convergência
echo ""
log_info "Aguardando convergência dos serviços..."
sleep 10

# Verificar status
log_info "Verificando status dos serviços..."
APP_STATUS=$(docker service ps $SERVICE_APP --filter "desired-state=running" --format "{{.CurrentState}}" | head -1)
SIDEKIQ_STATUS=$(docker service ps $SERVICE_SIDEKIQ --filter "desired-state=running" --format "{{.CurrentState}}" | head -1)

echo ""
log_info "Status dos serviços:"
echo "  App: $APP_STATUS"
echo "  Sidekiq: $SIDEKIQ_STATUS"

# Verificar se SDR IA está carregado
echo ""
log_info "Verificando se o módulo SDR IA foi carregado..."
sleep 5

CONTAINER_ID=$(docker ps --filter "name=${STACK_NAME}_chatwoot_app" --format "{{.ID}}" | head -1)

if [ -n "$CONTAINER_ID" ]; then
    log_info "Testando módulo SDR IA no container $CONTAINER_ID..."

    docker exec $CONTAINER_ID bundle exec rails runner "puts 'SDR IA enabled: ' + SdrIa.enabled?.to_s" 2>&1 | grep -i "sdr ia enabled" && \
        log_info "✅ Módulo SDR IA carregado com sucesso!" || \
        log_warn "⚠️  Não foi possível verificar o módulo SDR IA"
else
    log_warn "Não foi possível encontrar o container para teste"
fi

# Finalização
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
log_info "🎉 Deploy concluído!"
echo ""
log_info "Próximos passos:"
echo "  1. Acesse: https://chatteste.nexusatemporal.com"
echo "  2. Faça login como administrador"
echo "  3. Vá em: Configurações → SDR IA"
echo "  4. Configure sua OpenAI API Key"
echo "  5. Teste a qualificação!"
echo ""
log_info "Para monitorar os logs:"
echo "  docker service logs -f $SERVICE_APP | grep \"SDR IA\""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

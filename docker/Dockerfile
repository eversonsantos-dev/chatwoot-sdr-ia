# ============================================================
# Chatwoot SDR IA - Docker Image
# ============================================================
# Imagem: Chatwoot original + Módulo SDR IA
# Versão: 3.1.0
# ============================================================

ARG CHATWOOT_VERSION=v4.1.0
FROM chatwoot/chatwoot:${CHATWOOT_VERSION}

LABEL maintainer="eversonsantos-dev"
LABEL description="Chatwoot with SDR IA Module"
LABEL version="3.1.0"

USER root

# Criar diretórios necessários
RUN mkdir -p /app/plugins/sdr_ia \
    /app/tmp/cache \
    /app/tmp/pids \
    /app/log

# ============================================================
# BACKEND - Módulo SDR IA
# ============================================================

# Plugin SDR IA
COPY plugins/sdr_ia /app/plugins/sdr_ia

# Model
COPY models/sdr_ia_config.rb /app/app/models/sdr_ia_config.rb

# Controllers
COPY controllers/api/v1/accounts/sdr_ia /app/app/controllers/api/v1/accounts/sdr_ia

# Migration (ÚNICA - consolidada)
COPY db/migrate/20251120100000_create_sdr_ia_configs.rb /app/db/migrate/

# Initializer
COPY config/initializers/sdr_ia.rb /app/config/initializers/sdr_ia.rb

# Routes (Chatwoot completo + SDR IA)
COPY config/routes.rb /app/config/routes.rb

# Patch AsyncDispatcher
COPY patches/async_dispatcher.rb /app/app/dispatchers/async_dispatcher.rb

# ============================================================
# FRONTEND - Arquivos Vue.js do SDR IA
# ============================================================

# Componentes SDR IA
COPY frontend/routes/dashboard/settings/sdr-ia /app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia

# Routes do frontend
COPY frontend/settings.routes.js /app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js

# Sidebar com SDR IA
COPY frontend/sidebar-settings.js /app/app/javascript/dashboard/components/layout/config/sidebarItems/settings.js

# ============================================================
# RECOMPILAR ASSETS COM SDR IA
# ============================================================

# Instalar dependências Node e recompilar assets
WORKDIR /app

# Reinstalar dependências e compilar
RUN corepack enable && corepack prepare pnpm@9.0.4 --activate && \
    pnpm install --frozen-lockfile && \
    SECRET_KEY_BASE=precompile_placeholder RAILS_ENV=production \
    bundle exec rake assets:precompile && \
    rm -rf node_modules tmp/cache

# ============================================================
# ENTRYPOINT PERSONALIZADO
# ============================================================

# Script de inicialização que executa migrations
COPY docker/entrypoint-sdr.sh /app/docker/entrypoints/rails-sdr.sh
RUN chmod +x /app/docker/entrypoints/rails-sdr.sh

# Ajustar permissões
RUN chown -R chatwoot:chatwoot /app/plugins /app/tmp /app/log /app/db/migrate 2>/dev/null || true

# Verificação
RUN echo "=== SDR IA Module ===" && \
    ls -la /app/plugins/sdr_ia/ && \
    ls -la /app/db/migrate/ | grep sdr && \
    echo "=== Verificando assets compilados ===" && \
    ls -la /app/public/vite/assets/ | head -10 && \
    echo "=== OK ==="

WORKDIR /app

# Usar o entrypoint personalizado
ENTRYPOINT ["docker/entrypoints/rails-sdr.sh"]

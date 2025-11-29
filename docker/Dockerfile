# ============================================================
# Chatwoot SDR IA - Docker Image (Multi-Stage Build)
# ============================================================
# Imagem: Chatwoot original + Módulo SDR IA com SaaS Licensing
# Versão: 4.0.4
# IMPORTANTE: Compatível com Chatwoot v4.8.0+ (nova arquitetura)
# ============================================================

ARG CHATWOOT_VERSION=v4.8.0

# ============================================================
# STAGE 1: Builder - Compilar assets com Node.js
# ============================================================
FROM chatwoot/chatwoot:${CHATWOOT_VERSION} AS builder

ARG CHATWOOT_VERSION
ENV CHATWOOT_VERSION=${CHATWOOT_VERSION}

USER root

# Instalar dependências necessárias
RUN apk add --no-cache \
    nodejs \
    npm \
    curl \
    bash \
    jq \
    sed

# Instalar pnpm na versão correta
RUN npm install -g pnpm@10.2.0

WORKDIR /app

# Copiar APENAS os arquivos de rotas do SDR IA (não substituir arquivos do Chatwoot)
COPY frontend/routes/dashboard/settings/sdr-ia /app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia

# Copiar script de injeção
COPY scripts/inject_sdr_ia_frontend.sh /tmp/inject_sdr_ia_frontend.sh
RUN chmod +x /tmp/inject_sdr_ia_frontend.sh

# Executar injeção do SDR IA no frontend
RUN /tmp/inject_sdr_ia_frontend.sh

# Instalar dependências e compilar assets
RUN pnpm install --frozen-lockfile || pnpm install && \
    SECRET_KEY_BASE=precompile_placeholder RAILS_ENV=production \
    bundle exec rake assets:precompile

# ============================================================
# STAGE 2: Final - Imagem de produção
# ============================================================
FROM chatwoot/chatwoot:${CHATWOOT_VERSION}

ARG CHATWOOT_VERSION
ENV CHATWOOT_VERSION=${CHATWOOT_VERSION}
ENV SDR_IA_VERSION=4.0.4

LABEL maintainer="eversonsantos-dev"
LABEL description="Chatwoot with SDR IA Module - Multi-tenant SaaS"
LABEL version="${SDR_IA_VERSION}"
LABEL chatwoot_version="${CHATWOOT_VERSION}"

USER root

# Criar diretórios necessários
RUN mkdir -p /app/plugins/sdr_ia \
    /app/tmp/cache \
    /app/tmp/pids \
    /app/log \
    /app/scripts

# ============================================================
# BACKEND - Módulo SDR IA
# ============================================================

# Plugin SDR IA completo
COPY plugins/sdr_ia /app/plugins/sdr_ia

# Models
COPY models/sdr_ia_config.rb /app/app/models/sdr_ia_config.rb
COPY models/sdr_ia_license.rb /app/app/models/sdr_ia_license.rb

# Controllers
COPY controllers/api/v1/accounts/sdr_ia /app/app/controllers/api/v1/accounts/sdr_ia

# Super Admin (Dashboard de Licenças)
COPY super_admin/dashboards/sdr_ia_license_dashboard.rb /app/app/dashboards/sdr_ia_license_dashboard.rb
COPY super_admin/controllers/sdr_ia_licenses_controller.rb /app/app/controllers/super_admin/sdr_ia_licenses_controller.rb
COPY super_admin/views/sdr_ia_licenses /app/app/views/super_admin/sdr_ia_licenses

# Migrations - TODAS
COPY db/migrate/20251120100000_create_sdr_ia_configs.rb /app/db/migrate/
COPY db/migrate/20251129000001_create_sdr_ia_licenses.rb /app/db/migrate/

# Initializer
COPY config/initializers/sdr_ia.rb /app/config/initializers/sdr_ia.rb

# Script de injeção de rotas dinâmico
COPY scripts/inject_routes.rb /app/scripts/inject_routes.rb

# Patch AsyncDispatcher
COPY patches/async_dispatcher.rb /app/app/dispatchers/async_dispatcher.rb

# ============================================================
# FRONTEND - Copiar rotas SDR IA e assets compilados
# ============================================================

# Copiar arquivos de rotas do SDR IA
COPY frontend/routes/dashboard/settings/sdr-ia /app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia

# Copiar script de injeção do frontend
COPY scripts/inject_sdr_ia_frontend.sh /app/scripts/inject_sdr_ia_frontend.sh
RUN chmod +x /app/scripts/inject_sdr_ia_frontend.sh

# Executar injeção do SDR IA no frontend (modifica arquivos originais do Chatwoot)
RUN /app/scripts/inject_sdr_ia_frontend.sh

# Copiar assets compilados do stage builder
COPY --from=builder /app/public/vite /app/public/vite
COPY --from=builder /app/public/assets /app/public/assets

# ============================================================
# ENTRYPOINT PERSONALIZADO - Substitui o entrypoint do Chatwoot
# ============================================================

# Backup do entrypoint original e substituir pelo nosso
RUN if [ -f /app/docker/entrypoints/rails.sh ]; then \
      cp /app/docker/entrypoints/rails.sh /app/docker/entrypoints/rails.sh.original; \
    fi

# Copiar nosso entrypoint customizado como o principal
COPY docker/entrypoint-sdr-saas.sh /app/docker/entrypoints/rails.sh
RUN chmod +x /app/docker/entrypoints/rails.sh

# Também copiar como rails-sdr.sh para compatibilidade
COPY docker/entrypoint-sdr-saas.sh /app/docker/entrypoints/rails-sdr.sh
RUN chmod +x /app/docker/entrypoints/rails-sdr.sh

# Ajustar permissões
RUN chown -R chatwoot:chatwoot /app/plugins /app/tmp /app/log /app/db/migrate /app/scripts 2>/dev/null || true

# ============================================================
# Verificação Final
# ============================================================
RUN echo "=== SDR IA Module v${SDR_IA_VERSION} ===" && \
    echo "=== Chatwoot Version: ${CHATWOOT_VERSION} ===" && \
    echo "" && \
    echo "=== Backend Files ===" && \
    ls -la /app/plugins/sdr_ia/ && \
    ls -la /app/db/migrate/ | grep -E "(sdr_ia|license)" && \
    ls -la /app/app/models/sdr_ia*.rb && \
    echo "" && \
    echo "=== Frontend SDR IA Routes ===" && \
    ls -la /app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia/ && \
    echo "" && \
    echo "=== Verificando injeção no Sidebar ===" && \
    (grep -q "SDR IA" /app/app/javascript/dashboard/components-next/sidebar/Sidebar.vue && echo "[OK] SDR IA no Sidebar.vue" || echo "[WARN] SDR IA não encontrado no Sidebar.vue") && \
    echo "" && \
    echo "=== Verificando injeção nas rotas ===" && \
    (grep -q "sdr-ia" /app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js && echo "[OK] SDR IA nas rotas" || echo "[WARN] SDR IA não encontrado nas rotas") && \
    echo "" && \
    echo "=== Assets Compilados ===" && \
    ls -la /app/public/vite/assets/ | head -5 && \
    echo "" && \
    echo "=== Build OK ==="

WORKDIR /app

# O entrypoint rails.sh já foi substituído pelo nosso customizado

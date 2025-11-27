# ============================================================
# Chatwoot SDR IA - Custom Docker Image
# ============================================================
# Imagem customizada do Chatwoot com módulo SDR IA integrado
#
# Mantido por: eversonsantos-dev
# Repositório: github.com/eversonsantos-dev/chatwoot-sdr-ia
# Docker Hub: eversonsantosdev/chatwoot-sdr-ia
# ============================================================

# ============================================================
# STAGE 1: Builder - Compilar assets com Node.js
# ============================================================
ARG CHATWOOT_VERSION=v4.1.0
FROM chatwoot/chatwoot:${CHATWOOT_VERSION} AS builder

USER root

# Instalar Node.js e npm
RUN apk add --no-cache nodejs npm curl bash

# Instalar pnpm
RUN npm install -g pnpm@10.2.0

WORKDIR /app

# Copiar arquivos do frontend SDR IA
COPY frontend/routes/dashboard/settings/sdr-ia /app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia
COPY frontend/settings.routes.js /app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js
COPY frontend/sidebar-settings.js /app/app/javascript/dashboard/components/layout/config/sidebarItems/settings.js

# Adicionar traduções
RUN sed -i '/"INTEGRATIONS": "Integrações",/a\    "SDR_IA": "SDR IA",' /app/app/javascript/dashboard/i18n/locale/pt_BR/settings.json 2>/dev/null || true && \
    sed -i '/"INTEGRATIONS": "Integrations",/a\    "SDR_IA": "SDR AI",' /app/app/javascript/dashboard/i18n/locale/en/settings.json 2>/dev/null || true

# Limpar caches antigos
RUN rm -rf /app/public/vite /app/public/packs /app/public/assets \
    /app/node_modules/.vite /app/.vite /app/tmp/cache/*

# Instalar dependências
RUN pnpm install 2>/dev/null || npm install

# Compilar assets para produção
RUN SECRET_KEY_BASE=placeholder \
    RAILS_ENV=production \
    NODE_ENV=production \
    bundle exec rails assets:precompile

# ============================================================
# STAGE 2: Final - Imagem de produção
# ============================================================
FROM chatwoot/chatwoot:${CHATWOOT_VERSION}

# Metadata
LABEL maintainer="eversonsantos-dev <github.com/eversonsantos-dev>"
LABEL description="Chatwoot with SDR IA Module - Automatic Lead Qualification"
LABEL version="2.1.2"
LABEL org.opencontainers.image.source="https://github.com/eversonsantos-dev/chatwoot-sdr-ia"

USER root

# Criar diretórios necessários
RUN mkdir -p /app/plugins/sdr_ia \
    /app/tmp/cache \
    /app/tmp/pids \
    /app/log

# ============================================================
# BACKEND - Copiar arquivos do módulo SDR IA
# ============================================================

# Plugin principal
COPY plugins/sdr_ia /app/plugins/sdr_ia

# Model
COPY models/sdr_ia_config.rb /app/app/models/sdr_ia_config.rb

# Controllers
COPY controllers/api/v1/accounts/sdr_ia /app/app/controllers/api/v1/accounts/sdr_ia

# Migrations
COPY db/migrate/*.rb /app/db/migrate/

# Initializer
COPY config/initializers/sdr_ia.rb /app/config/initializers/sdr_ia.rb

# Routes (arquivo completo modificado)
COPY config/routes.rb /app/config/routes.rb

# Patch do AsyncDispatcher para registrar o listener
COPY patches/async_dispatcher.rb /app/app/dispatchers/async_dispatcher.rb

# ============================================================
# FRONTEND - Copiar assets compilados do builder
# ============================================================

# Copiar assets compilados
COPY --from=builder /app/public/vite /app/public/vite
COPY --from=builder /app/public/assets /app/public/assets

# Copiar arquivos fonte do frontend (para referência)
COPY frontend/routes/dashboard/settings/sdr-ia /app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia
COPY frontend/settings.routes.js /app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js
COPY frontend/sidebar-settings.js /app/app/javascript/dashboard/components/layout/config/sidebarItems/settings.js

# Copiar traduções atualizadas
COPY --from=builder /app/app/javascript/dashboard/i18n/locale/pt_BR/settings.json /app/app/javascript/dashboard/i18n/locale/pt_BR/settings.json
COPY --from=builder /app/app/javascript/dashboard/i18n/locale/en/settings.json /app/app/javascript/dashboard/i18n/locale/en/settings.json

# ============================================================
# VERIFICAÇÃO
# ============================================================

RUN echo "=== SDR IA Module instalado ===" && \
    ls -la /app/plugins/sdr_ia/ && \
    echo "=== Frontend SDR IA ===" && \
    ls -la /app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia/ && \
    echo "=== Assets compilados ===" && \
    ls -la /app/public/vite/ 2>/dev/null || echo "Vite assets OK" && \
    echo "=== Instalação concluída ==="

# Ajustar permissões
RUN chown -R chatwoot:chatwoot /app/plugins /app/tmp /app/log 2>/dev/null || true

WORKDIR /app

# O entrypoint padrão do Chatwoot será usado

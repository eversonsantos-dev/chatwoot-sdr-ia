# ============================================================
# Chatwoot SDR IA - Custom Docker Image
# ============================================================
# Imagem customizada do Chatwoot com módulo SDR IA integrado
#
# Mantido por: eversonsantos-dev
# Repositório: github.com/eversonsantos-dev/chatwoot-sdr-ia
# Docker Hub: eversonsantosdev/chatwoot-sdr-ia
# ============================================================

ARG CHATWOOT_VERSION=v4.1.0
FROM chatwoot/chatwoot:${CHATWOOT_VERSION}

# Metadata
LABEL maintainer="eversonsantos-dev <github.com/eversonsantos-dev>"
LABEL description="Chatwoot with SDR IA Module - Automatic Lead Qualification"
LABEL version="2.1.1"
LABEL org.opencontainers.image.source="https://github.com/eversonsantos-dev/chatwoot-sdr-ia"

# Mudar para root para instalar dependências
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
# FRONTEND - Copiar componentes Vue.js
# ============================================================

# Instalar ferramentas necessárias
RUN apk add --no-cache curl bash

# Instalar pnpm
RUN npm install -g pnpm@10.2.0

# Limpar caches antigos
RUN rm -rf /app/public/vite /app/public/packs /app/public/assets \
    /app/node_modules/.vite /app/.vite /app/tmp/cache/*

# Copiar componentes do frontend SDR IA
COPY frontend/routes/dashboard/settings/sdr-ia /app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia

# Copiar arquivos modificados (rotas e sidebar)
COPY frontend/settings.routes.js /app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js
COPY frontend/sidebar-settings.js /app/app/javascript/dashboard/components/layout/config/sidebarItems/settings.js

# Adicionar traduções
RUN sed -i '/"INTEGRATIONS": "Integrações",/a\    "SDR_IA": "SDR IA",' /app/app/javascript/dashboard/i18n/locale/pt_BR/settings.json 2>/dev/null || true && \
    sed -i '/"INTEGRATIONS": "Integrations",/a\    "SDR_IA": "SDR AI",' /app/app/javascript/dashboard/i18n/locale/en/settings.json 2>/dev/null || true

# ============================================================
# BUILD - Compilar assets
# ============================================================

# Instalar dependências e compilar
WORKDIR /app

RUN pnpm install --frozen-lockfile 2>/dev/null || pnpm install

# Limpar cache do Vite antes de compilar
RUN rm -rf /app/node_modules/.vite/* /root/.vite/* /root/.cache/* /tmp/*

# Compilar assets para produção
RUN SECRET_KEY_BASE=placeholder \
    RAILS_ENV=production \
    NODE_ENV=production \
    bundle exec rails assets:precompile

# ============================================================
# CLEANUP - Limpar arquivos temporários
# ============================================================

RUN rm -rf /root/.cache /root/.local /app/tmp/cache/* \
    && rm -rf /app/node_modules/.cache

# Verificar se os arquivos foram copiados corretamente
RUN echo "=== SDR IA Module instalado ===" && \
    ls -la /app/plugins/sdr_ia/ && \
    echo "=== Frontend SDR IA ===" && \
    ls -la /app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia/ && \
    echo "=== Instalação concluída ==="

# Voltar para usuário não-root (segurança)
# USER chatwoot

WORKDIR /app

# O entrypoint padrão do Chatwoot será usado
# Ele executa migrations automaticamente

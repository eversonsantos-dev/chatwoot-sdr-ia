# Chatwoot SDR IA - Custom Docker Image
# Baseado na imagem oficial do Chatwoot v4.1.0
#
# Este Dockerfile cria uma imagem customizada do Chatwoot que inclui
# o módulo SDR IA com todas as suas funcionalidades.

ARG CHATWOOT_VERSION=v4.1.0
FROM chatwoot/chatwoot:${CHATWOOT_VERSION}

# Metadata
LABEL maintainer="eversonsantos-dev"
LABEL description="Chatwoot with SDR IA Module"
LABEL version="1.0.0"

USER root

# Copiar plugin SDR IA
COPY plugins/sdr_ia /app/plugins/sdr_ia

# Copiar controllers
COPY controllers/api/v1/accounts/sdr_ia /app/app/controllers/api/v1/accounts/sdr_ia

# Copiar model
COPY models/sdr_ia_config.rb /app/app/models/sdr_ia_config.rb

# Copiar migration
COPY db/migrate/20251120100414_create_sdr_ia_configs.rb /app/db/migrate/20251120100414_create_sdr_ia_configs.rb

# Copiar initializer
COPY config/initializers/sdr_ia.rb /app/config/initializers/sdr_ia.rb

# Copiar frontend
COPY frontend/routes/dashboard/settings/sdr-ia /app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia

# Copiar arquivos modificados do Chatwoot
COPY frontend/settings.routes.js /app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js
COPY frontend/sidebar-settings.js /app/app/javascript/dashboard/components/layout/config/sidebarItems/settings.js

# Atualizar traduções
RUN sed -i '/"INTEGRATIONS": "Integrações",/a\    "SDR_IA": "SDR IA",' /app/app/javascript/dashboard/i18n/locale/pt_BR/settings.json && \
    sed -i '/"INTEGRATIONS": "Integrations",/a\    "SDR_IA": "SDR AI",' /app/app/javascript/dashboard/i18n/locale/en/settings.json

# Criar diretórios necessários
RUN mkdir -p /app/tmp/cache /app/tmp/pids

# Instalar pnpm e recompilar assets frontend
RUN apk add --no-cache curl bash && \
    export SHELL=/bin/bash && \
    curl -fsSL https://get.pnpm.io/install.sh | bash - && \
    export PNPM_HOME="/root/.local/share/pnpm" && \
    export PATH="$PNPM_HOME:$PATH" && \
    cd /app && \
    rm -rf /app/public/vite /app/public/packs /app/public/assets && \
    pnpm install && \
    SECRET_KEY_BASE=placeholder RAILS_ENV=production NODE_ENV=production bundle exec rails assets:precompile && \
    apk del curl bash && \
    rm -rf /root/.cache /root/.local

# O resto do processo segue o entrypoint original do Chatwoot
# Que vai rodar migrations, etc.

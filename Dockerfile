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

# Copiar ConversationManager (ambas versões)
COPY plugins/sdr_ia/app/services/conversation_manager.rb /app/plugins/sdr_ia/app/services/conversation_manager.rb
COPY plugins/sdr_ia/app/services/conversation_manager_v2.rb /app/plugins/sdr_ia/app/services/conversation_manager_v2.rb
COPY plugins/sdr_ia/app/services/openai_client.rb /app/plugins/sdr_ia/app/services/openai_client.rb

# Copiar controllers
COPY controllers/api/v1/accounts/sdr_ia /app/app/controllers/api/v1/accounts/sdr_ia

# Copiar model
COPY models/sdr_ia_config.rb /app/app/models/sdr_ia_config.rb

# Copiar migrations
COPY db/migrate/20251120100414_create_sdr_ia_configs.rb /app/db/migrate/20251120100414_create_sdr_ia_configs.rb
COPY db/migrate/20251120152500_add_prompts_to_sdr_ia_configs.rb /app/db/migrate/20251120152500_add_prompts_to_sdr_ia_configs.rb
COPY db/migrate/20251120230000_add_default_agent_to_sdr_ia_configs.rb /app/db/migrate/20251120230000_add_default_agent_to_sdr_ia_configs.rb

# Copiar initializer
COPY config/initializers/sdr_ia.rb /app/config/initializers/sdr_ia.rb

# Copiar routes.rb modificado com rotas do SDR IA
COPY config/routes.rb /app/config/routes.rb

# Copiar AsyncDispatcher modificado para incluir SDR IA Listener
COPY patches/async_dispatcher.rb /app/app/dispatchers/async_dispatcher.rb

# Criar diretórios necessários
RUN mkdir -p /app/tmp/cache /app/tmp/pids

# Instalar pnpm
RUN apk add --no-cache curl bash

# Instalar pnpm
RUN export SHELL=/bin/bash && \
    curl -fsSL https://get.pnpm.io/install.sh | bash -

# IMPORTANTE: Limpar caches ANTES de copiar novos arquivos
RUN cd /app && \
    rm -rf /app/public/vite /app/public/packs /app/public/assets && \
    rm -rf /app/node_modules/.vite /app/.vite && \
    rm -rf /app/tmp/cache/*

# Copiar frontend (DEPOIS de limpar cache)
COPY frontend/routes/dashboard/settings/sdr-ia /app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia

# Copiar arquivos modificados do Chatwoot
COPY frontend/settings.routes.js /app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js
COPY frontend/sidebar-settings.js /app/app/javascript/dashboard/components/layout/config/sidebarItems/settings.js

# Verificar se o arquivo foi copiado corretamente
RUN echo "=== Verificando Index.vue copiado ===" && \
    head -5 /app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia/Index.vue && \
    echo "=== Verificação concluída ==="

# Atualizar traduções
RUN sed -i '/"INTEGRATIONS": "Integrações",/a\    "SDR_IA": "SDR IA",' /app/app/javascript/dashboard/i18n/locale/pt_BR/settings.json && \
    sed -i '/"INTEGRATIONS": "Integrations",/a\    "SDR_IA": "SDR AI",' /app/app/javascript/dashboard/i18n/locale/en/settings.json

# Instalar dependências
RUN export PNPM_HOME="/root/.local/share/pnpm" && \
    export PATH="$PNPM_HOME:$PATH" && \
    cd /app && \
    pnpm install --force

# Recompilar assets
RUN export PNPM_HOME="/root/.local/share/pnpm" && \
    export PATH="$PNPM_HOME:$PATH" && \
    cd /app && \
    SECRET_KEY_BASE=placeholder RAILS_ENV=production NODE_ENV=production bundle exec rails assets:precompile

# Verificar compilação
RUN ls -lh /app/public/vite/assets/ | grep dashboard | head -5 || echo "Assets compilados"

# Limpar arquivos temporários
RUN rm -rf /root/.cache /root/.local

# O resto do processo segue o entrypoint original do Chatwoot
# Que vai rodar migrations, etc.

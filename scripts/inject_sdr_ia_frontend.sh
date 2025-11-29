#!/bin/bash
# ============================================================
# Inject SDR IA Frontend into Chatwoot v4.8.0+
# ============================================================
# Este script injeta o módulo SDR IA no frontend do Chatwoot
# de forma compatível com a nova arquitetura components-next
# ============================================================

set -e

echo "==========================================="
echo " SDR IA Frontend Injection"
echo "==========================================="

SDR_IA_ROUTES_DIR="/app/app/javascript/dashboard/routes/dashboard/settings/sdr-ia"
SETTINGS_ROUTES="/app/app/javascript/dashboard/routes/dashboard/settings/settings.routes.js"
SIDEBAR_VUE="/app/app/javascript/dashboard/components-next/sidebar/Sidebar.vue"

# ============================================================
# 1. Verificar se os arquivos SDR IA existem
# ============================================================
echo "[1/4] Verificando arquivos SDR IA..."
if [ ! -d "$SDR_IA_ROUTES_DIR" ]; then
    echo "[ERROR] Diretório de rotas SDR IA não encontrado: $SDR_IA_ROUTES_DIR"
    exit 1
fi
echo "[OK] Diretório de rotas SDR IA encontrado"

# ============================================================
# 2. Injetar import e rotas no settings.routes.js
# ============================================================
echo "[2/4] Injetando rotas SDR IA em settings.routes.js..."

if grep -q "sdr-ia" "$SETTINGS_ROUTES" 2>/dev/null; then
    echo "[INFO] Rotas SDR IA já estão presentes"
else
    # Adicionar import do sdrIa
    # Procurar última linha de import e adicionar depois
    if grep -q "import profile from" "$SETTINGS_ROUTES"; then
        sed -i "/import profile from/a import sdrIa from './sdr-ia/sdr-ia.routes';" "$SETTINGS_ROUTES"
    elif grep -q "import security from" "$SETTINGS_ROUTES"; then
        sed -i "/import security from/a import sdrIa from './sdr-ia/sdr-ia.routes';" "$SETTINGS_ROUTES"
    else
        # Fallback: adicionar antes de export default
        sed -i "/^export default/i import sdrIa from './sdr-ia/sdr-ia.routes';" "$SETTINGS_ROUTES"
    fi

    # Adicionar rotas no array (antes do fechamento do array)
    # Procurar última rota e adicionar ...sdrIa.routes depois
    if grep -q "\.\.\.security\.routes" "$SETTINGS_ROUTES"; then
        sed -i "s/\.\.\.security\.routes,/...security.routes,\n    ...sdrIa.routes,/" "$SETTINGS_ROUTES"
    elif grep -q "\.\.\.profile\.routes" "$SETTINGS_ROUTES"; then
        sed -i "s/\.\.\.profile\.routes,/...profile.routes,\n    ...sdrIa.routes,/" "$SETTINGS_ROUTES"
    else
        # Fallback: adicionar antes do fechamento do array
        sed -i "/^  \],$/i\    ...sdrIa.routes," "$SETTINGS_ROUTES"
    fi

    if grep -q "sdrIa" "$SETTINGS_ROUTES"; then
        echo "[OK] Rotas SDR IA injetadas com sucesso"
    else
        echo "[WARN] Falha ao injetar rotas SDR IA"
    fi
fi

# ============================================================
# 3. Injetar item SDR IA no Sidebar.vue (components-next)
# ============================================================
echo "[3/4] Injetando SDR IA no Sidebar.vue..."

if [ ! -f "$SIDEBAR_VUE" ]; then
    echo "[WARN] Sidebar.vue não encontrado. Versão antiga do Chatwoot?"
else
    if grep -q "SDR IA" "$SIDEBAR_VUE"; then
        echo "[INFO] SDR IA já está no Sidebar.vue"
    else
        # Adicionar o item SDR IA antes de 'Settings Billing'
        sed -i "/name: 'Settings Billing'/i\\
        {\\
          name: 'Settings SDR IA',\\
          label: 'SDR IA',\\
          icon: 'i-lucide-brain',\\
          to: accountScopedRoute('sdr_ia_settings'),\\
        }," "$SIDEBAR_VUE"

        if grep -q "SDR IA" "$SIDEBAR_VUE"; then
            echo "[OK] SDR IA injetado no Sidebar.vue"
        else
            echo "[WARN] Falha ao injetar SDR IA no Sidebar.vue"
        fi
    fi
fi

# ============================================================
# 4. Adicionar tradução para SDR IA
# ============================================================
echo "[4/4] Adicionando traduções SDR IA..."

# Adicionar no sidebar translations
SIDEBAR_EN="/app/app/javascript/dashboard/i18n/locale/en/sidebar.json"
SIDEBAR_PT="/app/app/javascript/dashboard/i18n/locale/pt_BR/sidebar.json"

if [ -f "$SIDEBAR_EN" ] && ! grep -q "SDR_IA" "$SIDEBAR_EN"; then
    # Adicionar SDR_IA após INTEGRATIONS
    sed -i '/"INTEGRATIONS"/a\  "SDR_IA": "SDR AI",' "$SIDEBAR_EN" 2>/dev/null || true
    echo "[OK] Tradução EN adicionada"
fi

if [ -f "$SIDEBAR_PT" ] && ! grep -q "SDR_IA" "$SIDEBAR_PT"; then
    sed -i '/"INTEGRATIONS"/a\  "SDR_IA": "SDR IA",' "$SIDEBAR_PT" 2>/dev/null || true
    echo "[OK] Tradução PT-BR adicionada"
fi

echo "==========================================="
echo " SDR IA Frontend Injection - Completo!"
echo "==========================================="

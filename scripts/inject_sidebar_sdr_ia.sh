#!/bin/bash
# ============================================================
# Inject SDR IA menu item into Chatwoot v4.8.0+ Sidebar.vue
# ============================================================
# Este script adiciona o item SDR IA no menu Settings do sidebar
# Compatível com Chatwoot v4.8.0 que usa components-next
# ============================================================

SIDEBAR_FILE="/app/app/javascript/dashboard/components-next/sidebar/Sidebar.vue"

echo "[INFO] Injetando SDR IA no Sidebar.vue..."

if [ ! -f "$SIDEBAR_FILE" ]; then
    echo "[WARN] Sidebar.vue não encontrado em components-next. Pode ser versão antiga."
    exit 0
fi

# Verificar se SDR IA já foi injetado
if grep -q "SDR IA" "$SIDEBAR_FILE"; then
    echo "[INFO] SDR IA já está no Sidebar.vue"
    exit 0
fi

# Adicionar o item SDR IA antes de Settings Billing
# Procura por "Settings Billing" e insere SDR IA antes dele
sed -i "/name: 'Settings Billing'/i\\
        {\\
          name: 'Settings SDR IA',\\
          label: 'SDR IA',\\
          icon: 'i-lucide-brain',\\
          to: accountScopedRoute('sdr_ia_settings'),\\
        }," "$SIDEBAR_FILE"

# Verificar se a injeção foi bem-sucedida
if grep -q "SDR IA" "$SIDEBAR_FILE"; then
    echo "[OK] SDR IA injetado no Sidebar.vue com sucesso!"
else
    echo "[WARN] Falha ao injetar SDR IA no Sidebar.vue"
fi

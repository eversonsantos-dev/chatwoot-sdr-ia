#!/bin/bash
# ============================================================
# Inject SDR IA Routes into Chatwoot routes.rb
# ============================================================
# Este script injeta as rotas do SDR IA no routes.rb do Chatwoot
# durante o BUILD da imagem Docker (não em runtime)
# ============================================================

set -e

ROUTES_FILE="/app/config/routes.rb"
MARKER="# SDR_IA_ROUTES_INJECTED"

echo "=========================================="
echo " SDR IA Routes Injection (Build Time)"
echo "=========================================="

# Verificar se arquivo existe
if [ ! -f "$ROUTES_FILE" ]; then
    echo "[ERROR] routes.rb não encontrado: $ROUTES_FILE"
    exit 1
fi

# Verificar se já foi injetado
if grep -q "$MARKER" "$ROUTES_FILE"; then
    echo "[INFO] Rotas SDR IA já estão injetadas"
    exit 0
fi

echo "[INFO] Fazendo backup de routes.rb..."
cp "$ROUTES_FILE" "$ROUTES_FILE.backup"

# ============================================================
# Injetar rotas da API SDR IA
# Inserir ANTES de "resources :working_hours"
# ============================================================
echo "[INFO] Injetando rotas da API SDR IA..."

# Usar awk para inserir as rotas antes de "resources :working_hours"
awk '
/resources :working_hours/ {
    print ""
    print "          # SDR IA - Qualificação Automática de Leads (SaaS Multi-tenant)"
    print "          # '"$MARKER"'"
    print "          namespace :sdr_ia do"
    print "            get '\''settings'\'', to: '\''settings#show'\''"
    print "            put '\''settings'\'', to: '\''settings#update'\''"
    print "            post '\''test'\'', to: '\''settings#test_qualification'\''"
    print "            get '\''stats'\'', to: '\''settings#stats'\''"
    print "            get '\''teams'\'', to: '\''settings#teams'\''"
    print "            get '\''license'\'', to: '\''settings#license_info'\''"
    print "          end"
    print ""
}
{ print }
' "$ROUTES_FILE" > "$ROUTES_FILE.tmp" && mv "$ROUTES_FILE.tmp" "$ROUTES_FILE"

# ============================================================
# Injetar rotas do Super Admin
# Inserir ANTES de "resources :account_users" dentro de super_admin
# ============================================================
echo "[INFO] Injetando rotas do Super Admin..."

# Usar awk para inserir as rotas do super admin
awk '
/resources :account_users, only: \[:new, :create, :show, :destroy\]/ {
    print ""
    print "      # SDR IA License Management"
    print "      # '"$MARKER"'"
    print "      resources :sdr_ia_licenses do"
    print "        member do"
    print "          post :suspend"
    print "          post :reactivate"
    print "          post :extend_trial"
    print "          post :reset_usage"
    print "          post :upgrade"
    print "        end"
    print "        collection do"
    print "          get :stats"
    print "          get :accounts_without_license"
    print "          post :create_trial"
    print "          post :bulk_create_trials"
    print "          post :expire_trials"
    print "          post :reset_all_usage"
    print "        end"
    print "      end"
    print ""
}
{ print }
' "$ROUTES_FILE" > "$ROUTES_FILE.tmp" && mv "$ROUTES_FILE.tmp" "$ROUTES_FILE"

# Verificar se foi injetado corretamente
if grep -q "namespace :sdr_ia" "$ROUTES_FILE"; then
    echo "[OK] Rotas da API SDR IA injetadas!"
else
    echo "[ERROR] Falha ao injetar rotas da API"
    cp "$ROUTES_FILE.backup" "$ROUTES_FILE"
    exit 1
fi

if grep -q "resources :sdr_ia_licenses" "$ROUTES_FILE"; then
    echo "[OK] Rotas do Super Admin injetadas!"
else
    echo "[WARN] Rotas do Super Admin podem não ter sido injetadas"
fi

echo "=========================================="
echo " SDR IA Routes Injection - Completo!"
echo "=========================================="

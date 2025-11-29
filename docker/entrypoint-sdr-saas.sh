#!/bin/bash
set -e

echo "=========================================="
echo " Chatwoot SDR IA SaaS - Iniciando..."
echo " Versão SDR IA: ${SDR_IA_VERSION:-4.0.1}"
echo " Versão Chatwoot: ${CHATWOOT_VERSION:-v4.8.0}"
echo "=========================================="

# Limpar arquivos temporários
rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

# Aguardar PostgreSQL estar disponível
echo "[INFO] Aguardando PostgreSQL..."
POSTGRES_HOST="${POSTGRES_HOST:-postgres}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USERNAME:-postgres}"

until pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" 2>/dev/null; do
  echo "[INFO] PostgreSQL não disponível em $POSTGRES_HOST:$POSTGRES_PORT, aguardando 3s..."
  sleep 3
done
echo "[OK] PostgreSQL conectado!"

# Verificar se o banco de dados existe
echo "[INFO] Verificando banco de dados..."
if bundle exec rails db:version 2>/dev/null | grep -q "Current version"; then
  echo "[INFO] Banco existe. Executando migrations pendentes..."
  bundle exec rails db:migrate 2>&1 || echo "[WARN] Algumas migrations podem já existir"
else
  echo "[INFO] Banco não configurado. Preparando..."
  bundle exec rails db:chatwoot_prepare 2>&1 || bundle exec rails db:prepare 2>&1
fi
echo "[OK] Banco de dados OK!"

# Instalar Custom Attributes do SDR IA (apenas no container principal - rails server)
if [[ "$1" == *"rails"* ]] && [[ "$1" == *"s"* || "$@" == *"server"* ]]; then
  echo "[INFO] Container principal detectado. Instalando SDR IA..."

  # ============================================================
  # CRÍTICO: Injetar rotas do SDR IA no Rails
  # ============================================================
  echo "[INFO] Injetando rotas SDR IA no Rails..."
  if [ -f /app/scripts/inject_routes.rb ]; then
    bundle exec rails runner /app/scripts/inject_routes.rb 2>&1 || echo "[WARN] Erro na injeção de rotas (pode já existir)"
    echo "[OK] Rotas SDR IA verificadas!"
  else
    echo "[WARN] Script inject_routes.rb não encontrado!"
  fi

  # Instalar Custom Attributes
  if [ -f /app/plugins/sdr_ia/install.rb ]; then
    echo "[INFO] Instalando Custom Attributes..."
    bundle exec rails runner /app/plugins/sdr_ia/install.rb 2>&1 || echo "[INFO] Attributes já existem"
    echo "[OK] Custom Attributes instalados!"
  fi

  # Verificar tabelas SDR IA
  echo "[INFO] Verificando tabelas SDR IA..."
  bundle exec rails runner "
    puts '[INFO] Verificando sdr_ia_configs...'
    if ActiveRecord::Base.connection.table_exists?('sdr_ia_configs')
      puts '[OK] Tabela sdr_ia_configs existe'
    else
      puts '[WARN] Tabela sdr_ia_configs não encontrada'
    end

    puts '[INFO] Verificando sdr_ia_licenses...'
    if ActiveRecord::Base.connection.table_exists?('sdr_ia_licenses')
      puts '[OK] Tabela sdr_ia_licenses existe'
    else
      puts '[WARN] Tabela sdr_ia_licenses não encontrada'
    end
  " 2>&1 || echo "[INFO] Verificação concluída"

  # Verificar se rotas foram injetadas
  echo "[INFO] Verificando rotas SDR IA..."
  bundle exec rails runner "
    routes = Rails.application.routes.routes.select { |r| r.path.spec.to_s.include?('sdr_ia') }
    if routes.any?
      puts \"[OK] #{routes.count} rotas SDR IA encontradas\"
    else
      puts '[WARN] Nenhuma rota SDR IA encontrada - verifique logs'
    end
  " 2>&1 || echo "[INFO] Verificação de rotas concluída"
fi

echo "=========================================="
echo " Chatwoot SDR IA SaaS - Pronto!"
echo "=========================================="
echo ""

# Executar comando passado
exec bundle exec "$@"

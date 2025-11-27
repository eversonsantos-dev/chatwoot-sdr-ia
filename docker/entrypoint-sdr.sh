#!/bin/sh
set -e

echo "=========================================="
echo " Chatwoot SDR IA - Iniciando..."
echo "=========================================="

# Aguardar banco de dados
echo "[INFO] Aguardando PostgreSQL..."
until bundle exec rails db:version 2>/dev/null; do
  echo "[INFO] PostgreSQL não disponível, aguardando 5s..."
  sleep 5
done
echo "[OK] PostgreSQL conectado!"

# Executar migrations automaticamente
echo "[INFO] Verificando migrations..."
if bundle exec rails db:migrate:status 2>/dev/null | grep -q "down"; then
  echo "[INFO] Executando migrations pendentes..."
  bundle exec rails db:migrate
  echo "[OK] Migrations executadas!"
else
  echo "[OK] Banco de dados atualizado!"
fi

# Preparar banco (seeds, configs, etc)
echo "[INFO] Preparando Chatwoot..."
bundle exec rails db:chatwoot_prepare 2>/dev/null || true

echo "=========================================="
echo " Chatwoot SDR IA - Pronto!"
echo "=========================================="

# Executar comando passado (rails s, sidekiq, etc)
exec "$@"

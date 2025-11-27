#!/bin/sh
set -e

echo "=========================================="
echo " Chatwoot SDR IA - Iniciando..."
echo "=========================================="

# Aguardar PostgreSQL estar disponível
echo "[INFO] Aguardando PostgreSQL..."
until pg_isready -h ${POSTGRES_HOST:-chatwoot_postgres} -p ${POSTGRES_PORT:-5432} -U ${POSTGRES_USERNAME:-postgres} 2>/dev/null; do
  echo "[INFO] PostgreSQL não disponível, aguardando 3s..."
  sleep 3
done
echo "[OK] PostgreSQL conectado!"

# Verificar se o banco de dados existe e tem tabelas
echo "[INFO] Verificando banco de dados..."
if ! bundle exec rails db:version 2>/dev/null | grep -q "Current version"; then
  echo "[INFO] Banco de dados não existe ou está vazio. Criando..."
  bundle exec rails db:chatwoot_prepare
  echo "[OK] Banco de dados criado e configurado!"
else
  # Banco existe, verificar migrations pendentes
  echo "[INFO] Banco existe. Verificando migrations..."
  bundle exec rails db:migrate
  echo "[OK] Migrations atualizadas!"
fi

# Instalar Custom Attributes do SDR IA (apenas no container principal, não no sidekiq)
if echo "$@" | grep -q "rails s"; then
  echo "[INFO] Instalando Custom Attributes do SDR IA..."
  if [ -f /app/plugins/sdr_ia/install.rb ]; then
    bundle exec rails runner /app/plugins/sdr_ia/install.rb 2>/dev/null || echo "[WARN] Custom Attributes podem já existir"
    echo "[OK] Custom Attributes verificados!"
  else
    echo "[WARN] Arquivo install.rb não encontrado"
  fi
fi

echo "=========================================="
echo " Chatwoot SDR IA - Pronto!"
echo "=========================================="

# Executar comando passado (rails s, sidekiq, etc)
exec "$@"

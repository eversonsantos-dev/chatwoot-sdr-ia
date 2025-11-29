#!/bin/sh
set -e

echo "=========================================="
echo " Chatwoot SDR IA SaaS - Iniciando..."
echo " Versão SDR IA: ${SDR_IA_VERSION:-4.0.0}"
echo " Versão Chatwoot: ${CHATWOOT_VERSION:-unknown}"
echo "=========================================="

# Aguardar PostgreSQL estar disponível
echo "[INFO] Aguardando PostgreSQL..."
until pg_isready -h ${POSTGRES_HOST:-chatwoot_postgres} -p ${POSTGRES_PORT:-5432} -U ${POSTGRES_USERNAME:-postgres} 2>/dev/null; do
  echo "[INFO] PostgreSQL não disponível, aguardando 3s..."
  sleep 3
done
echo "[OK] PostgreSQL conectado!"

# Injetar rotas SDR IA dinamicamente (se necessário)
if [ -f /app/scripts/inject_routes.rb ]; then
  echo "[INFO] Verificando rotas SDR IA..."
  bundle exec rails runner /app/scripts/inject_routes.rb 2>/dev/null || echo "[INFO] Rotas já configuradas ou script ignorado"
fi

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

  # Verificar/criar tabela de licenças
  echo "[INFO] Verificando tabela de licenças SDR IA..."
  bundle exec rails runner "
    begin
      if ActiveRecord::Base.connection.table_exists?('sdr_ia_licenses')
        puts '[OK] Tabela sdr_ia_licenses existe'
        puts \"[INFO] Total de licenças: #{SdrIaLicense.count}\"
      else
        puts '[WARN] Tabela sdr_ia_licenses não encontrada - migrations podem estar pendentes'
      end
    rescue => e
      puts \"[WARN] Erro ao verificar tabela de licenças: #{e.message}\"
    end
  " 2>/dev/null || echo "[INFO] Verificação de licenças concluída"
fi

echo "=========================================="
echo " Chatwoot SDR IA SaaS - Pronto!"
echo "=========================================="

# Executar comando passado (rails s, sidekiq, etc)
exec "$@"

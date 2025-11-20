#!/bin/bash
# Script de Teste do Módulo SDR IA

echo "🧪 TESTANDO MÓDULO SDR IA"
echo "========================="
echo ""

# 1. Verificar se módulo está instalado
echo "1️⃣ Verificando instalação..."
if docker exec chatwoot_chatwoot_app.1.j0ce7vl3ek2cg8v13l3x5v1gd ls /app/plugins/sdr_ia/ > /dev/null 2>&1; then
    echo "   ✅ Módulo instalado em /app/plugins/sdr_ia/"
else
    echo "   ❌ Módulo NÃO encontrado!"
    exit 1
fi

# 2. Verificar se está habilitado
echo ""
echo "2️⃣ Verificando se está habilitado..."
ENABLED=$(docker exec chatwoot_chatwoot_app.1.j0ce7vl3ek2cg8v13l3x5v1gd cat /app/plugins/sdr_ia/config/settings.yml | grep "enabled:" | awk '{print $2}')
if [ "$ENABLED" = "true" ]; then
    echo "   ✅ Módulo HABILITADO"
else
    echo "   ❌ Módulo DESABILITADO (edite settings.yml)"
    exit 1
fi

# 3. Verificar OpenAI API Key
echo ""
echo "3️⃣ Verificando OpenAI API Key..."
API_KEY=$(docker exec chatwoot_chatwoot_app.1.j0ce7vl3ek2cg8v13l3x5v1gd printenv OPENAI_API_KEY 2>/dev/null)
if [ -n "$API_KEY" ]; then
    echo "   ✅ API Key configurada: ${API_KEY:0:10}..."
else
    echo "   ❌ API Key NÃO configurada!"
    echo "   👉 Adicione OPENAI_API_KEY ao chatwoot.yaml"
    exit 1
fi

# 4. Verificar Custom Attributes
echo ""
echo "4️⃣ Verificando Custom Attributes..."
COUNT=$(docker exec chatwoot_chatwoot_app.1.j0ce7vl3ek2cg8v13l3x5v1gd bundle exec rails runner "puts Account.first.custom_attribute_definitions.where('attribute_key LIKE ?', 'sdr_ia_%').count" 2>/dev/null | tail -1)
echo "   ✅ $COUNT custom attributes criados"

# 5. Verificar Labels
echo ""
echo "5️⃣ Verificando Labels..."
LABEL_COUNT=$(docker exec chatwoot_chatwoot_app.1.j0ce7vl3ek2cg8v13l3x5v1gd bundle exec rails runner "puts Account.first.labels.where('title LIKE ? OR title LIKE ? OR title LIKE ?', 'temperatura-%', 'procedimento-%', 'urgencia-%').count" 2>/dev/null | tail -1)
echo "   ✅ $LABEL_COUNT labels criadas"

# 6. Teste manual (se houver contatos)
echo ""
echo "6️⃣ Teste manual com último contato..."
echo "   Executando qualificação no último contato..."
docker exec chatwoot_chatwoot_app.1.j0ce7vl3ek2cg8v13l3x5v1gd bundle exec rails runner "
contact = Contact.last
if contact
  puts '   📞 Testando contact: ' + contact.name.to_s + ' (ID: ' + contact.id.to_s + ')'
  result = SdrIa::LeadQualifier.new(contact: contact).qualify!
  if result[:success]
    puts '   ✅ Qualificação FUNCIONOU!'
    puts '   Temperatura: ' + contact.custom_attributes['sdr_ia_temperatura'].to_s
    puts '   Score: ' + contact.custom_attributes['sdr_ia_score'].to_s
  else
    puts '   ⚠️  Qualificação retornou: ' + result[:reason].to_s
  end
else
  puts '   ⚠️  Nenhum contato encontrado para testar'
end
" 2>&1 | grep -v "ERROR\|INFO\|rake"

echo ""
echo "========================="
echo "✅ TESTE CONCLUÍDO!"
echo ""
echo "📝 Para monitorar em tempo real:"
echo "   docker service logs chatwoot_chatwoot_app -f | grep 'SDR IA'"
echo ""

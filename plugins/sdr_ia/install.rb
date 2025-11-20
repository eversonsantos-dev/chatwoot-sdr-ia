# frozen_string_literal: true

# Script de Instalação do Módulo SDR IA
# Execute com: bundle exec rails runner plugins/sdr_ia/install.rb

puts "🚀 Instalando SDR IA Module para Chatwoot..."
puts ""

account = Account.first

unless account
  puts "❌ Nenhuma conta encontrada!"
  exit 1
end

puts "📋 Criando Custom Attributes..."

custom_attrs = [
  { key: 'sdr_ia_status', name: 'SDR IA - Status', type: 'list', values: ['em_andamento', 'completo', 'incompleto', 'pausado', 'qualificado'] },
  { key: 'sdr_ia_progresso', name: 'SDR IA - Progresso', type: 'text' },
  { key: 'sdr_ia_temperatura', name: 'SDR IA - Temperatura', type: 'list', values: ['quente', 'morno', 'frio', 'muito_frio'] },
  { key: 'sdr_ia_score', name: 'SDR IA - Score', type: 'number' },
  { key: 'sdr_ia_nome', name: 'SDR IA - Nome', type: 'text' },
  { key: 'sdr_ia_interesse', name: 'SDR IA - Interesse', type: 'text' },
  { key: 'sdr_ia_urgencia', name: 'SDR IA - Urgência', type: 'text' },
  { key: 'sdr_ia_conhecimento', name: 'SDR IA - Conhecimento', type: 'text' },
  { key: 'sdr_ia_motivacao', name: 'SDR IA - Motivação', type: 'text' },
  { key: 'sdr_ia_localizacao', name: 'SDR IA - Localização', type: 'text' },
  { key: 'sdr_ia_comportamento', name: 'SDR IA - Comportamento', type: 'text' },
  { key: 'sdr_ia_resumo', name: 'SDR IA - Resumo para Closer', type: 'text' },
  { key: 'sdr_ia_proximo_passo', name: 'SDR IA - Próximo Passo', type: 'text' },
  { key: 'sdr_ia_tentativas', name: 'SDR IA - Tentativas JSON', type: 'text' },
  { key: 'sdr_ia_iniciado_em', name: 'SDR IA - Iniciado em', type: 'text' },
  { key: 'sdr_ia_qualificado_em', name: 'SDR IA - Qualificado em', type: 'text' }
]

custom_attrs.each do |attr|
  ca = account.custom_attribute_definitions.find_or_initialize_by(
    attribute_key: attr[:key],
    attribute_model: 'contact_attribute'
  )

  ca.attribute_display_name = attr[:name]
  ca.attribute_display_type = attr[:type]
  ca.attribute_values = attr[:values] if attr[:values]

  if ca.save
    puts "  ✅ #{attr[:name]}"
  else
    puts "  ⚠️  #{attr[:name]} - #{ca.errors.full_messages.join(', ')}"
  end
end

puts ""
puts "🏷️  Criando Tags Padrão..."

labels = [
  'temperatura-quente',
  'temperatura-morno',
  'temperatura-frio',
  'temperatura-muito_frio',
  'procedimento-harmonizacao_facial',
  'procedimento-emagrecimento',
  'procedimento-cabelo',
  'procedimento-botox',
  'procedimento-pele',
  'urgencia-esta_semana',
  'urgencia-proximas_2_semanas',
  'urgencia-ate_30_dias',
  'urgencia-acima_30_dias',
  'urgencia-pesquisando'
]

labels.each do |label_name|
  label = account.labels.find_or_initialize_by(title: label_name)

  if label.save
    puts "  ✅ #{label_name}"
  else
    puts "  ⚠️  #{label_name} - #{label.errors.full_messages.join(', ')}"
  end
end

puts ""
puts "✅ Instalação Concluída!"
puts ""
puts "📝 Próximos passos:"
puts "1. Configure OPENAI_API_KEY no ambiente"
puts "2. Ajuste settings.yml conforme necessário"
puts "3. Reinicie o Chatwoot"
puts ""

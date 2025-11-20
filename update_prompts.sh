#!/bin/bash

# Script para atualizar prompts do SDR IA
# Este script atualiza os prompts para o novo formato conversacional

echo "🔄 Atualizando prompts do SDR IA..."

# Ler o novo prompt do arquivo YAML
SYSTEM_PROMPT=$(ruby -ryaml -e "
config = YAML.load_file('plugins/sdr_ia/config/prompts_new.yml')
puts config['prompts']['system']
")

ANALYSIS_PROMPT=$(ruby -ryaml -e "
config = YAML.load_file('plugins/sdr_ia/config/prompts_new.yml')
puts config['prompts']['analysis']
")

# Atualizar no banco de dados via Rails console
echo "📝 Atualizando prompts no banco de dados..."

docker exec -it $(docker ps -q -f name=chatwoot_chatwoot_app) bundle exec rails runner "
  SdrIaConfig.find_each do |config|
    config.update!(
      prompt_system: File.read('plugins/sdr_ia/config/prompts_new.yml').match(/system: \|(.*?)analysis:/m)[1].strip,
      prompt_analysis: File.read('plugins/sdr_ia/config/prompts_new.yml').match(/analysis: \|(.*)/m)[1].strip,
      default_agent_email: 'pedro.zoia@nexusatemporal.com',
      clinic_name: 'Nexus Atemporal',
      ai_name: 'Nexus IA',
      clinic_address: 'A ser configurado'
    )
    puts \"[OK] Config atualizada para conta #{config.account_id}\"
  end
  puts '✅ Todos os prompts foram atualizados!'
"

echo "✅ Atualização concluída!"

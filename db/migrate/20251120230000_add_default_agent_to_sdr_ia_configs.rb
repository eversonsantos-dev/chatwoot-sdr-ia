# frozen_string_literal: true

class AddDefaultAgentToSdrIaConfigs < ActiveRecord::Migration[7.0]
  def change
    # Adicionar campo para email do agente padrão (SDR especialista)
    add_column :sdr_ia_configs, :default_agent_email, :string, default: 'pedro.zoia@nexusatemporal.com'

    # Adicionar campo para nome da clínica (para personalizar mensagens)
    add_column :sdr_ia_configs, :clinic_name, :string, default: 'Nexus Atemporal'

    # Adicionar campo para nome da IA
    add_column :sdr_ia_configs, :ai_name, :string, default: 'Nexus IA'

    # Adicionar campo para endereço da clínica (para responder perguntas)
    add_column :sdr_ia_configs, :clinic_address, :text, default: 'A ser configurado'
  end
end

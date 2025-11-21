# frozen_string_literal: true

# SDR IA Initializer
#
# Este arquivo deve ser copiado para: /app/config/initializers/sdr_ia.rb
#
# Ele integra o módulo SDR IA com o Chatwoot, registrando o listener
# para capturar eventos de conversas e mensagens.

Rails.application.config.to_prepare do
  plugin_path = Rails.root.join('plugins/sdr_ia/lib/sdr_ia.rb')

  if File.exist?(plugin_path)
    require plugin_path
    Rails.logger.info "[SDR IA] Carregando módulo SDR IA..."

    if SdrIa.enabled?
      begin
        Rails.logger.info "[SDR IA] Módulo habilitado. Carregando classes..."

        # Força o carregamento das classes do plugin
        require Rails.root.join('plugins/sdr_ia/app/services/openai_client')
        require Rails.root.join('plugins/sdr_ia/app/services/lead_qualifier')
        require Rails.root.join('plugins/sdr_ia/app/services/conversation_manager')
        require Rails.root.join('plugins/sdr_ia/app/services/conversation_manager_v2')
        require Rails.root.join('plugins/sdr_ia/app/jobs/qualify_lead_job')
        require Rails.root.join('plugins/sdr_ia/app/listeners/sdr_ia_listener')

        Rails.logger.info "[SDR IA] Classes carregadas. Listener será registrado pelo AsyncDispatcher."
      rescue StandardError => e
        Rails.logger.error "[SDR IA] Erro ao carregar classes: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    else
      Rails.logger.info "[SDR IA] Módulo desabilitado"
    end
  else
    Rails.logger.warn "[SDR IA] Plugin não encontrado em #{plugin_path}"
  end
end

# frozen_string_literal: true

# SDR IA Initializer
#
# Este arquivo deve ser copiado para: /app/config/initializers/sdr_ia.rb
#
# Ele integra o módulo SDR IA com o Chatwoot, registrando o listener
# para capturar eventos de conversas e mensagens.

Rails.application.config.to_prepare do
  # Adicionar associação ao modelo Account (necessário para Super Admin)
  begin
    Account.class_eval do
      has_one :sdr_ia_license, dependent: :destroy unless reflect_on_association(:sdr_ia_license)
    end
    Rails.logger.info "[SDR IA] Associação Account.has_one :sdr_ia_license adicionada"
  rescue StandardError => e
    Rails.logger.warn "[SDR IA] Não foi possível adicionar associação: #{e.message}"
  end

  # Carregar Model SdrIaLicense
  begin
    model_path = Rails.root.join('app/models/sdr_ia_license.rb')
    if File.exist?(model_path)
      require_dependency model_path
      Rails.logger.info "[SDR IA] Model SdrIaLicense carregado"
    end
  rescue StandardError => e
    Rails.logger.warn "[SDR IA] Não foi possível carregar model: #{e.message}"
  end

  # Carregar Dashboard do Super Admin (Administrate)
  begin
    dashboard_path = Rails.root.join('app/dashboards/sdr_ia_license_dashboard.rb')
    if File.exist?(dashboard_path)
      require_dependency dashboard_path
      Rails.logger.info "[SDR IA] Dashboard SdrIaLicenseDashboard carregado"
    end
  rescue StandardError => e
    Rails.logger.warn "[SDR IA] Não foi possível carregar dashboard: #{e.message}"
  end

  # Carregar Controller do Super Admin
  begin
    controller_path = Rails.root.join('app/controllers/super_admin/sdr_ia_licenses_controller.rb')
    if File.exist?(controller_path)
      require_dependency controller_path
      Rails.logger.info "[SDR IA] Controller SuperAdmin::SdrIaLicensesController carregado"
    end
  rescue StandardError => e
    Rails.logger.warn "[SDR IA] Não foi possível carregar controller: #{e.message}"
  end

  plugin_path = Rails.root.join('plugins/sdr_ia/lib/sdr_ia.rb')

  if File.exist?(plugin_path)
    require plugin_path
    Rails.logger.info "[SDR IA] Carregando módulo SDR IA..."

    begin
      Rails.logger.info "[SDR IA] Carregando classes essenciais..."

      # SEMPRE carregar classes essenciais (controller precisa delas)
      require Rails.root.join('plugins/sdr_ia/app/services/license_validator')
      require Rails.root.join('plugins/sdr_ia/app/services/openai_client')
      require Rails.root.join('plugins/sdr_ia/app/services/lead_qualifier')
      require Rails.root.join('plugins/sdr_ia/app/services/conversation_manager')
      require Rails.root.join('plugins/sdr_ia/app/services/conversation_manager_v2')
      require Rails.root.join('plugins/sdr_ia/app/services/message_buffer')
      require Rails.root.join('plugins/sdr_ia/app/services/audio_transcriber')
      require Rails.root.join('plugins/sdr_ia/app/services/round_robin_assigner')
      require Rails.root.join('plugins/sdr_ia/app/jobs/qualify_lead_job')
      require Rails.root.join('plugins/sdr_ia/app/jobs/process_buffered_messages_job')
      require Rails.root.join('plugins/sdr_ia/app/listeners/sdr_ia_listener')

      Rails.logger.info "[SDR IA] Classes carregadas com sucesso!"

      if SdrIa.enabled?
        Rails.logger.info "[SDR IA] Módulo HABILITADO. Listener será registrado."
      else
        Rails.logger.info "[SDR IA] Módulo desabilitado (enabled: false)"
      end
    rescue StandardError => e
      Rails.logger.error "[SDR IA] Erro ao carregar classes: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  else
    Rails.logger.warn "[SDR IA] Plugin não encontrado em #{plugin_path}"
  end
end

# frozen_string_literal: true

module SdrIa
  class Error < StandardError; end

  def self.enabled?
    config = YAML.load_file(Rails.root.join('plugins/sdr_ia/config/settings.yml'))
    config.dig('sdr_ia', 'enabled') == true
  rescue => e
    Rails.logger.error "[SDR IA] Erro ao carregar config: #{e.message}"
    false
  end

  def self.config
    @config ||= YAML.load_file(Rails.root.join('plugins/sdr_ia/config/settings.yml'))['sdr_ia']
  end

  def self.reload_config!
    @config = nil
    config
    Rails.logger.info "[SDR IA] Configuração recarregada"
  end
end

if defined?(Rails)
  Rails.application.config.after_initialize do
    next unless File.exist?(Rails.root.join('plugins/sdr_ia/config/settings.yml'))

    Rails.logger.info "[SDR IA] Carregando módulo SDR IA..."

    # Load routes
    routes_file = Rails.root.join('plugins/sdr_ia/config/routes.rb')
    if File.exist?(routes_file)
      load routes_file
      Rails.logger.info "[SDR IA] Rotas carregadas"
    end

    config_enabled = SdrIa.enabled?

    if config_enabled
      Rails.logger.info "[SDR IA] Módulo habilitado. Registrando listener..."

      require Rails.root.join('plugins/sdr_ia/app/services/openai_client')
      require Rails.root.join('plugins/sdr_ia/app/services/lead_qualifier')
      require Rails.root.join('plugins/sdr_ia/app/jobs/qualify_lead_job')
      require Rails.root.join('plugins/sdr_ia/app/listeners/sdr_ia_listener')

      Rails.logger.info "[SDR IA] Classes carregadas. Listener pronto."
    else
      Rails.logger.info "[SDR IA] Módulo desabilitado (enabled: false no settings.yml)"
    end
  end
end

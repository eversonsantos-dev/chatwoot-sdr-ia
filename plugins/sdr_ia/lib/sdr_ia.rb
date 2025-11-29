# frozen_string_literal: true

module SdrIa
  class Error < StandardError; end

  def self.enabled?
    # Tenta buscar do banco primeiro, se falhar usa YAML como fallback
    return db_config_enabled? if db_available?

    # Fallback para arquivo YAML
    yaml_config_enabled?
  rescue => e
    Rails.logger.error "[SDR IA] Erro ao verificar se módulo está habilitado: #{e.message}"
    false
  end

  def self.config(account = nil)
    # Se uma conta for fornecida, busca config específica
    if account
      db_config = SdrIaConfig.find_by(account: account)
      return db_config.to_config_hash['sdr_ia'] if db_config
    end

    # Tenta buscar a primeira config do banco
    if db_available?
      first_config = SdrIaConfig.first
      return first_config.to_config_hash['sdr_ia'] if first_config
    end

    # Fallback para YAML
    @config ||= yaml_config
  end

  def self.reload_config!
    @config = nil
    Rails.logger.info "[SDR IA] Configuração recarregada"
  end

  private

  def self.db_available?
    return false unless defined?(ActiveRecord) && ActiveRecord::Base.connected?
    return false unless ActiveRecord::Base.connection.table_exists?('sdr_ia_configs')
    true
  rescue
    false
  end

  def self.db_config_enabled?
    first_config = SdrIaConfig.first
    first_config&.enabled || false
  end

  def self.yaml_config_enabled?
    yaml_config = YAML.load_file(Rails.root.join('plugins/sdr_ia/config/settings.yml'))
    yaml_config.dig('sdr_ia', 'enabled') == true
  rescue
    false
  end

  def self.yaml_config
    YAML.load_file(Rails.root.join('plugins/sdr_ia/config/settings.yml'))['sdr_ia']
  rescue => e
    Rails.logger.error "[SDR IA] Erro ao carregar config YAML: #{e.message}"
    {}
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

    # ============================================================
    # CRÍTICO: Carregar LicenseValidator SEMPRE (controller precisa)
    # Deve ser carregado ANTES de checar enabled? pois o controller
    # usa essas classes mesmo quando o módulo está "desabilitado"
    # ============================================================
    begin
      require Rails.root.join('plugins/sdr_ia/app/services/license_validator')
      Rails.logger.info "[SDR IA] LicenseValidator carregado com sucesso"
    rescue => e
      Rails.logger.error "[SDR IA] Erro ao carregar LicenseValidator: #{e.message}"
    end

    config_enabled = SdrIa.enabled?

    if config_enabled
      Rails.logger.info "[SDR IA] Módulo habilitado. Carregando classes adicionais..."

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

      Rails.logger.info "[SDR IA] Todas as classes carregadas. Listener pronto."
    else
      Rails.logger.info "[SDR IA] Módulo desabilitado (enabled: false). Classes adicionais não carregadas."
    end
  end
end

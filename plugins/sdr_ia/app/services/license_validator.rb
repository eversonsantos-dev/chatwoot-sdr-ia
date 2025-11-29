# frozen_string_literal: true

module SdrIa
  # Exceções de licenciamento
  class LicenseError < StandardError; end
  class LicenseNotFoundError < LicenseError; end
  class LicenseExpiredError < LicenseError; end
  class LicenseSuspendedError < LicenseError; end
  class TrialExpiredError < LicenseError; end
  class UsageLimitError < LicenseError; end
  class ModelNotAllowedError < LicenseError; end
  class FeatureNotAllowedError < LicenseError; end

  class LicenseValidator
    attr_reader :account, :license, :errors

    def initialize(account)
      @account = account
      @license = SdrIaLicense.for_account(account)
      @errors = []
    end

    # Validação completa da licença
    def validate!
      validate_license_exists!
      validate_status!
      validate_trial!
      validate_expiration!
      validate_usage!

      license
    end

    # Validação rápida (retorna boolean)
    def valid?
      validate!
      true
    rescue LicenseError
      false
    end

    # Verificar se pode processar lead
    def can_process_lead?
      return false unless license&.active?
      return false if license.expired? || license.trial_expired?
      return false if license.usage_limit_reached?

      true
    end

    # Verificar se modelo é permitido
    def validate_model!(model)
      validate!

      unless license.model_allowed?(model)
        raise ModelNotAllowedError,
              "Modelo '#{model}' não permitido. Modelos disponíveis: #{license.allowed_models.join(', ')}"
      end

      true
    end

    # Verificar se feature é permitida
    def validate_feature!(feature)
      validate!

      feature_enabled = case feature.to_sym
                        when :custom_prompts then license.custom_prompts_enabled?
                        when :api_access then license.api_access_enabled?
                        when :knowledge_base then license.knowledge_base_enabled?
                        when :round_robin then license.round_robin_enabled?
                        when :audio_transcription then license.audio_transcription_enabled?
                        else true
                        end

      unless feature_enabled
        raise FeatureNotAllowedError,
              "Feature '#{feature}' não disponível no plano #{license.license_type.titleize}. Faça upgrade para desbloquear."
      end

      true
    end

    # Incrementar uso após processar lead
    def increment_usage!
      return false unless license

      unless license.increment_usage!
        raise UsageLimitError, "Limite mensal de #{license.monthly_lead_limit} leads atingido"
      end

      log_usage_increment
      true
    end

    # Obter modelo permitido (retorna o configurado se permitido, ou o default)
    def get_allowed_model(requested_model)
      return license.default_model unless license

      license.model_allowed?(requested_model) ? requested_model : license.default_model
    end

    # Informações de uso para exibição
    # SEMPRE retorna um objeto, nunca nil
    def usage_info
      # Se não tem licença, retorna objeto indicando isso
      unless license
        return {
          has_license: false,
          status: 'none',
          message: 'Nenhuma licença encontrada para esta conta',
          activation_url: nil
        }
      end

      # Se tem licença, retorna informações completas
      {
        has_license: true,
        license_type: license.license_type,
        status: license.status,
        monthly_limit: license.monthly_lead_limit,
        monthly_usage: license.monthly_lead_usage,
        remaining: license.remaining_leads,
        percentage: license.usage_percentage,
        trial_days_remaining: license.trial_days_remaining,
        expires_at: license.expires_at,
        can_process: can_process_lead?,
        activation_url: license.try(:activation_url),
        features: {
          custom_prompts: license.custom_prompts_enabled?,
          api_access: license.api_access_enabled?,
          knowledge_base: license.knowledge_base_enabled?,
          round_robin: license.round_robin_enabled?,
          audio_transcription: license.audio_transcription_enabled?
        },
        allowed_models: license.allowed_models
      }
    end

    # Métodos de classe para uso rápido
    class << self
      def validate!(account)
        new(account).validate!
      end

      def valid?(account)
        new(account).valid?
      end

      def can_process_lead?(account)
        new(account).can_process_lead?
      end

      def increment_usage!(account)
        new(account).increment_usage!
      end

      def usage_info(account)
        new(account).usage_info
      end

      def get_allowed_model(account, requested_model)
        new(account).get_allowed_model(requested_model)
      end

      # Criar licença trial para nova conta
      def create_trial!(account)
        return if SdrIaLicense.for_account(account)

        SdrIaLicense.create_trial_for_account!(account)
      end

      # Jobs de manutenção
      def expire_overdue_trials!
        count = 0
        SdrIaLicense.trials.where('trial_ends_at < ? AND status = ?', Time.current, 'active').find_each do |license|
          license.expire!
          notify_trial_expired(license)
          count += 1
        end
        Rails.logger.info "[SDR IA] #{count} trials expirados"
        count
      end

      def expire_overdue_licenses!
        count = 0
        SdrIaLicense.where('expires_at < ? AND status = ?', Time.current, 'active').find_each do |license|
          license.expire!
          notify_license_expired(license)
          count += 1
        end
        Rails.logger.info "[SDR IA] #{count} licenças expiradas"
        count
      end

      def reset_monthly_usage!
        count = 0
        SdrIaLicense.active.where('usage_reset_at < ?', 1.month.ago).find_each do |license|
          license.reset_monthly_usage!
          count += 1
        end
        Rails.logger.info "[SDR IA] #{count} contadores de uso resetados"
        count
      end

      def send_expiration_warnings!
        # Avisar 3 dias antes do trial expirar
        SdrIaLicense.trial_expiring_soon.find_each do |license|
          notify_trial_expiring(license)
        end

        # Avisar 7 dias antes da licença expirar
        SdrIaLicense.expiring_soon.find_each do |license|
          notify_license_expiring(license)
        end
      end

      private

      def notify_trial_expired(license)
        Rails.logger.info "[SDR IA] Trial expirado para Account #{license.account_id}"
        # TODO: Enviar email de notificação
      end

      def notify_license_expired(license)
        Rails.logger.info "[SDR IA] Licença expirada para Account #{license.account_id}"
        # TODO: Enviar email de notificação
      end

      def notify_trial_expiring(license)
        Rails.logger.info "[SDR IA] Trial expirando em #{license.trial_days_remaining} dias para Account #{license.account_id}"
        # TODO: Enviar email de notificação
      end

      def notify_license_expiring(license)
        days = ((license.expires_at - Time.current) / 1.day).ceil
        Rails.logger.info "[SDR IA] Licença expirando em #{days} dias para Account #{license.account_id}"
        # TODO: Enviar email de notificação
      end
    end

    private

    def validate_license_exists!
      raise LicenseNotFoundError, 'Módulo SDR IA não habilitado para esta conta. Entre em contato para ativar.' unless license
    end

    def validate_status!
      case license.status
      when 'suspended'
        raise LicenseSuspendedError, license.suspension_reason || 'Licença suspensa. Entre em contato com o suporte.'
      when 'cancelled'
        raise LicenseExpiredError, 'Licença cancelada.'
      when 'expired'
        raise LicenseExpiredError, 'Licença expirada. Renove para continuar usando.'
      end
    end

    def validate_trial!
      return unless license.trial?

      if license.trial_expired?
        license.expire! if license.active?
        raise TrialExpiredError, 'Período de teste encerrado. Faça upgrade para continuar usando o SDR IA.'
      end
    end

    def validate_expiration!
      return unless license.expires_at.present?

      if license.expires_at < Time.current
        license.expire! if license.active?
        raise LicenseExpiredError, 'Licença expirada. Renove para continuar usando.'
      end
    end

    def validate_usage!
      return unless license.usage_limit_reached?

      raise UsageLimitError,
            "Limite mensal de #{license.monthly_lead_limit} leads atingido. " \
            "Uso atual: #{license.monthly_lead_usage}. " \
            "Reset em: #{license.usage_reset_at&.strftime('%d/%m/%Y')}. " \
            'Faça upgrade para aumentar o limite.'
    end

    def log_usage_increment
      Rails.logger.info "[SDR IA] Uso incrementado para Account #{account.id}: #{license.monthly_lead_usage}/#{license.monthly_lead_limit}"
    end
  end
end

# frozen_string_literal: true

class Api::V1::Accounts::SdrIa::SettingsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :validate_license!, except: %i[show license_info]

  def show
    config = SdrIaConfig.for_account(Current.account)
    license_info = SdrIa::LicenseValidator.usage_info(Current.account)

    render json: {
      settings: config.to_config_hash,
      license: license_info
    }
  end

  def update
    # Verificar se modelo é permitido pela licença
    if params.dig(:settings, :sdr_ia, :openai, :model)
      requested_model = params[:settings][:sdr_ia][:openai][:model]
      validator = SdrIa::LicenseValidator.new(Current.account)

      begin
        validator.validate_model!(requested_model)
      rescue SdrIa::ModelNotAllowedError => e
        return render json: {
          success: false,
          error: e.message,
          allowed_models: validator.license&.allowed_models || []
        }, status: :forbidden
      end
    end

    # Verificar features permitidas
    validate_features_in_params!

    config = SdrIaConfig.for_account(Current.account)

    if config.update_from_params(permitted_params)
      render json: {
        success: true,
        message: 'Configurações salvas com sucesso!',
        settings: config.to_config_hash,
        license: SdrIa::LicenseValidator.usage_info(Current.account)
      }
    else
      render json: {
        success: false,
        errors: config.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def test_qualification
    contact = Current.account.contacts.find_by(id: params[:contact_id])

    unless contact
      return render json: {
        success: false,
        error: 'Contato não encontrado'
      }, status: :not_found
    end

    # Verificar se pode processar (mas não incrementar uso no teste)
    validator = SdrIa::LicenseValidator.new(Current.account)
    unless validator.can_process_lead?
      return render json: {
        success: false,
        error: 'Não é possível processar. Verifique sua licença ou limite de uso.',
        license: validator.usage_info
      }, status: :forbidden
    end

    result = SdrIa::LeadQualifier.new(contact: contact, account: Current.account).qualify!

    render json: {
      success: result[:success],
      result: result,
      contact: {
        id: contact.id,
        name: contact.name,
        temperatura: contact.custom_attributes['sdr_ia_temperatura'],
        score: contact.custom_attributes['sdr_ia_score']
      }
    }
  end

  def stats
    total = Current.account.contacts
                   .where("custom_attributes->>'sdr_ia_status' = ?", 'qualificado').count

    license_info = SdrIa::LicenseValidator.usage_info(Current.account)

    render json: {
      total_qualificados: total,
      distribuicao: {
        quente: Current.account.contacts.where("custom_attributes->>'sdr_ia_temperatura' = ?", 'quente').count,
        morno: Current.account.contacts.where("custom_attributes->>'sdr_ia_temperatura' = ?", 'morno').count,
        frio: Current.account.contacts.where("custom_attributes->>'sdr_ia_temperatura' = ?", 'frio').count,
        muito_frio: Current.account.contacts.where("custom_attributes->>'sdr_ia_temperatura' = ?", 'muito_frio').count
      },
      license: license_info
    }
  end

  def teams
    teams = Current.account.teams.pluck(:id, :name).map { |id, name| { id: id, name: name } }
    render json: { teams: teams }
  end

  # Endpoint específico para informações de licença
  def license_info
    license = SdrIaLicense.for_account(Current.account)

    if license
      render json: {
        has_license: true,
        license: SdrIa::LicenseValidator.usage_info(Current.account),
        license_details: {
          type: license.license_type,
          status: license.status,
          key: license.license_key,
          started_at: license.started_at,
          expires_at: license.expires_at,
          trial_ends_at: license.trial_ends_at,
          trial_days_remaining: license.trial_days_remaining,
          can_process: license.can_process_lead?
        }
      }
    else
      render json: {
        has_license: false,
        message: 'Módulo SDR IA não habilitado. Entre em contato para ativar.',
        contact_email: 'suporte@seudominio.com'
      }
    end
  end

  private

  def check_admin_authorization?
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end

  def validate_license!
    SdrIa::LicenseValidator.validate!(Current.account)
  rescue SdrIa::LicenseError => e
    render json: {
      success: false,
      error: e.message,
      license_error: true,
      license: SdrIa::LicenseValidator.usage_info(Current.account)
    }, status: :forbidden
  end

  def validate_features_in_params!
    validator = SdrIa::LicenseValidator.new(Current.account)

    # Verificar knowledge_base
    if params.dig(:settings, :sdr_ia, :knowledge_base).present?
      validator.validate_feature!(:knowledge_base)
    end

    # Verificar round_robin
    if params.dig(:settings, :sdr_ia, :round_robin, :enabled) == true
      validator.validate_feature!(:round_robin)
    end
  rescue SdrIa::FeatureNotAllowedError => e
    render json: {
      success: false,
      error: e.message,
      feature_error: true
    }, status: :forbidden
  end

  def permitted_params
    params.require(:settings).permit!.to_h.deep_symbolize_keys
  end
end

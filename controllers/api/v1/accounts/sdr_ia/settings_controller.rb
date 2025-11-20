# frozen_string_literal: true

class Api::V1::Accounts::SdrIa::SettingsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?

  def show
    @settings = load_settings
    render json: { settings: @settings }
  end

  def update
    settings_path = Rails.root.join('plugins/sdr_ia/config/settings.yml')

    begin
      # Load existing settings
      current_settings = YAML.load_file(settings_path)

      # Update with new values
      updated_settings = deep_merge(current_settings, permitted_params)

      # Write back to file
      File.write(settings_path, updated_settings.to_yaml)

      # Reload the module configuration
      SdrIa.reload_config!

      render json: {
        success: true,
        message: 'Configurações atualizadas com sucesso',
        settings: load_settings
      }
    rescue StandardError => e
      Rails.logger.error "[SDR IA] Erro ao atualizar configurações: #{e.message}"
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  def test_qualification
    contact_id = params[:contact_id]
    contact = Current.account.contacts.find_by(id: contact_id)

    unless contact
      return render json: {
        success: false,
        error: 'Contato não encontrado'
      }, status: :not_found
    end

    result = SdrIa::LeadQualifier.new(contact: contact).qualify!

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
  rescue StandardError => e
    Rails.logger.error "[SDR IA] Erro no teste de qualificação: #{e.message}"
    render json: {
      success: false,
      error: e.message
    }, status: :internal_server_error
  end

  def stats
    account = Current.account

    total_qualificados = account.contacts
      .where("custom_attributes->>'sdr_ia_status' = ?", 'qualificado')
      .count

    quentes = account.contacts
      .where("custom_attributes->>'sdr_ia_temperatura' = ?", 'quente')
      .count

    mornos = account.contacts
      .where("custom_attributes->>'sdr_ia_temperatura' = ?", 'morno')
      .count

    frios = account.contacts
      .where("custom_attributes->>'sdr_ia_temperatura' = ?", 'frio')
      .count

    muito_frios = account.contacts
      .where("custom_attributes->>'sdr_ia_temperatura' = ?", 'muito_frio')
      .count

    render json: {
      total_qualificados: total_qualificados,
      distribuicao: {
        quente: quentes,
        morno: mornos,
        frio: frios,
        muito_frio: muito_frios
      }
    }
  rescue StandardError => e
    Rails.logger.error "[SDR IA] Erro ao buscar estatísticas: #{e.message}"
    render json: {
      success: false,
      error: e.message
    }, status: :internal_server_error
  end

  def teams
    teams = Current.account.teams.pluck(:id, :name).map do |id, name|
      { id: id, name: name }
    end

    render json: { teams: teams }
  rescue StandardError => e
    Rails.logger.error "[SDR IA] Erro ao buscar times: #{e.message}"
    render json: {
      success: false,
      error: e.message
    }, status: :internal_server_error
  end

  private

  def check_admin_authorization?
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end

  def load_settings
    settings_path = Rails.root.join('plugins/sdr_ia/config/settings.yml')
    YAML.load_file(settings_path)
  end

  def permitted_params
    params.require(:settings).permit!.to_h
  end

  def deep_merge(hash1, hash2)
    hash1.merge(hash2) do |_key, old_val, new_val|
      if old_val.is_a?(Hash) && new_val.is_a?(Hash)
        deep_merge(old_val, new_val)
      else
        new_val
      end
    end
  end
end

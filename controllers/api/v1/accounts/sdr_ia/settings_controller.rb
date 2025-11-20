# frozen_string_literal: true

class Api::V1::Accounts::SdrIa::SettingsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?

  def show
    config = SdrIaConfig.for_account(Current.account)
    render json: { settings: config.to_config_hash }
  end

  def update
    config = SdrIaConfig.for_account(Current.account)
    
    if config.update_from_params(permitted_params)
      render json: {
        success: true,
        message: 'Configurações salvas com sucesso!',
        settings: config.to_config_hash
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

    render json: {
      total_qualificados: total,
      distribuicao: {
        quente: Current.account.contacts.where("custom_attributes->>'sdr_ia_temperatura' = ?", 'quente').count,
        morno: Current.account.contacts.where("custom_attributes->>'sdr_ia_temperatura' = ?", 'morno').count,
        frio: Current.account.contacts.where("custom_attributes->>'sdr_ia_temperatura' = ?", 'frio').count,
        muito_frio: Current.account.contacts.where("custom_attributes->>'sdr_ia_temperatura' = ?", 'muito_frio').count
      }
    }
  end

  def teams
    teams = Current.account.teams.pluck(:id, :name).map { |id, name| { id: id, name: name } }
    render json: { teams: teams }
  end

  private

  def check_admin_authorization?
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end

  def permitted_params
    params.require(:settings).permit!.to_h.deep_symbolize_keys
  end
end

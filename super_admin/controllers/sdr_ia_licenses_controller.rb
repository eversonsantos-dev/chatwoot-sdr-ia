# frozen_string_literal: true

class SuperAdmin::SdrIaLicensesController < SuperAdmin::ApplicationController
  # Ações customizadas
  def create_trial
    account = Account.find(params[:account_id])

    if SdrIaLicense.for_account(account)
      flash[:error] = 'Esta conta já possui uma licença SDR IA'
    else
      license = SdrIaLicense.create_trial_for_account!(account)
      flash[:notice] = "Trial criado com sucesso para #{account.name}. Expira em #{license.trial_ends_at.strftime('%d/%m/%Y')}"
    end

    redirect_to super_admin_sdr_ia_licenses_path
  end

  def upgrade
    license = SdrIaLicense.find(params[:id])
    new_type = params[:license_type]

    if SdrIaLicense::LICENSE_TYPES.include?(new_type) && license.upgrade_to!(new_type)
      flash[:notice] = "Licença atualizada para #{new_type.titleize} com sucesso"
    else
      flash[:error] = 'Erro ao atualizar licença'
    end

    redirect_to super_admin_sdr_ia_license_path(license)
  end

  def suspend
    license = SdrIaLicense.find(params[:id])
    reason = params[:reason] || 'Suspensão manual pelo administrador'

    if license.suspend!(reason)
      flash[:notice] = 'Licença suspensa com sucesso'
    else
      flash[:error] = 'Erro ao suspender licença'
    end

    redirect_to super_admin_sdr_ia_license_path(license)
  end

  def reactivate
    license = SdrIaLicense.find(params[:id])

    if license.reactivate!
      flash[:notice] = 'Licença reativada com sucesso'
    else
      flash[:error] = 'Erro ao reativar licença'
    end

    redirect_to super_admin_sdr_ia_license_path(license)
  end

  def extend_trial
    license = SdrIaLicense.find(params[:id])
    days = (params[:days] || 14).to_i

    if license.extend_trial!(days)
      flash[:notice] = "Trial estendido por #{days} dias. Nova data: #{license.trial_ends_at.strftime('%d/%m/%Y')}"
    else
      flash[:error] = 'Erro ao estender trial. Certifique-se de que é uma licença trial.'
    end

    redirect_to super_admin_sdr_ia_license_path(license)
  end

  def reset_usage
    license = SdrIaLicense.find(params[:id])

    if license.reset_monthly_usage!
      flash[:notice] = 'Contador de uso resetado com sucesso'
    else
      flash[:error] = 'Erro ao resetar contador'
    end

    redirect_to super_admin_sdr_ia_license_path(license)
  end

  def bulk_create_trials
    account_ids = params[:account_ids]
    created = 0
    skipped = 0

    Account.where(id: account_ids).find_each do |account|
      if SdrIaLicense.for_account(account)
        skipped += 1
      else
        SdrIaLicense.create_trial_for_account!(account)
        created += 1
      end
    end

    flash[:notice] = "#{created} trials criados. #{skipped} contas já possuíam licença."
    redirect_to super_admin_sdr_ia_licenses_path
  end

  def stats
    @stats = {
      total: SdrIaLicense.count,
      active: SdrIaLicense.active.count,
      suspended: SdrIaLicense.suspended.count,
      expired: SdrIaLicense.expired.count,
      trials: SdrIaLicense.trials.count,
      paid: SdrIaLicense.paid.count,
      by_type: SdrIaLicense.group(:license_type).count,
      by_status: SdrIaLicense.group(:status).count,
      total_usage_this_month: SdrIaLicense.sum(:monthly_lead_usage),
      expiring_soon: SdrIaLicense.expiring_soon.count,
      trial_expiring: SdrIaLicense.trial_expiring_soon.count
    }

    respond_to do |format|
      format.html
      format.json { render json: @stats }
    end
  end

  def accounts_without_license
    @accounts = Account.active
                       .left_joins(:sdr_ia_license)
                       .where(sdr_ia_licenses: { id: nil })
                       .order(:name)
                       .page(params[:page])

    respond_to do |format|
      format.html
      format.json { render json: @accounts.map { |a| { id: a.id, name: a.name } } }
    end
  end

  private

  # Sobrescrever método do Administrate para permitir todos os campos do formulário
  def resource_params
    permitted = params.require(:sdr_ia_license).permit(
      :account_id,
      :license_type,
      :status,
      :expires_at,
      :trial_ends_at,
      :monthly_lead_limit,
      :monthly_lead_usage,
      :max_inboxes,
      :max_agents,
      :custom_prompts_enabled,
      :api_access_enabled,
      :knowledge_base_enabled,
      :round_robin_enabled,
      :audio_transcription_enabled,
      :suspension_reason,
      :billing_email,
      :activation_url,
      :notes,
      :stripe_customer_id,
      :stripe_subscription_id,
      allowed_models: []
    )

    # Garantir que allowed_models seja um array
    if permitted[:allowed_models].is_a?(String)
      permitted[:allowed_models] = permitted[:allowed_models].split(',').map(&:strip)
    end

    permitted
  end

  # Dashboard para Administrate
  def dashboard
    SdrIaLicenseDashboard
  end

  # Modelo para Administrate
  def resource_class
    SdrIaLicense
  end
end

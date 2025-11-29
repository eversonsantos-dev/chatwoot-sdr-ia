# frozen_string_literal: true

# == Schema Information
#
# Table name: sdr_ia_licenses
#
#  id                          :bigint           not null, primary key
#  account_id                  :bigint           not null
#  license_type                :string           default("trial"), not null
#  license_key                 :string
#  started_at                  :datetime
#  expires_at                  :datetime
#  trial_ends_at               :datetime
#  monthly_lead_limit          :integer          default(50)
#  monthly_lead_usage          :integer          default(0)
#  usage_reset_at              :datetime
#  max_inboxes                 :integer          default(1)
#  max_agents                  :integer          default(1)
#  allowed_models              :string           default(["gpt-3.5-turbo"]), is an Array
#  custom_prompts_enabled      :boolean          default(FALSE)
#  api_access_enabled          :boolean          default(FALSE)
#  knowledge_base_enabled      :boolean          default(FALSE)
#  round_robin_enabled         :boolean          default(FALSE)
#  audio_transcription_enabled :boolean          default(FALSE)
#  status                      :string           default("active"), not null
#  suspension_reason           :text
#  suspended_at                :datetime
#  stripe_customer_id          :string
#  stripe_subscription_id      :string
#  billing_email               :string
#  metadata                    :jsonb            default({})
#  notes                       :text
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#

class SdrIaLicense < ApplicationRecord
  belongs_to :account

  # Constantes de tipos de licença
  LICENSE_TYPES = %w[trial basic pro enterprise].freeze
  STATUS_TYPES = %w[active suspended expired cancelled].freeze

  # Configurações padrão por tipo de licença
  LICENSE_DEFAULTS = {
    'trial' => {
      monthly_lead_limit: 50,
      max_inboxes: 1,
      max_agents: 1,
      allowed_models: ['gpt-3.5-turbo'],
      custom_prompts_enabled: false,
      api_access_enabled: false,
      knowledge_base_enabled: false,
      round_robin_enabled: false,
      audio_transcription_enabled: false,
      trial_days: 14
    },
    'basic' => {
      monthly_lead_limit: 200,
      max_inboxes: 1,
      max_agents: 3,
      allowed_models: ['gpt-3.5-turbo', 'gpt-4'],
      custom_prompts_enabled: true,
      api_access_enabled: false,
      knowledge_base_enabled: false,
      round_robin_enabled: false,
      audio_transcription_enabled: true
    },
    'pro' => {
      monthly_lead_limit: 1000,
      max_inboxes: 5,
      max_agents: 10,
      allowed_models: ['gpt-3.5-turbo', 'gpt-4', 'gpt-4-turbo'],
      custom_prompts_enabled: true,
      api_access_enabled: true,
      knowledge_base_enabled: true,
      round_robin_enabled: true,
      audio_transcription_enabled: true
    },
    'enterprise' => {
      monthly_lead_limit: 999_999,
      max_inboxes: 999,
      max_agents: 999,
      allowed_models: ['gpt-3.5-turbo', 'gpt-4', 'gpt-4-turbo', 'gpt-4o'],
      custom_prompts_enabled: true,
      api_access_enabled: true,
      knowledge_base_enabled: true,
      round_robin_enabled: true,
      audio_transcription_enabled: true
    }
  }.freeze

  # Validações
  validates :account_id, uniqueness: true
  validates :license_type, inclusion: { in: LICENSE_TYPES }
  validates :status, inclusion: { in: STATUS_TYPES }
  validates :monthly_lead_limit, numericality: { greater_than_or_equal_to: 0 }
  validates :monthly_lead_usage, numericality: { greater_than_or_equal_to: 0 }
  validates :license_key, uniqueness: true, allow_nil: true

  # Callbacks
  before_create :set_defaults
  before_create :generate_license_key
  before_create :set_trial_period, if: :trial?
  after_update :check_expiration

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :expired, -> { where(status: 'expired') }
  scope :suspended, -> { where(status: 'suspended') }
  scope :trials, -> { where(license_type: 'trial') }
  scope :paid, -> { where.not(license_type: 'trial') }
  scope :expiring_soon, -> { where('expires_at <= ? AND status = ?', 7.days.from_now, 'active') }
  scope :trial_expiring_soon, -> { where('trial_ends_at <= ? AND license_type = ?', 3.days.from_now, 'trial') }

  # Métodos de status
  def active?
    status == 'active'
  end

  def suspended?
    status == 'suspended'
  end

  def expired?
    status == 'expired' || (expires_at.present? && expires_at < Time.current)
  end

  def cancelled?
    status == 'cancelled'
  end

  def trial?
    license_type == 'trial'
  end

  def trial_expired?
    trial? && trial_ends_at.present? && trial_ends_at < Time.current
  end

  def trial_days_remaining
    return nil unless trial? && trial_ends_at.present?

    days = ((trial_ends_at - Time.current) / 1.day).ceil
    [days, 0].max
  end

  # Métodos de limite
  def usage_limit_reached?
    monthly_lead_usage >= monthly_lead_limit
  end

  def usage_percentage
    return 0 if monthly_lead_limit.zero?

    ((monthly_lead_usage.to_f / monthly_lead_limit) * 100).round(1)
  end

  def remaining_leads
    [monthly_lead_limit - monthly_lead_usage, 0].max
  end

  def can_process_lead?
    active? && !expired? && !trial_expired? && !usage_limit_reached?
  end

  # Métodos de modelo OpenAI
  def model_allowed?(model)
    allowed_models.include?(model)
  end

  def default_model
    allowed_models.last || 'gpt-3.5-turbo'
  end

  # Métodos de uso
  def increment_usage!
    return false if usage_limit_reached?

    increment!(:monthly_lead_usage)
    true
  end

  def reset_monthly_usage!
    update!(
      monthly_lead_usage: 0,
      usage_reset_at: Time.current
    )
  end

  # Métodos de gestão
  def suspend!(reason = nil)
    update!(
      status: 'suspended',
      suspension_reason: reason,
      suspended_at: Time.current
    )
  end

  def reactivate!
    update!(
      status: 'active',
      suspension_reason: nil,
      suspended_at: nil
    )
  end

  def expire!
    update!(status: 'expired')
  end

  def cancel!
    update!(status: 'cancelled')
  end

  def upgrade_to!(new_license_type)
    return false unless LICENSE_TYPES.include?(new_license_type)

    defaults = LICENSE_DEFAULTS[new_license_type]
    update!(
      license_type: new_license_type,
      monthly_lead_limit: defaults[:monthly_lead_limit],
      max_inboxes: defaults[:max_inboxes],
      max_agents: defaults[:max_agents],
      allowed_models: defaults[:allowed_models],
      custom_prompts_enabled: defaults[:custom_prompts_enabled],
      api_access_enabled: defaults[:api_access_enabled],
      knowledge_base_enabled: defaults[:knowledge_base_enabled],
      round_robin_enabled: defaults[:round_robin_enabled],
      audio_transcription_enabled: defaults[:audio_transcription_enabled],
      status: 'active',
      trial_ends_at: nil
    )
  end

  def extend_trial!(days = 14)
    return false unless trial?

    new_end = trial_ends_at.present? ? trial_ends_at + days.days : Time.current + days.days
    update!(
      trial_ends_at: new_end,
      status: 'active'
    )
  end

  # Métodos de classe
  def self.for_account(account)
    find_by(account: account)
  end

  def self.create_trial_for_account!(account)
    create!(
      account: account,
      license_type: 'trial',
      started_at: Time.current
    )
  end

  def self.reset_all_monthly_usage!
    active.find_each(&:reset_monthly_usage!)
  end

  def self.expire_overdue_trials!
    trials.where('trial_ends_at < ? AND status = ?', Time.current, 'active').find_each(&:expire!)
  end

  def self.expire_overdue_licenses!
    where('expires_at < ? AND status = ?', Time.current, 'active').find_each(&:expire!)
  end

  # Webhook data
  def webhook_data
    {
      id: id,
      account_id: account_id,
      license_type: license_type,
      status: status,
      monthly_lead_limit: monthly_lead_limit,
      monthly_lead_usage: monthly_lead_usage,
      expires_at: expires_at&.iso8601,
      trial_ends_at: trial_ends_at&.iso8601
    }
  end

  # Para exibição
  def display_name
    "#{account.name} - #{license_type.titleize}"
  end

  def status_badge
    case status
    when 'active' then 'success'
    when 'suspended' then 'warning'
    when 'expired', 'cancelled' then 'danger'
    else 'secondary'
    end
  end

  private

  def set_defaults
    defaults = LICENSE_DEFAULTS[license_type] || LICENSE_DEFAULTS['trial']

    self.monthly_lead_limit ||= defaults[:monthly_lead_limit]
    self.max_inboxes ||= defaults[:max_inboxes]
    self.max_agents ||= defaults[:max_agents]
    self.allowed_models ||= defaults[:allowed_models]
    self.custom_prompts_enabled = defaults[:custom_prompts_enabled] if custom_prompts_enabled.nil?
    self.api_access_enabled = defaults[:api_access_enabled] if api_access_enabled.nil?
    self.knowledge_base_enabled = defaults[:knowledge_base_enabled] if knowledge_base_enabled.nil?
    self.round_robin_enabled = defaults[:round_robin_enabled] if round_robin_enabled.nil?
    self.audio_transcription_enabled = defaults[:audio_transcription_enabled] if audio_transcription_enabled.nil?
    self.started_at ||= Time.current
    self.usage_reset_at ||= Time.current
  end

  def generate_license_key
    self.license_key ||= "SDRIA-#{SecureRandom.hex(4).upcase}-#{SecureRandom.hex(4).upcase}-#{SecureRandom.hex(4).upcase}"
  end

  def set_trial_period
    defaults = LICENSE_DEFAULTS['trial']
    self.trial_ends_at ||= Time.current + defaults[:trial_days].days
  end

  def check_expiration
    return unless saved_change_to_expires_at? || saved_change_to_trial_ends_at?

    expire! if expired? || trial_expired?
  end
end

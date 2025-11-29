# frozen_string_literal: true

require 'administrate/base_dashboard'

class SdrIaLicenseDashboard < Administrate::BaseDashboard
  # Tipos de atributos para exibição
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo.with_options(searchable: true, searchable_field: 'name'),
    license_type: Field::Select.with_options(
      collection: SdrIaLicense::LICENSE_TYPES.map { |t| [t.titleize, t] }
    ),
    license_key: Field::String,
    status: Field::Select.with_options(
      collection: SdrIaLicense::STATUS_TYPES.map { |s| [s.titleize, s] }
    ),
    started_at: Field::DateTime,
    expires_at: Field::DateTime,
    trial_ends_at: Field::DateTime,
    monthly_lead_limit: Field::Number,
    monthly_lead_usage: Field::Number,
    usage_reset_at: Field::DateTime,
    max_inboxes: Field::Number,
    max_agents: Field::Number,
    allowed_models: Field::String.with_options(searchable: false),
    custom_prompts_enabled: Field::Boolean,
    api_access_enabled: Field::Boolean,
    knowledge_base_enabled: Field::Boolean,
    round_robin_enabled: Field::Boolean,
    audio_transcription_enabled: Field::Boolean,
    suspension_reason: Field::Text,
    suspended_at: Field::DateTime,
    stripe_customer_id: Field::String,
    stripe_subscription_id: Field::String,
    billing_email: Field::Email,
    activation_url: Field::String.with_options(searchable: false),
    notes: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # Atributos exibidos na listagem
  COLLECTION_ATTRIBUTES = %i[
    id
    account
    license_type
    status
    monthly_lead_usage
    monthly_lead_limit
    expires_at
  ].freeze

  # Atributos exibidos na página de detalhes
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    account
    license_key
    license_type
    status
    started_at
    expires_at
    trial_ends_at
    monthly_lead_limit
    monthly_lead_usage
    usage_reset_at
    max_inboxes
    max_agents
    allowed_models
    custom_prompts_enabled
    api_access_enabled
    knowledge_base_enabled
    round_robin_enabled
    audio_transcription_enabled
    suspension_reason
    suspended_at
    stripe_customer_id
    stripe_subscription_id
    billing_email
    activation_url
    notes
    created_at
    updated_at
  ].freeze

  # Atributos do formulário de criação/edição
  FORM_ATTRIBUTES = %i[
    account
    license_type
    status
    expires_at
    trial_ends_at
    monthly_lead_limit
    monthly_lead_usage
    max_inboxes
    max_agents
    custom_prompts_enabled
    api_access_enabled
    knowledge_base_enabled
    round_robin_enabled
    audio_transcription_enabled
    activation_url
    suspension_reason
    billing_email
    notes
  ].freeze

  # Filtros disponíveis na listagem
  COLLECTION_FILTERS = {
    active: ->(resources) { resources.where(status: 'active') },
    suspended: ->(resources) { resources.where(status: 'suspended') },
    expired: ->(resources) { resources.where(status: 'expired') },
    trial: ->(resources) { resources.where(license_type: 'trial') },
    basic: ->(resources) { resources.where(license_type: 'basic') },
    pro: ->(resources) { resources.where(license_type: 'pro') },
    enterprise: ->(resources) { resources.where(license_type: 'enterprise') },
    expiring_soon: ->(resources) { resources.where('expires_at <= ? AND status = ?', 7.days.from_now, 'active') },
    trial_expiring: ->(resources) { resources.where('trial_ends_at <= ? AND license_type = ?', 3.days.from_now, 'trial') },
    usage_high: ->(resources) { resources.where('monthly_lead_usage >= monthly_lead_limit * 0.8') }
  }.freeze

  def display_resource(license)
    "#{license.account&.name || 'N/A'} - #{license.license_type.titleize}"
  end
end

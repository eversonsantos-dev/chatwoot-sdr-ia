# frozen_string_literal: true

require 'administrate/base_dashboard'

class SdrIaLicenseDashboard < Administrate::BaseDashboard
  # Definir constantes localmente para evitar erro de carregamento
  LICENSE_TYPES = %w[trial basic pro enterprise].freeze
  STATUS_TYPES = %w[active suspended expired cancelled].freeze

  # Tipos de atributos para exibição
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo.with_options(searchable: true, searchable_field: 'name'),
    license_type: Field::Select.with_options(
      collection: LICENSE_TYPES.map { |t| [t.titleize, t] }
    ),
    license_key: Field::String,
    status: Field::Select.with_options(
      collection: STATUS_TYPES.map { |s| [s.titleize, s] }
    ),
    started_at: Field::DateTime,
    expires_at: Field::DateTime,
    trial_ends_at: Field::DateTime,
    monthly_lead_limit: Field::Number,
    monthly_lead_usage: Field::Number,
    usage_reset_at: Field::DateTime,
    max_inboxes: Field::Number,
    max_agents: Field::Number,
    custom_prompts_enabled: Field::Boolean,
    api_access_enabled: Field::Boolean,
    knowledge_base_enabled: Field::Boolean,
    round_robin_enabled: Field::Boolean,
    audio_transcription_enabled: Field::Boolean,
    suspension_reason: Field::Text,
    suspended_at: Field::DateTime,
    stripe_customer_id: Field::String,
    stripe_subscription_id: Field::String,
    billing_email: Field::String,
    activation_url: Field::String,
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
  COLLECTION_FILTERS = {}.freeze

  def display_resource(license)
    "Licença ##{license.id}"
  end
end

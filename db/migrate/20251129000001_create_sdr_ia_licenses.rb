# frozen_string_literal: true

class CreateSdrIaLicenses < ActiveRecord::Migration[7.0]
  def change
    create_table :sdr_ia_licenses do |t|
      # Relacionamento com Account
      t.references :account, null: false, foreign_key: true, index: { unique: true }

      # Tipo de Licença
      t.string :license_type, null: false, default: 'trial'
      t.string :license_key, index: { unique: true }

      # Período
      t.datetime :started_at
      t.datetime :expires_at
      t.datetime :trial_ends_at

      # Limites de Uso
      t.integer :monthly_lead_limit, default: 50
      t.integer :monthly_lead_usage, default: 0
      t.datetime :usage_reset_at
      t.integer :max_inboxes, default: 1
      t.integer :max_agents, default: 1

      # Configurações de Modelo OpenAI
      t.string :allowed_models, array: true, default: ['gpt-3.5-turbo']
      t.boolean :custom_prompts_enabled, default: false
      t.boolean :api_access_enabled, default: false
      t.boolean :knowledge_base_enabled, default: false
      t.boolean :round_robin_enabled, default: false
      t.boolean :audio_transcription_enabled, default: false

      # Status
      t.string :status, null: false, default: 'active'
      t.text :suspension_reason
      t.datetime :suspended_at

      # Billing (opcional - para integração futura com Stripe)
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.string :billing_email

      # Metadata
      t.jsonb :metadata, default: {}
      t.text :notes

      t.timestamps
    end

    # Índices adicionais
    add_index :sdr_ia_licenses, :license_type
    add_index :sdr_ia_licenses, :status
    add_index :sdr_ia_licenses, :expires_at
    add_index :sdr_ia_licenses, :trial_ends_at
  end
end

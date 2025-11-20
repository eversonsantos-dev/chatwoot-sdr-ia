# frozen_string_literal: true

class CreateSdrIaConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :sdr_ia_configs do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }

      # Configurações gerais
      t.boolean :enabled, default: true
      t.boolean :debug_mode, default: false

      # OpenAI
      t.string :openai_api_key  # Criptografado
      t.string :openai_model, default: 'gpt-4-turbo-preview'
      t.integer :openai_max_tokens, default: 2000
      t.float :openai_temperature, default: 0.3

      # Scoring weights (JSON)
      t.jsonb :scoring_weights, default: {
        urgencia: {
          esta_semana: 30,
          proximas_2_semanas: 25,
          ate_30_dias: 15,
          acima_30_dias: 5,
          pesquisando: 0
        },
        conhecimento: {
          conhece_valores: 25,
          tem_duvidas: 15,
          primeira_pesquisa: 5
        },
        interesse_definido: 20,
        motivacao_clara: 20
      }

      # Temperature thresholds
      t.integer :threshold_quente, default: 70
      t.integer :threshold_morno, default: 40
      t.integer :threshold_frio, default: 20
      t.integer :threshold_muito_frio, default: 0

      # Team assignment
      t.integer :quente_team_id
      t.integer :morno_team_id

      # Procedimentos (array)
      t.jsonb :procedimentos, default: [
        'Harmonização Facial',
        'Emagrecimento',
        'Cabelo',
        'Botox',
        'Pele'
      ]

      # Reconduzir settings
      t.integer :max_tentativas_reconduzir, default: 3
      t.integer :delay_reconduzir_segundos, default: 2

      t.timestamps
    end
  end
end

# frozen_string_literal: true

# Migration ÚNICA e consolidada para SDR IA
# Esta migration cria TODAS as colunas necessárias
class CreateSdrIaConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :sdr_ia_configs do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }

      # === Configurações Gerais ===
      t.boolean :enabled, default: true
      t.boolean :debug_mode, default: false

      # === OpenAI ===
      t.string :openai_api_key
      t.string :openai_model, default: 'gpt-4-turbo-preview'
      t.integer :openai_max_tokens, default: 2000
      t.float :openai_temperature, default: 0.3

      # === Scoring Weights ===
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

      # === Temperature Thresholds ===
      t.integer :threshold_quente, default: 70
      t.integer :threshold_morno, default: 40
      t.integer :threshold_frio, default: 20
      t.integer :threshold_muito_frio, default: 0

      # === Team Assignment ===
      t.integer :quente_team_id
      t.integer :morno_team_id

      # === Procedimentos ===
      t.jsonb :procedimentos, default: [
        'Harmonização Facial',
        'Emagrecimento',
        'Cabelo',
        'Botox',
        'Pele'
      ]

      # === Prompts ===
      t.text :prompt_system, default: "Você é um SDR virtual. Qualifique leads com empatia."
      t.text :prompt_analysis, default: "Analise a conversa e retorne JSON com qualificação."

      # === Perguntas por Etapa ===
      t.jsonb :perguntas_etapas, default: {
        nome: "Qual é o seu nome?",
        interesse: "Qual procedimento você tem interesse?",
        urgencia: "Para quando você está pensando em fazer?",
        conhecimento: "Você já pesquisou sobre valores?",
        motivacao: "Qual é o seu principal objetivo?",
        localizacao: "De qual região você é?"
      }

      # === Recondução ===
      t.integer :max_tentativas_reconduzir, default: 3
      t.integer :delay_reconduzir_segundos, default: 2

      # === Configurações da Clínica ===
      t.string :default_agent_email
      t.string :clinic_name, default: 'Minha Clínica'
      t.string :ai_name, default: 'Assistente IA'
      t.text :clinic_address

      # === Knowledge Base ===
      t.text :knowledge_base, default: ''

      # === Round Robin ===
      t.boolean :enable_round_robin, default: false
      t.jsonb :round_robin_closers, default: []
      t.integer :last_assigned_closer_index, default: -1
      t.string :round_robin_strategy, default: 'sequential'

      t.timestamps
    end
  end
end

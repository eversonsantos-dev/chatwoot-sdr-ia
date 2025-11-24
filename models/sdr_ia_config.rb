# frozen_string_literal: true

class SdrIaConfig < ApplicationRecord
  belongs_to :account

  validates :account_id, uniqueness: true

  # Retorna configuração para uma conta (cria se não existir)
  def self.for_account(account)
    find_or_create_by(account: account)
  end

  # Retorna hash de configuração no formato esperado pelo sistema
  def to_config_hash
    {
      'sdr_ia' => {
        'enabled' => enabled,
        'debug_mode' => debug_mode,
        'default_agent_email' => default_agent_email,
        'clinic_name' => clinic_name,
        'ai_name' => ai_name,
        'clinic_address' => clinic_address,
        'knowledge_base' => knowledge_base,
        'openai' => {
          'api_key' => openai_api_key,
          'model' => openai_model,
          'max_tokens' => openai_max_tokens,
          'temperature' => openai_temperature
        },
        'prompts' => {
          'system' => prompt_system,
          'analysis' => prompt_analysis
        },
        'perguntas_etapas' => perguntas_etapas,
        'scoring' => {
          'weights' => scoring_weights.deep_symbolize_keys
        },
        'temperature_thresholds' => {
          'quente' => threshold_quente,
          'morno' => threshold_morno,
          'frio' => threshold_frio,
          'muito_frio' => threshold_muito_frio
        },
        'teams' => {
          'quente_team_id' => quente_team_id,
          'morno_team_id' => morno_team_id
        },
        'procedimentos' => procedimentos,
        'reconduzir' => {
          'max_tentativas' => max_tentativas_reconduzir,
          'delay_segundos' => delay_reconduzir_segundos
        },
        'round_robin' => {
          'enabled' => enable_round_robin,
          'strategy' => round_robin_strategy,
          'closers' => round_robin_closers || []
        }
      }
    }
  end

  # Atualiza a partir de um hash de parâmetros do frontend
  def update_from_params(params)
    update(
      enabled: params.dig(:sdr_ia, :enabled),
      debug_mode: params.dig(:sdr_ia, :debug_mode),
      default_agent_email: params.dig(:sdr_ia, :default_agent_email),
      clinic_name: params.dig(:sdr_ia, :clinic_name),
      ai_name: params.dig(:sdr_ia, :ai_name),
      clinic_address: params.dig(:sdr_ia, :clinic_address),
      knowledge_base: params.dig(:sdr_ia, :knowledge_base),
      openai_api_key: params.dig(:sdr_ia, :openai, :api_key),
      openai_model: params.dig(:sdr_ia, :openai, :model),
      openai_max_tokens: params.dig(:sdr_ia, :openai, :max_tokens),
      openai_temperature: params.dig(:sdr_ia, :openai, :temperature),
      prompt_system: params.dig(:sdr_ia, :prompts, :system),
      prompt_analysis: params.dig(:sdr_ia, :prompts, :analysis),
      perguntas_etapas: params.dig(:sdr_ia, :perguntas_etapas),
      scoring_weights: params.dig(:sdr_ia, :scoring, :weights),
      threshold_quente: params.dig(:sdr_ia, :temperature_thresholds, :quente),
      threshold_morno: params.dig(:sdr_ia, :temperature_thresholds, :morno),
      threshold_frio: params.dig(:sdr_ia, :temperature_thresholds, :frio),
      threshold_muito_frio: params.dig(:sdr_ia, :temperature_thresholds, :muito_frio),
      quente_team_id: params.dig(:sdr_ia, :teams, :quente_team_id),
      morno_team_id: params.dig(:sdr_ia, :teams, :morno_team_id),
      procedimentos: params.dig(:sdr_ia, :procedimentos),
      max_tentativas_reconduzir: params.dig(:sdr_ia, :reconduzir, :max_tentativas),
      delay_reconduzir_segundos: params.dig(:sdr_ia, :reconduzir, :delay_segundos),
      enable_round_robin: params.dig(:sdr_ia, :round_robin, :enabled),
      round_robin_strategy: params.dig(:sdr_ia, :round_robin, :strategy),
      round_robin_closers: params.dig(:sdr_ia, :round_robin, :closers)
    )
  end
end

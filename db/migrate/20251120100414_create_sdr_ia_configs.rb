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

      # Prompts configuráveis (textos grandes)
      t.text :prompt_system, default: "Você é um SDR (Sales Development Representative) virtual de uma clínica de estética.\nSeu objetivo é qualificar leads através de conversas naturais no WhatsApp.\n\nREGRAS CRÍTICAS:\n1. NUNCA pule etapas - sempre complete as 6 perguntas\n2. Seja gentil, empático e profissional\n3. Se o lead fugir do assunto, reconduza educadamente (máximo 3 tentativas)\n4. Sempre retome o contexto se o lead voltar depois de pausas\n5. Não desqualifique sem tentar coletar todas as informações\n\nPERGUNTAS OBRIGATÓRIAS (nesta ordem):\n1. Nome do lead\n2. Interesse específico (tipo de procedimento)\n3. Urgência/timing (quando quer fazer)\n4. Conhecimento de mercado (já pesquisou?)\n5. Motivação/objetivo (por que quer fazer)\n6. Localização (bairro/cidade)"

      t.text :prompt_analysis, default: "Analise a conversa completa abaixo e extraia as informações de qualificação do lead.\n\nCONVERSA:\n{conversation_history}\n\nRESPONDA APENAS COM JSON VÁLIDO (sem markdown, sem explicações):\n{\n  \"status_qualificacao\": \"completo|incompleto|em_andamento\",\n  \"progresso\": \"1/6|2/6|3/6|4/6|5/6|6/6\",\n  \"dados_coletados\": {\n    \"nome\": \"string ou null\",\n    \"interesse\": \"string ou null\",\n    \"urgencia\": \"esta_semana|proximas_2_semanas|ate_30_dias|acima_30_dias|pesquisando|null\",\n    \"conhecimento\": \"conhece_valores|tem_duvidas|primeira_pesquisa|null\",\n    \"motivacao\": \"string ou null\",\n    \"localizacao\": \"string ou null\"\n  },\n  \"score_calculado\": 0,\n  \"temperatura\": \"quente|morno|frio|muito_frio\",\n  \"tags_sugeridas\": [],\n  \"lead_comportamento\": \"cooperativo|evasivo|resistente\",\n  \"proximo_passo\": \"continuar_qualificacao|transferir_closer|agendar_followup|marcar_frio\",\n  \"resumo_para_closer\": \"string\"\n}"

      # Perguntas personalizadas para cada etapa
      t.jsonb :perguntas_etapas, default: {
        nome: "Qual é o seu nome?",
        interesse: "Qual procedimento você tem interesse?",
        urgencia: "Para quando você está pensando em fazer?",
        conhecimento: "Você já pesquisou sobre valores?",
        motivacao: "Qual é o seu principal objetivo com esse procedimento?",
        localizacao: "De qual região/bairro você é?"
      }

      # Reconduzir settings
      t.integer :max_tentativas_reconduzir, default: 3
      t.integer :delay_reconduzir_segundos, default: 2

      t.timestamps
    end
  end
end

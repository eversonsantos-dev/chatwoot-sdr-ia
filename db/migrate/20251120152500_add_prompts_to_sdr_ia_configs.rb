# frozen_string_literal: true

class AddPromptsToSdrIaConfigs < ActiveRecord::Migration[7.0]
  def change
    # Adicionar campos de prompts
    add_column :sdr_ia_configs, :prompt_system, :text, default: "Você é um SDR (Sales Development Representative) virtual de uma clínica de estética.\nSeu objetivo é qualificar leads através de conversas naturais no WhatsApp.\n\nREGRAS CRÍTICAS:\n1. NUNCA pule etapas - sempre complete as 6 perguntas\n2. Seja gentil, empático e profissional\n3. Se o lead fugir do assunto, reconduza educadamente (máximo 3 tentativas)\n4. Sempre retome o contexto se o lead voltar depois de pausas\n5. Não desqualifique sem tentar coletar todas as informações\n\nPERGUNTAS OBRIGATÓRIAS (nesta ordem):\n1. Nome do lead\n2. Interesse específico (tipo de procedimento)\n3. Urgência/timing (quando quer fazer)\n4. Conhecimento de mercado (já pesquisou?)\n5. Motivação/objetivo (por que quer fazer)\n6. Localização (bairro/cidade)"

    add_column :sdr_ia_configs, :prompt_analysis, :text, default: "Analise a conversa completa abaixo e extraia as informações de qualificação do lead.\n\nCONVERSA:\n{conversation_history}\n\nRESPONDA APENAS COM JSON VÁLIDO (sem markdown, sem explicações):\n{\n  \"status_qualificacao\": \"completo|incompleto|em_andamento\",\n  \"progresso\": \"1/6|2/6|3/6|4/6|5/6|6/6\",\n  \"dados_coletados\": {\n    \"nome\": \"string ou null\",\n    \"interesse\": \"string ou null\",\n    \"urgencia\": \"esta_semana|proximas_2_semanas|ate_30_dias|acima_30_dias|pesquisando|null\",\n    \"conhecimento\": \"conhece_valores|tem_duvidas|primeira_pesquisa|null\",\n    \"motivacao\": \"string ou null\",\n    \"localizacao\": \"string ou null\"\n  },\n  \"score_calculado\": 0,\n  \"temperatura\": \"quente|morno|frio|muito_frio\",\n  \"tags_sugeridas\": [],\n  \"lead_comportamento\": \"cooperativo|evasivo|resistente\",\n  \"proximo_passo\": \"continuar_qualificacao|transferir_closer|agendar_followup|marcar_frio\",\n  \"resumo_para_closer\": \"string\"\n}"

    # Adicionar perguntas personalizadas para cada etapa
    add_column :sdr_ia_configs, :perguntas_etapas, :jsonb, default: {
      nome: "Qual é o seu nome?",
      interesse: "Qual procedimento você tem interesse?",
      urgencia: "Para quando você está pensando em fazer?",
      conhecimento: "Você já pesquisou sobre valores?",
      motivacao: "Qual é o seu principal objetivo com esse procedimento?",
      localizacao: "De qual região/bairro você é?"
    }
  end
end

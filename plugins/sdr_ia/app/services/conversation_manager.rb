# frozen_string_literal: true

module SdrIa
  class ConversationManager
    attr_reader :contact, :conversation, :config, :license_validator

    PERGUNTAS = %w[nome interesse urgencia conhecimento motivacao localizacao].freeze

    def initialize(contact:, conversation:, account: nil)
      @contact = contact
      @conversation = conversation
      @account = account || contact.account
      @config = SdrIa.config(@account)
      @perguntas_config = @config.dig('perguntas_etapas') || load_perguntas_from_yaml
      @license_validator = LicenseValidator.new(@account)
    end

    def process_message!
      Rails.logger.info "[SDR IA] Processando mensagem do contact #{contact.id}"

      # Validar licença antes de processar
      unless validate_license!
        Rails.logger.warn "[SDR IA] Licença inválida ou limite atingido para account #{@account.id}"
        return
      end

      # Inicializar ou avançar progresso
      current_step = get_current_step

      if current_step.zero?
        # Primeira interação - enviar boas-vindas e primeira pergunta
        send_welcome_message
      else
        # Salvar resposta da pergunta anterior
        save_answer(current_step - 1)

        # Verificar se completou todas as perguntas
        if current_step >= PERGUNTAS.length
          # Todas as perguntas respondidas - fazer qualificação final
          qualify_lead
        else
          # Enviar próxima pergunta
          send_next_question(current_step)
        end
      end
    rescue LicenseError => e
      Rails.logger.warn "[SDR IA] Erro de licença: #{e.message}"
      handle_license_error(e)
    rescue StandardError => e
      Rails.logger.error "[SDR IA] Erro ao processar mensagem: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end

    # Verifica se a conta pode processar leads
    def can_process?
      license_validator.can_process_lead?
    end

    # Retorna informações de uso da licença
    def usage_info
      license_validator.usage_info
    end

    private

    def get_current_step
      progresso = contact.custom_attributes['sdr_ia_progresso'] || '0/6'
      progresso.split('/').first.to_i
    end

    def update_progress(step)
      contact.custom_attributes['sdr_ia_progresso'] = "#{step}/#{PERGUNTAS.length}"
      contact.save!
      Rails.logger.info "[SDR IA] Progresso atualizado: #{step}/#{PERGUNTAS.length}"
    end

    def send_welcome_message
      mensagem_boas_vindas = @config.dig('mensagens', 'boas_vindas') ||
                             "Olá! Sou o assistente virtual e vou te ajudar. Vou fazer algumas perguntas rápidas para entender melhor como posso ajudar você."

      send_message(mensagem_boas_vindas)
      sleep 1
      send_next_question(0)
    end

    def send_next_question(step_index)
      pergunta_key = PERGUNTAS[step_index]
      pergunta_texto = @perguntas_config[pergunta_key] || "Pergunta #{step_index + 1}"

      send_message(pergunta_texto)
      update_progress(step_index + 1)
    end

    def save_answer(step_index)
      # Pega a última mensagem do lead
      last_message = conversation.messages
        .where(message_type: :incoming)
        .where.not(content: nil)
        .order(created_at: :desc)
        .first

      return unless last_message

      pergunta_key = PERGUNTAS[step_index]
      contact.custom_attributes["sdr_ia_resposta_#{pergunta_key}"] = last_message.content
      contact.save!

      Rails.logger.info "[SDR IA] Resposta salva para #{pergunta_key}: #{last_message.content[0..50]}..."
    end

    def qualify_lead
      Rails.logger.info "[SDR IA] Todas as perguntas respondidas. Iniciando qualificação..."

      # Coletar todas as respostas
      respostas = {}
      PERGUNTAS.each do |pergunta_key|
        respostas[pergunta_key] = contact.custom_attributes["sdr_ia_resposta_#{pergunta_key}"]
      end

      # Montar conversa completa para análise
      mensagens = []
      PERGUNTAS.each_with_index do |pergunta_key, index|
        pergunta = @perguntas_config[pergunta_key]
        resposta = respostas[pergunta_key]

        mensagens << "Atendente: #{pergunta}"
        mensagens << "Lead: #{resposta}" if resposta
      end

      # Analisar com IA
      conversation_text = mensagens.join("\n")
      prompts = @config['prompts'] || {}

      client = OpenaiClient.new(@account)
      analysis = client.analyze_conversation(
        conversation_text,
        prompts['system'] || 'Você é um SDR virtual.',
        prompts['analysis'] || 'Analise a conversa e qualifique o lead.'
      )

      if analysis
        # Atualizar contact com análise
        update_contact_with_analysis(analysis)

        # Enviar mensagem de encerramento
        send_closing_message(analysis)

        # Aplicar labels e atribuir time se necessário
        apply_labels(analysis['tags_sugeridas']) if analysis['tags_sugeridas']
        assign_to_team(analysis) if should_assign_to_team?(analysis)

        # Incrementar uso da licença (apenas após qualificação bem-sucedida)
        increment_license_usage!

        Rails.logger.info "[SDR IA] Qualificação completa: #{analysis['temperatura']} - Score: #{analysis['score']}"
      else
        Rails.logger.error "[SDR IA] Falha na análise da IA"
        send_message("Obrigado pelas respostas! Em breve um de nossos especialistas entrará em contato.")
      end
    end

    def update_contact_with_analysis(analysis)
      contact.custom_attributes.merge!({
        'sdr_ia_status' => 'qualificado',
        'sdr_ia_temperatura' => analysis['temperatura'],
        'sdr_ia_score' => analysis['score'],
        'sdr_ia_nome' => analysis['nome'],
        'sdr_ia_interesse' => analysis['interesse'],
        'sdr_ia_urgencia' => analysis['urgencia'],
        'sdr_ia_conhecimento' => analysis['conhecimento'],
        'sdr_ia_motivacao' => analysis['motivacao'],
        'sdr_ia_localizacao' => analysis['localizacao'],
        'sdr_ia_comportamento' => analysis['comportamento'],
        'sdr_ia_resumo' => analysis['resumo'],
        'sdr_ia_proximo_passo' => analysis['proximo_passo'],
        'sdr_ia_qualificado_em' => Time.current.iso8601,
        'sdr_ia_progresso' => '6/6'
      })

      contact.save!
      Rails.logger.info "[SDR IA] Contact #{contact.id} qualificado com sucesso"
    end

    def send_closing_message(analysis)
      temperatura = analysis['temperatura']

      mensagem = case temperatura
                 when 'quente'
                   @config.dig('mensagens', 'quente') ||
                   "Ótimo! Identifiquei que você tem grande interesse. Um especialista entrará em contato em breve!"
                 when 'morno'
                   @config.dig('mensagens', 'morno') ||
                   "Obrigado pelas informações! Vou direcionar você para nossa equipe que poderá ajudar melhor."
                 when 'frio', 'muito_frio'
                   @config.dig('mensagens', 'frio') ||
                   "Obrigado pelo seu tempo! Vou registrar suas informações e retornaremos em breve."
                 else
                   "Obrigado pelas respostas!"
                 end

      send_message(mensagem)
    end

    def send_message(content)
      # Tenta usar o agente padrão configurado (ex: Pedro Zoia)
      default_agent_email = @config.dig('default_agent_email')
      sender = nil

      if default_agent_email.present?
        sender = @account.users.find_by(email: default_agent_email)
        Rails.logger.info "[SDR IA] Usando agente padrão: #{default_agent_email}" if sender
      end

      # Fallback: assignee ou primeiro usuário da conta
      sender ||= conversation.assignee || @account.users.first

      message = conversation.messages.create!(
        account: @account,
        inbox: conversation.inbox,
        message_type: :outgoing,
        content: content,
        sender: sender
      )

      Rails.logger.info "[SDR IA] Mensagem enviada por #{sender.email}: #{content[0..50]}..."
      message
    rescue StandardError => e
      Rails.logger.error "[SDR IA] Erro ao enviar mensagem: #{e.message}"
      Rails.logger.error e.backtrace.join("\n") if e.backtrace
      nil
    end

    def apply_labels(tag_names)
      return unless tag_names.is_a?(Array)

      tag_names.each do |tag_name|
        label = @account.labels.find_by(title: tag_name)
        next unless label

        unless contact.labels.include?(label)
          contact.labels << label
          Rails.logger.info "[SDR IA] Label '#{tag_name}' aplicada"
        end
      end
    rescue StandardError => e
      Rails.logger.error "[SDR IA] Erro ao aplicar labels: #{e.message}"
    end

    def should_assign_to_team?(analysis)
      ['quente', 'morno'].include?(analysis['temperatura']) &&
        analysis['proximo_passo'] == 'transferir_closer'
    end

    def assign_to_team(analysis)
      team_id = case analysis['temperatura']
                when 'quente'
                  @config.dig('teams', 'quente_team_id')
                when 'morno'
                  @config.dig('teams', 'morno_team_id')
                end

      return unless team_id

      team = Team.find_by(id: team_id)
      return unless team

      conversation.update!(team_id: team_id)
      Rails.logger.info "[SDR IA] Lead atribuído para time #{team.name}"
    rescue StandardError => e
      Rails.logger.error "[SDR IA] Erro ao atribuir time: #{e.message}"
    end

    def load_perguntas_from_yaml
      yaml_data = YAML.load_file(Rails.root.join('plugins/sdr_ia/config/prompts.yml'))
      yaml_data['perguntas_etapas'] || {}
    rescue StandardError => e
      Rails.logger.error "[SDR IA] Erro ao carregar perguntas YAML: #{e.message}"
      {}
    end

    # ============================================
    # Métodos de Validação de Licença
    # ============================================

    def validate_license!
      return true unless license_validation_enabled?

      license_validator.validate!
      true
    rescue LicenseError
      false
    end

    def license_validation_enabled?
      # Permite desabilitar validação de licença via variável de ambiente (para desenvolvimento)
      ENV['SDR_IA_SKIP_LICENSE_CHECK'] != 'true'
    end

    def handle_license_error(error)
      case error
      when TrialExpiredError
        send_license_expired_message(:trial)
      when LicenseExpiredError
        send_license_expired_message(:license)
      when UsageLimitError
        send_usage_limit_message
      when LicenseSuspendedError
        Rails.logger.warn "[SDR IA] Conta suspensa: #{error.message}"
      else
        Rails.logger.warn "[SDR IA] Erro de licença não tratado: #{error.message}"
      end
    end

    def send_license_expired_message(type)
      # Não enviar mensagem ao cliente sobre problemas internos
      # Apenas registrar no log
      message = type == :trial ? 'Período de teste expirado' : 'Licença expirada'
      Rails.logger.warn "[SDR IA] #{message} para account #{@account.id}"

      # Atualizar status do contato
      contact.custom_attributes['sdr_ia_status'] = 'licenca_expirada'
      contact.save!
    end

    def send_usage_limit_message
      Rails.logger.warn "[SDR IA] Limite de uso atingido para account #{@account.id}"

      # Atualizar status do contato
      contact.custom_attributes['sdr_ia_status'] = 'limite_atingido'
      contact.save!
    end

    # Incrementar uso após qualificação bem-sucedida
    def increment_license_usage!
      return unless license_validation_enabled?

      license_validator.increment_usage!
      Rails.logger.info "[SDR IA] Uso incrementado para account #{@account.id}"
    rescue StandardError => e
      Rails.logger.error "[SDR IA] Erro ao incrementar uso: #{e.message}"
    end

    # Verificar se modelo OpenAI é permitido pela licença
    def get_allowed_openai_model
      requested_model = @config.dig('openai', 'model') || 'gpt-3.5-turbo'
      license_validator.get_allowed_model(requested_model)
    end
  end
end

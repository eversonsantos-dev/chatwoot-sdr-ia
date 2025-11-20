# frozen_string_literal: true

module SdrIa
  class ConversationManagerV2
    attr_reader :contact, :conversation, :config

    MAX_MESSAGES_IN_QUALIFICATION = 15 # Máximo de mensagens antes de forçar qualificação

    def initialize(contact:, conversation:, account: nil)
      @contact = contact
      @conversation = conversation
      @account = account || contact.account
      @config = SdrIa.config(@account)
    end

    def process_message!
      Rails.logger.info "[SDR IA] [V2] Processando mensagem do contact #{contact.id}"

      # Verificar se já está qualificado
      if already_qualified?
        Rails.logger.info "[SDR IA] [V2] Contact já qualificado, ignorando"
        return
      end

      # Obter histórico da conversa
      history = build_conversation_history

      # Verificar se deve qualificar (muitas mensagens ou sinais claros)
      if should_qualify_now?(history)
        Rails.logger.info "[SDR IA] [V2] Iniciando qualificação final..."
        qualify_lead(history)
      else
        # Gerar resposta conversacional
        generate_conversational_response(history)
      end
    rescue StandardError => e
      Rails.logger.error "[SDR IA] [V2] Erro ao processar mensagem: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end

    private

    def already_qualified?
      contact.custom_attributes['sdr_ia_status'] == 'qualificado'
    end

    def build_conversation_history
      messages = conversation.messages
        .where.not(content: nil)
        .where.not(content: '')
        .order(created_at: :asc)
        .limit(30) # Últimas 30 mensagens
        .pluck(:message_type, :content, :created_at)

      history = []
      messages.each do |msg_type, content, created_at|
        role = msg_type == 'incoming' ? 'user' : 'assistant'
        history << {
          role: role,
          content: content,
          timestamp: created_at
        }
      end

      history
    end

    def should_qualify_now?(history)
      # Contar apenas mensagens do lead (incoming)
      lead_messages_count = history.count { |msg| msg[:role] == 'user' }

      # Qualificar se:
      # 1. Já trocou muitas mensagens (>= 8 mensagens do lead)
      # 2. Lead disse explicitamente que quer finalizar/falar com humano
      last_message = history.last[:content].to_s.downcase if history.last

      lead_messages_count >= 8 ||
        last_message&.include?('falar com') ||
        last_message&.include?('atendente') ||
        last_message&.include?('humano') ||
        last_message&.include?('pessoa')
    end

    def generate_conversational_response(history)
      client = OpenaiClient.new(@account)
      system_prompt = get_conversational_system_prompt

      # Gerar resposta usando OpenAI
      response = client.generate_response(history, system_prompt)

      if response.present?
        send_message(response)
        Rails.logger.info "[SDR IA] [V2] Resposta conversacional enviada"
      else
        Rails.logger.error "[SDR IA] [V2] Falha ao gerar resposta, usando fallback"
        send_message("Desculpe, tive um problema técnico. Pode repetir?")
      end
    rescue StandardError => e
      Rails.logger.error "[SDR IA] [V2] Erro ao gerar resposta conversacional: #{e.message}"
      # Não envia nada em caso de erro para não spammar
    end

    def qualify_lead(history)
      Rails.logger.info "[SDR IA] [V2] Qualificando lead com #{history.length} mensagens..."

      # Montar conversa completa para análise
      conversation_text = history.map do |msg|
        role_label = msg[:role] == 'user' ? 'Lead' : 'Atendente'
        "#{role_label}: #{msg[:content]}"
      end.join("\n")

      # Analisar com IA
      prompts = @config['prompts'] || {}
      client = OpenaiClient.new(@account)

      analysis = client.analyze_conversation(
        conversation_text,
        prompts['system'] || get_fallback_system_prompt,
        prompts['analysis'] || get_fallback_analysis_prompt
      )

      if analysis
        # Atualizar contact com análise
        update_contact_with_analysis(analysis)

        # Enviar mensagem de encerramento
        send_closing_message(analysis)

        # Aplicar labels e atribuir time se necessário
        apply_labels(analysis['tags_sugeridas']) if analysis['tags_sugeridas']
        assign_to_team(analysis) if should_assign_to_team?(analysis)

        Rails.logger.info "[SDR IA] [V2] Qualificação completa: #{analysis['temperatura']} - Score: #{analysis['score']}"
      else
        Rails.logger.error "[SDR IA] [V2] Falha na análise da IA"
        send_message("Obrigado pelas informações! Nossa equipe entrará em contato em breve.")
      end
    end

    def get_conversational_system_prompt
      # Usar prompt do banco ou fallback para o novo prompt conversacional
      @config.dig('prompts', 'system') || read_prompts_from_file['system']
    end

    def get_fallback_system_prompt
      'Você é um SDR virtual qualificando leads de clínica de estética.'
    end

    def get_fallback_analysis_prompt
      'Analise a conversa e retorne JSON com: nome, interesse, urgencia, conhecimento, motivacao, localizacao, score, temperatura.'
    end

    def read_prompts_from_file
      file_path = Rails.root.join('plugins/sdr_ia/config/prompts_new.yml')
      if File.exist?(file_path)
        yaml_data = YAML.load_file(file_path)
        yaml_data['prompts'] || {}
      else
        {}
      end
    rescue StandardError => e
      Rails.logger.error "[SDR IA] [V2] Erro ao ler prompts_new.yml: #{e.message}"
      {}
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
        'sdr_ia_qualificado_em' => Time.current.iso8601
      })

      contact.save!
      Rails.logger.info "[SDR IA] [V2] Contact #{contact.id} qualificado com sucesso"
    end

    def send_closing_message(analysis)
      temperatura = analysis['temperatura']
      clinic_name = @config.dig('clinic_name') || 'nossa clínica'
      agent_name = get_agent_name

      mensagem = case temperatura
                 when 'quente'
                   "Perfeito! Vejo que você tem grande interesse 🎯\n" \
                   "Vou te conectar AGORA com #{agent_name}, nosso especialista em SDR. " \
                   "Ele vai te ajudar a agendar sua avaliação! 😊"
                 when 'morno'
                   "Ótimo! Entendi suas necessidades 😊\n" \
                   "Vou te enviar nosso portfólio com resultados reais e tabela de valores.\n" \
                   "#{agent_name} vai entrar em contato em até 2 horas para tirar suas dúvidas. Tudo bem?"
                 when 'frio'
                   "Entendi que você está no início da pesquisa! 💙\n" \
                   "Vou te adicionar em nosso grupo de conteúdos e promoções.\n" \
                   "Quando quiser conversar mais, é só chamar!"
                 when 'muito_frio'
                   "Obrigado pelo contato! 😊\n" \
                   "Vou te deixar em nossa base para futuras novidades.\n" \
                   "Qualquer coisa, estamos à disposição!"
                 else
                   "Obrigado pelas informações!"
                 end

      send_message(mensagem)
    end

    def get_agent_name
      default_email = @config.dig('default_agent_email')
      if default_email.present?
        agent = @account.users.find_by(email: default_email)
        return agent.name if agent
      end
      'nossa equipe'
    end

    def send_message(content)
      # Tenta usar o agente padrão configurado
      default_agent_email = @config.dig('default_agent_email')
      sender = nil

      if default_agent_email.present?
        sender = @account.users.find_by(email: default_agent_email)
        Rails.logger.info "[SDR IA] [V2] Usando agente padrão: #{default_agent_email}" if sender
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

      Rails.logger.info "[SDR IA] [V2] Mensagem enviada por #{sender.email}: #{content[0..50]}..."
      message
    rescue StandardError => e
      Rails.logger.error "[SDR IA] [V2] Erro ao enviar mensagem: #{e.message}"
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
          Rails.logger.info "[SDR IA] [V2] Label '#{tag_name}' aplicada"
        end
      end
    rescue StandardError => e
      Rails.logger.error "[SDR IA] [V2] Erro ao aplicar labels: #{e.message}"
    end

    def should_assign_to_team?(analysis)
      ['quente', 'morno'].include?(analysis['temperatura']) &&
        ['transferir_closer', 'agendar_followup'].include?(analysis['proximo_passo'])
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
      Rails.logger.info "[SDR IA] [V2] Lead atribuído para time #{team.name}"
    rescue StandardError => e
      Rails.logger.error "[SDR IA] [V2] Erro ao atribuir time: #{e.message}"
    end
  end
end

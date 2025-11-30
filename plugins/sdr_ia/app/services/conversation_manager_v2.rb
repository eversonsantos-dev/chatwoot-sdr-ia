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

      # NOVO: Fazer mini-análise para saber estado atual
      @current_state = extract_current_state(history)
      Rails.logger.info "[SDR IA] [V2] Estado atual: #{@current_state['informacoes_coletadas']}/5 informações"

      # Verificar se deve qualificar (análise inteligente)
      if should_qualify_now?(history, @current_state)
        Rails.logger.info "[SDR IA] [V2] Qualificação completa detectada! Iniciando finalização..."
        qualify_lead(history)
      else
        # Gerar resposta conversacional COM CONTEXTO do estado atual
        generate_conversational_response(history, @current_state)
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
      # Buscar mensagens com todos os dados necessários (incluindo attachments)
      messages = conversation.messages
        .order(created_at: :asc)
        .limit(30) # Últimas 30 mensagens

      history = []

      messages.each do |message|
        # Pular mensagens vazias sem attachment
        next if message.content.blank? && message.attachments.empty?

        role = message.message_type == 'incoming' ? 'user' : 'assistant'
        content = message.content

        # Se a mensagem tiver attachments de áudio, transcrever
        if message.content.blank? && message.attachments.present?
          audio_attachment = message.attachments.find do |att|
            att.file_type == 'audio' ||
            att.content_type&.start_with?('audio/') ||
            %w[.mp3 .m4a .wav .ogg .mpeg .mpga].any? { |ext| att.file&.filename&.to_s&.downcase&.end_with?(ext) }
          end

          if audio_attachment
            Rails.logger.info "[SDR IA] [Audio] Detectado áudio na mensagem #{message.id}"

            # Transcrever áudio
            transcriber = SdrIa::AudioTranscriber.new(@account)
            transcription = transcriber.transcribe_from_url(audio_attachment.download_url)

            if transcription.present?
              content = "[Áudio transcrito]: #{transcription}"
              Rails.logger.info "[SDR IA] [Audio] ✅ Transcrição adicionada ao histórico"
            else
              content = "[Áudio não pôde ser transcrito]"
              Rails.logger.warn "[SDR IA] [Audio] ⚠️ Falha na transcrição"
            end
          end
        end

        # Adicionar ao histórico apenas se tiver conteúdo
        if content.present?
          history << {
            role: role,
            content: content,
            timestamp: message.created_at
          }
        end
      end

      history
    end

    def should_qualify_now?(history, current_state = nil)
      # Contar apenas mensagens do lead (incoming)
      lead_messages_count = history.count { |msg| msg[:role] == 'user' }
      last_message = history.last[:content].to_s.downcase if history.last

      # NOVO: Threshold dinâmico baseado em informações coletadas
      infos_coletadas = current_state&.dig('informacoes_coletadas') || 0
      qualificacao_completa = current_state&.dig('qualificacao_completa') || false

      # Qualificar se:
      # 1. Mini-análise detectou qualificação completa (4-5 informações)
      # 2. Já tem 4+ informações E pelo menos 3 mensagens do lead
      # 3. Já trocou muitas mensagens (>= 6 do lead) - reduzido de 8
      # 4. Lead disse explicitamente que quer finalizar/falar com humano

      qualificacao_completa ||
        (infos_coletadas >= 4 && lead_messages_count >= 3) ||
        lead_messages_count >= 6 ||
        last_message&.include?('falar com') ||
        last_message&.include?('atendente') ||
        last_message&.include?('humano') ||
        last_message&.include?('pessoa') ||
        last_message&.include?('especialista')
    end

    def generate_conversational_response(history, current_state = nil)
      client = OpenaiClient.new(@account)

      # NOVO: Injetar contexto do estado atual no prompt
      system_prompt = get_conversational_system_prompt_with_context(current_state)

      # Gerar resposta usando OpenAI
      response = client.generate_response(history, system_prompt)

      if response.present?
        send_message(response)
        Rails.logger.info "[SDR IA] [V2] Resposta conversacional enviada"

        # GATILHO: Se a mensagem indica encerramento, qualificar e atribuir automaticamente
        if response_indicates_handoff?(response)
          Rails.logger.info "[SDR IA] [V2] Mensagem de encerramento detectada! Iniciando qualificação automática..."
          qualify_lead(history)
        end
      else
        Rails.logger.error "[SDR IA] [V2] Falha ao gerar resposta, usando fallback"
        send_message("Desculpe, tive um problema técnico. Pode repetir?")
      end
    rescue StandardError => e
      Rails.logger.error "[SDR IA] [V2] Erro ao gerar resposta conversacional: #{e.message}"
      # Não envia nada em caso de erro para não spammar
    end

    def response_indicates_handoff?(response)
      # Detectar frases que indicam passagem para especialista
      handoff_keywords = [
        'já temos todas as informações',
        'encaminhar seu contato',
        'nosso especialista',
        'entrará em contato',
        'dar continuidade',
        'vamos te conectar',
        'nossa equipe vai entrar em contato'
      ]

      response_downcase = response.downcase
      handoff_keywords.any? { |keyword| response_downcase.include?(keyword) }
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

        # Aplicar labels ANTES de enviar mensagem
        apply_labels(analysis['tags_sugeridas']) if analysis['tags_sugeridas']

        # ATRIBUIR TIME IMEDIATAMENTE (antes da mensagem)
        # Para leads QUENTES e MORNOS, garantir atribuição automática
        assign_to_team(analysis)

        # Enviar mensagem de encerramento (DEPOIS da atribuição)
        # REMOVIDO: send_closing_message(analysis) - Mensagem automática desabilitada

        Rails.logger.info "[SDR IA] [V2] Qualificação completa: #{analysis['temperatura']} - Score: #{analysis['score']}"
      else
        Rails.logger.error "[SDR IA] [V2] Falha na análise da IA"
        send_message("Obrigado pelas informações! Nossa equipe entrará em contato em breve.")
      end
    end

    def get_conversational_system_prompt
      base_prompt = @config.dig('prompts', 'system') || read_prompts_from_file['system']

      # Adicionar base de conhecimento ao prompt se configurado
      knowledge_base = @config.dig('knowledge_base')
      if knowledge_base.present?
        base_prompt += "\n\n# BASE DE CONHECIMENTO DA EMPRESA\n\n#{knowledge_base}\n\n" \
                      "Use essas informações para responder perguntas do lead sobre a clínica."
      end

      base_prompt
    end

    # NOVO: Prompt com contexto do estado atual da qualificação
    def get_conversational_system_prompt_with_context(current_state)
      base_prompt = get_conversational_system_prompt

      return base_prompt unless current_state

      # Construir seção de estado atual
      nome = current_state['nome']
      interesse = current_state['interesse']
      urgencia = current_state['urgencia']
      conhecimento = current_state['conhecimento']
      localizacao = current_state['localizacao']
      faltantes = current_state['informacoes_faltantes'] || []

      estado_section = <<~ESTADO

        ---
        # ESTADO ATUAL DA QUALIFICAÇÃO (INFORMAÇÃO INTERNA - NÃO MENCIONE ISSO AO LEAD)

        ## Informações JÁ COLETADAS (NÃO pergunte novamente):
        #{nome ? "- Nome: #{nome} ✓" : "- Nome: NÃO COLETADO"}
        #{interesse ? "- Interesse/Procedimento: #{interesse} ✓" : "- Interesse: NÃO COLETADO"}
        #{urgencia && urgencia != 'null' ? "- Urgência: #{urgencia} ✓" : "- Urgência: NÃO COLETADA"}
        #{conhecimento && conhecimento != 'null' ? "- Conhecimento: #{conhecimento} ✓" : "- Conhecimento: NÃO COLETADO"}
        #{localizacao ? "- Localização: #{localizacao} ✓" : "- Localização: NÃO COLETADA"}

        ## O QUE FALTA COLETAR (priorize estas):
        #{faltantes.any? ? faltantes.map { |f| "- #{f}" }.join("\n") : "- Todas as informações coletadas!"}

        ## INSTRUÇÕES IMPORTANTES:
        1. NUNCA pergunte algo que já foi coletado acima
        2. Foque em coletar AS INFORMAÇÕES FALTANTES de forma natural
        3. Se o lead já deu várias informações, agradeça e pergunte só o que falta
        4. Se todas informações estão coletadas, finalize a qualificação
        5. Trate o lead pelo nome se já souber
        ---

      ESTADO

      base_prompt + estado_section
    end

    # NOVO: Extrai estado atual da conversa via mini-análise
    def extract_current_state(history)
      return default_state if history.empty?

      # Montar conversa para análise
      conversation_text = history.map do |msg|
        role_label = msg[:role] == 'user' ? 'Lead' : 'Atendente'
        "#{role_label}: #{msg[:content]}"
      end.join("\n")

      # Fazer mini-análise rápida
      client = OpenaiClient.new(@account)
      result = client.quick_extract(conversation_text)

      if result
        # Calcular informações coletadas
        infos = 0
        faltantes = []

        if result['nome'].present? && result['nome'] != 'null'
          infos += 1
        else
          faltantes << 'nome'
        end

        if result['interesse'].present? && result['interesse'] != 'null'
          infos += 1
        else
          faltantes << 'interesse/procedimento'
        end

        if result['urgencia'].present? && result['urgencia'] != 'null'
          infos += 1
        else
          faltantes << 'urgência'
        end

        if result['conhecimento'].present? && result['conhecimento'] != 'null'
          infos += 1
        else
          faltantes << 'conhecimento sobre o procedimento'
        end

        if result['localizacao'].present? && result['localizacao'] != 'null'
          infos += 1
        else
          faltantes << 'localização (bairro/cidade)'
        end

        result['informacoes_coletadas'] = infos
        result['informacoes_faltantes'] = faltantes
        result['qualificacao_completa'] = infos >= 4

        Rails.logger.info "[SDR IA] [V2] Mini-análise: #{infos}/5 infos. Faltam: #{faltantes.join(', ')}"
        result
      else
        Rails.logger.warn "[SDR IA] [V2] Mini-análise falhou, usando estado padrão"
        default_state
      end
    rescue StandardError => e
      Rails.logger.error "[SDR IA] [V2] Erro na extração de estado: #{e.message}"
      default_state
    end

    def default_state
      {
        'nome' => nil,
        'interesse' => nil,
        'urgencia' => nil,
        'conhecimento' => nil,
        'localizacao' => nil,
        'informacoes_coletadas' => 0,
        'informacoes_faltantes' => %w[nome interesse urgência conhecimento localização],
        'qualificacao_completa' => false
      }
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
      temperatura = analysis['temperatura']
      score = analysis['score']

      # Determinar estágio do funil baseado em temperatura e score
      estagio_funil = determine_funnel_stage(temperatura, score)

      contact.custom_attributes.merge!({
        'sdr_ia_status' => 'qualificado',
        'sdr_ia_temperatura' => temperatura,
        'sdr_ia_score' => score,
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
        'estagio_funil' => estagio_funil  # MELHORIA 04: Estágio do Funil
      })

      contact.save!
      Rails.logger.info "[SDR IA] [V2] Contact #{contact.id} qualificado: #{estagio_funil} (#{temperatura} - #{score}pts)"
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
                   contact_name = analysis['nome'] || 'você'
                   "Ótimo, #{contact_name}! Já temos todas as informações necessárias. 😊\n" \
                   "Agradeço muito pelo seu interesse e pelas informações.\n" \
                   "Vamos encaminhar seu contato para nosso especialista, que entrará em contato em breve para dar continuidade.\n" \
                   "Se tiver mais alguma dúvida ou precisar de algo, estamos à disposição!"
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

      labels_aplicadas = []

      tag_names.each do |tag_name|
        label = @account.labels.find_by(title: tag_name)

        unless label
          Rails.logger.warn "[SDR IA] [V2] Label '#{tag_name}' não encontrada, tentando criar..."
          label = create_label_if_needed(tag_name)
        end

        next unless label

        unless contact.labels.include?(label)
          contact.labels << label
          labels_aplicadas << tag_name
        end
      end

      Rails.logger.info "[SDR IA] [V2] Labels aplicadas: #{labels_aplicadas.join(', ')}" if labels_aplicadas.any?

    rescue StandardError => e
      Rails.logger.error "[SDR IA] [V2] Erro ao aplicar labels: #{e.message}"
    end

    # MELHORIA 04: Criar label automaticamente se não existir
    def create_label_if_needed(tag_name)
      # Definir cor baseada no tipo de label
      color = case tag_name
              when /temperatura-quente/
                '#FF0000'  # Vermelho
              when /temperatura-morno/
                '#FFA500'  # Laranja
              when /temperatura-frio/
                '#0000FF'  # Azul
              when /temperatura-muito_frio/
                '#808080'  # Cinza
              when /procedimento-/
                '#9C27B0'  # Roxo
              when /urgencia-/
                '#FF9800'  # Laranja escuro
              when /comportamento-/
                '#4CAF50'  # Verde
              else
                '#000000'  # Preto (padrão)
              end

      @account.labels.create!(
        title: tag_name,
        description: "Criada automaticamente pelo SDR IA",
        color: color
      )

      Rails.logger.info "[SDR IA] [V2] Label '#{tag_name}' criada automaticamente"

    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[SDR IA] [V2] Erro ao criar label '#{tag_name}': #{e.message}"
      nil
    end

    def assign_to_team(analysis)
      temperatura = analysis['temperatura']

      # REGRA UNIVERSAL: Leads QUENTES e MORNOS SEMPRE são atribuídos automaticamente
      return unless ['quente', 'morno'].include?(temperatura)

      # MELHORIA v2.1.0: Usar Round Robin se habilitado
      round_robin = RoundRobinAssigner.new(@account)

      if round_robin.assign_conversation(conversation, temperatura)
        Rails.logger.info "[SDR IA] [V2] ✅ Lead #{temperatura.upcase} atribuído via Round Robin"

        # Criar nota privada para o closer
        create_private_note_for_closer(analysis)

        return
      end

      # FALLBACK: Sistema de times tradicional
      team_id = case temperatura
                when 'quente'
                  @config.dig('teams', 'quente_team_id')
                when 'morno'
                  @config.dig('teams', 'morno_team_id')
                end

      if team_id.nil?
        Rails.logger.warn "[SDR IA] [V2] Team ID não configurado para temperatura: #{temperatura}"
        return
      end

      team = Team.find_by(id: team_id)
      unless team
        Rails.logger.error "[SDR IA] [V2] Team não encontrado: ID #{team_id}"
        return
      end

      # Atribuir conversa ao time
      conversation.update!(team_id: team_id)
      Rails.logger.info "[SDR IA] [V2] ✅ Lead #{temperatura.upcase} atribuído IMEDIATAMENTE para time: #{team.name} (ID: #{team_id})"

      # MELHORIA 03: Criar nota privada para o closer
      create_private_note_for_closer(analysis)

    rescue StandardError => e
      Rails.logger.error "[SDR IA] [V2] Erro ao atribuir time: #{e.message}"
      Rails.logger.error e.backtrace.join("\n") if e.backtrace
    end

    # MELHORIA 04: Determinar estágio do funil
    def determine_funnel_stage(temperatura, score)
      return 'Lead Desqualificado' if temperatura == 'muito_frio' || score < 20

      case temperatura
      when 'quente'
        'Lead Qualificado'  # Alta prioridade, pronto para closer
      when 'morno'
        'Lead Qualificado'  # Média prioridade, mas ainda qualificado
      when 'frio'
        'Contato Inicial'   # Baixa prioridade, precisa nutrição
      else
        'Novo Lead'
      end
    end

    # MELHORIA 03: Criar nota privada automática para o closer
    def create_private_note_for_closer(analysis)
      temperatura_emoji = {
        'quente' => '🔴',
        'morno' => '🟡',
        'frio' => '🔵',
        'muito_frio' => '⚫'
      }[analysis['temperatura']] || '⚪'

      nota_content = <<~NOTA
        #{temperatura_emoji} **QUALIFICAÇÃO AUTOMÁTICA SDR IA**

        📊 **Score:** #{analysis['score']}/130 pontos
        🌡️ **Temperatura:** #{analysis['temperatura'].upcase}
        🎯 **Estágio:** #{determine_funnel_stage(analysis['temperatura'], analysis['score'])}

        👤 **Nome:** #{analysis['nome'] || 'Não informado'}
        💎 **Interesse:** #{analysis['interesse'] || 'Não especificado'}
        ⏰ **Urgência:** #{analysis['urgencia']&.humanize || 'Não informada'}
        📍 **Localização:** #{analysis['localizacao'] || 'Não informada'}

        💡 **Motivação:** #{analysis['motivacao'] || 'Não identificada'}
        📚 **Conhecimento:** #{analysis['conhecimento']&.humanize || 'Não avaliado'}
        🎭 **Comportamento:** #{analysis['comportamento']&.humanize || 'Normal'}

        📝 **RESUMO PARA CLOSER:**
        #{analysis['resumo']}

        🎯 **PRÓXIMO PASSO RECOMENDADO:**
        #{analysis['proximo_passo']&.humanize || 'Avaliar contexto'}

        ⏱️ **Qualificado em:** #{Time.current.strftime('%d/%m/%Y às %H:%M')}

        ---
        _Nota gerada automaticamente pelo SDR IA v1.3.0_
      NOTA

      # Criar a nota privada (visible only to agents)
      conversation.messages.create!(
        account: @account,
        inbox: conversation.inbox,
        message_type: :activity,
        content: nota_content,
        private: true,  # Nota privada - lead não vê
        sender: conversation.assignee || @account.users.first
      )

      Rails.logger.info "[SDR IA] [V2] ✅ Nota privada criada para closer com resumo da qualificação"

    rescue StandardError => e
      Rails.logger.error "[SDR IA] [V2] Erro ao criar nota privada: #{e.message}"
    end
  end
end

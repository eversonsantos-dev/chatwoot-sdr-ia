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
        Rails.logger.info "[SDR IA] [V2] ✅ Análise recebida da IA: temperatura=#{analysis['temperatura']}, score=#{analysis['score']}"

        # Atualizar contact com análise
        update_contact_with_analysis(analysis)
        Rails.logger.info "[SDR IA] [V2] ✅ Custom attributes atualizados"

        # Aplicar labels ANTES de enviar mensagem
        if analysis['tags_sugeridas']
          apply_labels(analysis['tags_sugeridas'])
          Rails.logger.info "[SDR IA] [V2] ✅ Labels aplicadas"
        end

        # ATRIBUIR TIME IMEDIATAMENTE (antes da mensagem)
        # Para leads QUENTES e MORNOS, garantir atribuição automática
        Rails.logger.info "[SDR IA] [V2] 🎯 INICIANDO ATRIBUIÇÃO AUTOMÁTICA..."
        assign_to_team(analysis)
        Rails.logger.info "[SDR IA] [V2] ✅ Atribuição automática concluída"

        # Enviar mensagem de encerramento (DEPOIS da atribuição)
        Rails.logger.info "[SDR IA] [V2] 💬 Enviando mensagem de encerramento..."
        send_closing_message(analysis)
        Rails.logger.info "[SDR IA] [V2] ✅ Mensagem de encerramento enviada"

        Rails.logger.info "[SDR IA] [V2] ✅✅✅ Qualificação completa: #{analysis['temperatura']} - Score: #{analysis['score']}"
      else
        Rails.logger.error "[SDR IA] [V2] ❌ Falha na análise da IA - Análise retornou nil"
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
      agent_name = get_agent_name || 'nossa equipe'

      # Buscar mensagem configurável do banco, com fallback para mensagens padrão
      closing_messages = @config.dig('closing_messages') || {}
      mensagem_template = closing_messages[temperatura] || get_default_closing_message(temperatura)

      # Garantir que mensagem_template não é nil
      if mensagem_template.nil? || mensagem_template.empty?
        Rails.logger.error "[SDR IA] [V2] Mensagem template vazia para temperatura: #{temperatura}"
        mensagem_template = "Obrigado pelas informações! Nossa equipe entrará em contato em breve."
      end

      # Substituir placeholder {{agent_name}} pelo nome real do agente
      mensagem = mensagem_template.gsub('{{agent_name}}', agent_name.to_s)

      send_message(mensagem)
    rescue StandardError => e
      Rails.logger.error "[SDR IA] [V2] Erro ao enviar mensagem de encerramento: #{e.message}"
      # Tentar enviar mensagem genérica
      send_message("Obrigado pelas informações! Nossa equipe entrará em contato em breve.") rescue nil
    end

    def get_default_closing_message(temperatura)
      case temperatura
      when 'quente'
        "Perfeito! Vejo que você tem grande interesse 🎯\nVou te conectar AGORA com {{agent_name}}, nossa especialista. Ela vai te ajudar a agendar sua avaliação! 😊"
      when 'morno'
        "Ótimo! Entendi suas necessidades 😊\nVou te enviar nosso portfólio com resultados reais e tabela de valores.\n{{agent_name}} vai entrar em contato em até 2 horas para tirar suas dúvidas. Tudo bem?"
      when 'frio'
        "Entendi que você está no início da pesquisa! 💙\nVou te adicionar em nosso grupo de conteúdos e promoções.\nQuando quiser conversar mais, é só chamar!"
      when 'muito_frio'
        "Obrigado pelo contato! 😊\nSe mudar de ideia, estarei por aqui!"
      else
        "Obrigado pelas informações!"
      end
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
      Rails.logger.info "[SDR IA] [V2] 🎯 Iniciando atribuição automática para temperatura: #{temperatura}"

      # REGRA UNIVERSAL: Leads QUENTES e MORNOS SEMPRE são atribuídos automaticamente
      unless ['quente', 'morno'].include?(temperatura)
        Rails.logger.info "[SDR IA] [V2] ⏭️ Lead #{temperatura} não requer atribuição automática"
        return
      end

      team_id = case temperatura
                when 'quente'
                  @config.dig('teams', 'quente_team_id')
                when 'morno'
                  @config.dig('teams', 'morno_team_id')
                end

      Rails.logger.info "[SDR IA] [V2] 🔍 Team ID configurado para #{temperatura}: #{team_id || 'NÃO CONFIGURADO'}"

      if team_id.nil?
        Rails.logger.warn "[SDR IA] [V2] ⚠️ Team ID não configurado para temperatura: #{temperatura}. Configure em Configurações → SDR IA → Atribuição Automática"
        return
      end

      team = Team.find_by(id: team_id)
      unless team
        Rails.logger.error "[SDR IA] [V2] ❌ Team não encontrado com ID #{team_id}. Verifique se o time existe na conta."
        return
      end

      Rails.logger.info "[SDR IA] [V2] 📋 Time encontrado: #{team.name} (ID: #{team_id})"

      # Atribuir conversa ao time
      conversation.update!(team_id: team_id)
      Rails.logger.info "[SDR IA] [V2] ✅ Lead #{temperatura.upcase} atribuído IMEDIATAMENTE para time: #{team.name} (ID: #{team_id})"
      Rails.logger.info "[SDR IA] [V2] 📊 Conversation #{conversation.id} agora pertence ao time #{team_id}"

      # MELHORIA 03: Criar nota privada para o closer
      create_private_note_for_closer(analysis)

    rescue StandardError => e
      Rails.logger.error "[SDR IA] [V2] ❌ ERRO CRÍTICO ao atribuir time: #{e.message}"
      Rails.logger.error "[SDR IA] [V2] Backtrace: #{e.backtrace.join("\n")}" if e.backtrace
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

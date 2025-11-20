# frozen_string_literal: true

module SdrIa
  class LeadQualifier
    attr_reader :contact, :conversation

    def initialize(contact:, conversation: nil, account: nil)
      @contact = contact
      @conversation = conversation || contact.conversations.last
      @account = account || contact.account
      @config = SdrIa.config(@account)

      # Busca prompts da config do banco, fallback para YAML
      @prompts = @config['prompts'] || load_prompts_from_yaml
    end

    def qualify!
      Rails.logger.info "[SDR IA] Iniciando qualificação: Contact #{contact.id}"

      return { success: false, reason: 'já qualificado' } if already_qualified?

      messages = collect_messages
      return { success: false, reason: 'sem mensagens' } if messages.empty?

      analysis = analyze_with_ai(messages)
      return { success: false, reason: 'análise falhou' } unless analysis

      update_contact(analysis)
      apply_labels(analysis['tags_sugeridas']) if analysis['tags_sugeridas']
      assign_to_team(analysis) if should_assign_to_team?(analysis)

      Rails.logger.info "[SDR IA] Qualificação concluída: #{analysis['temperatura']} - Score: #{analysis['score']}"

      { success: true, analysis: analysis }
    rescue StandardError => e
      Rails.logger.error "[SDR IA] Erro na qualificação: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      { success: false, error: e.message }
    end

    private

    def already_qualified?
      contact.custom_attributes['sdr_ia_status'] == 'qualificado'
    end

    def collect_messages
      return [] unless conversation

      conversation.messages
        .where.not(content: nil)
        .order(created_at: :asc)
        .map do |msg|
          sender = msg.incoming? ? contact.name || 'Lead' : 'Atendente'
          "#{sender}: #{msg.content}"
        end
    end

    def analyze_with_ai(messages)
      conversation_text = messages.join("\n")

      client = OpenaiClient.new(@account)
      client.analyze_conversation(
        conversation_text,
        @prompts['system'],
        @prompts['analysis']
      )
    rescue StandardError => e
      Rails.logger.error "[SDR IA] Erro na análise OpenAI: #{e.message}"
      nil
    end

    def update_contact(analysis)
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
      Rails.logger.info "[SDR IA] Contact #{contact.id} atualizado com análise"
    end

    def apply_labels(tag_names)
      return unless tag_names.is_a?(Array)

      account = contact.account
      tag_names.each do |tag_name|
        label = account.labels.find_by(title: tag_name)
        next unless label

        unless contact.labels.include?(label)
          contact.labels << label
          Rails.logger.info "[SDR IA] Label '#{tag_name}' aplicada ao contact #{contact.id}"
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
                  @config['teams']['quente_team_id']
                when 'morno'
                  @config['teams']['morno_team_id']
                end

      return unless team_id && conversation

      team = Team.find_by(id: team_id)
      return unless team

      conversation.update!(team_id: team_id)
      Rails.logger.info "[SDR IA] Lead atribuído para time #{team_id}"
    rescue StandardError => e
      Rails.logger.error "[SDR IA] Erro ao atribuir time: #{e.message}"
    end

    def load_prompts_from_yaml
      YAML.load_file(Rails.root.join('plugins/sdr_ia/config/prompts.yml'))['prompts']
    rescue StandardError => e
      Rails.logger.error "[SDR IA] Erro ao carregar prompts YAML: #{e.message}"
      {
        'system' => 'Você é um SDR virtual.',
        'analysis' => 'Analise a conversa.'
      }
    end
  end
end

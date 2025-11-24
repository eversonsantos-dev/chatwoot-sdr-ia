# frozen_string_literal: true

module SdrIa
  # Serviço para distribuir leads qualificados entre closers usando Round Robin
  class RoundRobinAssigner
    attr_reader :account, :config

    def initialize(account)
      @account = account
      @sdr_config = SdrIaConfig.for_account(account)
      @config = SdrIa.config(account)
    end

    # Atribui conversa ao próximo closer disponível
    def assign_conversation(conversation, temperatura)
      unless round_robin_enabled?
        Rails.logger.info "[SDR IA] [Round Robin] Round Robin desabilitado"
        return false
      end

      # Buscar lista de closers
      closers = get_closers_list(temperatura)

      if closers.empty?
        Rails.logger.warn "[SDR IA] [Round Robin] Nenhum closer configurado"
        return false
      end

      # Selecionar próximo closer
      closer = select_next_closer(closers, temperatura)

      unless closer
        Rails.logger.error "[SDR IA] [Round Robin] Erro ao selecionar closer"
        return false
      end

      # Atribuir conversa ao closer
      assign_to_closer(conversation, closer)

      Rails.logger.info "[SDR IA] [Round Robin] ✅ Lead #{temperatura} atribuído para #{closer['name']} (#{closer['email']})"

      true
    rescue StandardError => e
      Rails.logger.error "[SDR IA] [Round Robin] Erro: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      false
    end

    # Retorna estatísticas de distribuição
    def get_distribution_stats
      closers = @sdr_config.round_robin_closers || []
      return {} if closers.empty?

      stats = {}

      closers.each do |closer|
        user = @account.users.find_by(email: closer['email'])
        next unless user

        # Contar conversas atribuídas
        assigned_count = Conversation.joins(:messages)
                                     .where(account: @account, assignee: user)
                                     .where("messages.created_at > ?", 30.days.ago)
                                     .distinct
                                     .count

        stats[closer['email']] = {
          name: closer['name'],
          email: closer['email'],
          assigned_last_30_days: assigned_count,
          active: closer['active'] != false
        }
      end

      stats
    end

    private

    def round_robin_enabled?
      @sdr_config&.enable_round_robin == true
    end

    def get_closers_list(temperatura)
      closers = @sdr_config.round_robin_closers || []

      # Filtrar apenas closers ativos
      closers.select { |c| c['active'] != false }
    end

    def select_next_closer(closers, temperatura)
      strategy = @sdr_config.round_robin_strategy || 'sequential'

      case strategy
      when 'sequential'
        select_sequential(closers)
      when 'random'
        select_random(closers)
      when 'weighted'
        select_weighted(closers, temperatura)
      else
        select_sequential(closers)
      end
    end

    # Estratégia sequencial: um após o outro
    def select_sequential(closers)
      return nil if closers.empty?

      # Incrementar índice
      current_index = @sdr_config.last_assigned_closer_index || -1
      next_index = (current_index + 1) % closers.size

      # Atualizar índice no banco
      @sdr_config.update_column(:last_assigned_closer_index, next_index)

      selected = closers[next_index]
      Rails.logger.info "[SDR IA] [Round Robin] Selecionado closer sequencial: índice #{next_index}/#{closers.size}"

      selected
    end

    # Estratégia aleatória
    def select_random(closers)
      return nil if closers.empty?

      selected = closers.sample
      Rails.logger.info "[SDR IA] [Round Robin] Selecionado closer aleatório: #{selected['email']}"

      selected
    end

    # Estratégia ponderada: leads quentes para closers mais experientes
    def select_weighted(closers, temperatura)
      return nil if closers.empty?

      # Separar por peso (se configurado)
      high_priority = closers.select { |c| c['priority'] == 'high' }
      medium_priority = closers.select { |c| c['priority'] == 'medium' }
      low_priority = closers.select { |c| c['priority'].nil? || c['priority'] == 'low' }

      # Distribuir baseado em temperatura
      candidates = case temperatura
                   when 'quente'
                     high_priority.presence || medium_priority.presence || low_priority
                   when 'morno'
                     medium_priority.presence || high_priority.presence || low_priority
                   else
                     low_priority.presence || medium_priority.presence || high_priority
                   end

      selected = candidates.sample
      Rails.logger.info "[SDR IA] [Round Robin] Selecionado closer ponderado (#{temperatura}): #{selected['email']}"

      selected
    end

    # Atribui conversa ao closer selecionado
    def assign_to_closer(conversation, closer)
      user = @account.users.find_by(email: closer['email'])

      unless user
        Rails.logger.error "[SDR IA] [Round Robin] Usuário não encontrado: #{closer['email']}"
        return false
      end

      # Atribuir conversa ao usuário
      conversation.update!(assignee: user)

      # Adicionar nota privada informando atribuição
      add_assignment_note(conversation, user)

      Rails.logger.info "[SDR IA] [Round Robin] Conversa #{conversation.id} atribuída para #{user.name} (#{user.email})"

      true
    rescue StandardError => e
      Rails.logger.error "[SDR IA] [Round Robin] Erro ao atribuir: #{e.message}"
      false
    end

    def add_assignment_note(conversation, user)
      note_content = "🎯 **Lead atribuído automaticamente via Round Robin**\n\n" \
                    "👤 **Closer:** #{user.name}\n" \
                    "📧 **Email:** #{user.email}\n" \
                    "⏱️ **Data:** #{Time.current.strftime('%d/%m/%Y às %H:%M')}\n\n" \
                    "---\n" \
                    "_Atribuição automática pelo SDR IA v2.1.0_"

      conversation.messages.create!(
        account: @account,
        inbox: conversation.inbox,
        message_type: :activity,
        content: note_content,
        private: true,
        sender: conversation.assignee || @account.users.first
      )
    rescue StandardError => e
      Rails.logger.warn "[SDR IA] [Round Robin] Erro ao criar nota de atribuição: #{e.message}"
    end
  end
end

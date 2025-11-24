# frozen_string_literal: true

module SdrIa
  class Listener < BaseListener
    include Singleton

    def conversation_created(event)
      conversation = event.data[:conversation]
      contact = conversation.contact

      Rails.logger.info "[SDR IA] Nova conversa detectada: conversation_id=#{conversation.id}, contact_id=#{contact.id}"

      # Inicializar status de qualificação
      contact.custom_attributes ||= {}
      contact.custom_attributes['sdr_ia_status'] = 'em_andamento'
      contact.custom_attributes['sdr_ia_progresso'] = '0/6'
      contact.custom_attributes['sdr_ia_iniciado_em'] = Time.current.iso8601
      contact.save!

      Rails.logger.info "[SDR IA] Contact #{contact.id} marcado como em_andamento"
    rescue StandardError => e
      Rails.logger.error "[SDR IA] Erro em conversation_created: #{e.message}"
    end

    def message_created(event)
      message = event.data[:message]
      return unless message.incoming?

      conversation = message.conversation
      contact = conversation.contact

      Rails.logger.info "[SDR IA] Nova mensagem incoming: contact_id=#{contact.id}, msg_id=#{message.id}"

      status = contact.custom_attributes['sdr_ia_status']
      return unless ['em_andamento', nil, ''].include?(status)

      # MELHORIA: Usar buffer para agrupar mensagens consecutivas
      # Exemplo: Lead manda "Oi", "Tudo bem?", "Pode me ajudar?" → agrupamos antes de responder
      buffer = SdrIa::MessageBuffer.new(conversation.id)
      buffer.add_message(message.id)

      Rails.logger.info "[SDR IA] Mensagem adicionada ao buffer. Total no buffer: #{buffer.buffer_size}"
    rescue StandardError => e
      Rails.logger.error "[SDR IA] Erro em message_created: #{e.message}"
    end
  end
end

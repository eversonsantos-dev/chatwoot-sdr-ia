# frozen_string_literal: true

module SdrIa
  class QualifyLeadJob < ApplicationJob
    queue_as :default

    def perform(contact_id, conversation_id = nil)
      Rails.logger.info "[SDR IA Job] Processando contact_id=#{contact_id}, conversation_id=#{conversation_id}"

      contact = Contact.find_by(id: contact_id)
      unless contact
        Rails.logger.warn "[SDR IA Job] Contact #{contact_id} não encontrado"
        return
      end

      conversation = conversation_id ? Conversation.find_by(id: conversation_id) : contact.conversations.last
      unless conversation
        Rails.logger.warn "[SDR IA Job] Nenhuma conversa encontrada para contact #{contact_id}"
        return
      end

      # Usar ConversationManager para fluxo conversacional
      manager = ConversationManager.new(
        contact: contact,
        conversation: conversation,
        account: contact.account
      )

      manager.process_message!

      Rails.logger.info "[SDR IA Job] Mensagem processada com sucesso para contact #{contact_id}"
    rescue StandardError => e
      Rails.logger.error "[SDR IA Job] Erro inesperado: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise
    end
  end
end

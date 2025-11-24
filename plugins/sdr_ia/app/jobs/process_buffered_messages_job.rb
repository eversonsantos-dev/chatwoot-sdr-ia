# frozen_string_literal: true

module SdrIa
  # Job para processar mensagens que foram agrupadas no buffer
  class ProcessBufferedMessagesJob < ApplicationJob
    queue_as :default

    def perform(conversation_id)
      Rails.logger.info "[SDR IA] [Buffer Job] Processando mensagens agrupadas da conversation #{conversation_id}"

      conversation = Conversation.find_by(id: conversation_id)
      unless conversation
        Rails.logger.error "[SDR IA] [Buffer Job] Conversation não encontrada: #{conversation_id}"
        return
      end

      contact = conversation.contact

      # Verificar se já está qualificado
      if contact.custom_attributes['sdr_ia_status'] == 'qualificado'
        Rails.logger.info "[SDR IA] [Buffer Job] Contact já qualificado, ignorando"
        return
      end

      # Buscar mensagens do buffer
      buffer = MessageBuffer.new(conversation_id)
      message_ids = buffer.get_buffered_messages

      if message_ids.empty?
        Rails.logger.warn "[SDR IA] [Buffer Job] Buffer vazio, nada a processar"
        return
      end

      # Buscar conteúdo das mensagens
      messages = Message.where(id: message_ids, conversation_id: conversation_id, message_type: 'incoming')
                       .order(created_at: :asc)

      # Processar cada mensagem (pode ser texto ou áudio)
      transcriber = AudioTranscriber.new(contact.account)
      processed_contents = []

      messages.each do |msg|
        # Verificar se é áudio
        if message_is_audio?(msg)
          Rails.logger.info "[SDR IA] [Buffer Job] Detectado áudio na mensagem #{msg.id}"

          audio_url = get_audio_url(msg)
          if audio_url
            transcription = transcriber.transcribe_from_url(audio_url)
            if transcription
              processed_contents << "[Áudio transcrito]: #{transcription}"
              Rails.logger.info "[SDR IA] [Buffer Job] ✅ Áudio transcrito: #{transcription[0..100]}"
            else
              processed_contents << "[Áudio não compreendido]"
              Rails.logger.warn "[SDR IA] [Buffer Job] ⚠️ Falha ao transcrever áudio"
            end
          end
        else
          # Mensagem de texto normal
          processed_contents << msg.content if msg.content.present?
        end
      end

      # Concatenar conteúdo das mensagens (texto + áudios transcritos)
      concatenated_content = processed_contents.compact.join("\n")

      Rails.logger.info "[SDR IA] [Buffer Job] Processando #{messages.size} mensagens agrupadas (#{processed_contents.size} processadas):"
      Rails.logger.info "[SDR IA] [Buffer Job] Conteúdo concatenado: #{concatenated_content[0..200]}..."

      # Processar com ConversationManagerV2
      manager = ConversationManagerV2.new(
        contact: contact,
        conversation: conversation,
        account: contact.account
      )

      manager.process_message!

      # Limpar buffer após processar
      buffer.clear_buffer

      Rails.logger.info "[SDR IA] [Buffer Job] ✅ Processamento concluído"

    rescue StandardError => e
      Rails.logger.error "[SDR IA] [Buffer Job] Erro ao processar: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end

    private

    # Verifica se a mensagem contém áudio
    def message_is_audio?(message)
      return false unless message.attachments.present?

      # Verificar se há anexos de áudio
      message.attachments.any? { |att| audio_file?(att) }
    end

    # Verifica se o anexo é um arquivo de áudio
    def audio_file?(attachment)
      return false unless attachment.file_type

      # Tipos MIME de áudio
      audio_types = ['audio/ogg', 'audio/mpeg', 'audio/mp4', 'audio/wav', 'audio/webm', 'audio/aac']
      audio_types.include?(attachment.file_type)
    end

    # Extrai URL do áudio da mensagem
    def get_audio_url(message)
      audio_attachment = message.attachments.find { |att| audio_file?(att) }
      return nil unless audio_attachment

      # Retornar URL completa do arquivo
      if audio_attachment.file_url.present?
        audio_attachment.file_url
      elsif audio_attachment.file.attached?
        # Rails Active Storage
        Rails.application.routes.url_helpers.rails_blob_url(audio_attachment.file, host: ENV['FRONTEND_URL'])
      else
        nil
      end
    rescue StandardError => e
      Rails.logger.error "[SDR IA] [Buffer Job] Erro ao extrair URL do áudio: #{e.message}"
      nil
    end
  end
end

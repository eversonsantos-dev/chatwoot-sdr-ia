# frozen_string_literal: true

module SdrIa
  # Serviço para agrupar mensagens consecutivas do lead antes de processar
  # Evita que a IA responda para cada mensagem individual quando o lead envia várias seguidas
  class MessageBuffer
    # BUFFER_WINDOW: Tempo de espera para agrupar mensagens
    #
    # Configurado para 15 segundos (alinhado com práticas do mercado)
    # Este tempo permite capturar 2-3 mensagens consecutivas rápidas
    # sem fazer o cliente esperar demais.
    #
    # Exemplo de uso:
    # Lead envia: "Oi" + "Tudo bem?" → Sistema aguarda 15s → Responde
    #
    # Referência: WhatsApp Business bots (10-15s), Intercom (8-12s)
    BUFFER_WINDOW = 15.seconds

    REDIS_KEY_PREFIX = 'sdr_ia:message_buffer'

    attr_reader :conversation_id

    def initialize(conversation_id)
      @conversation_id = conversation_id
      @redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379/0')
    end

    # Adiciona mensagem ao buffer e agenda processamento
    def add_message(message_id)
      buffer_key = redis_key

      # Adicionar mensagem ao buffer (usando Redis Set)
      @redis.sadd(buffer_key, message_id)

      # Definir TTL de 25 segundos (maior que BUFFER_WINDOW de 15s)
      @redis.expire(buffer_key, 25)

      # Cancelar job agendado anterior (se existir)
      cancel_pending_job

      # Agendar novo job para processar após BUFFER_WINDOW
      job = ProcessBufferedMessagesJob.set(wait: BUFFER_WINDOW).perform_later(conversation_id)

      # Guardar job_id no Redis para poder cancelar (TTL maior que BUFFER_WINDOW)
      @redis.setex(job_key, 25, job.provider_job_id)

      Rails.logger.info "[SDR IA] [Buffer] Mensagem #{message_id} adicionada ao buffer. Processamento em #{BUFFER_WINDOW}s"

      true
    rescue StandardError => e
      Rails.logger.error "[SDR IA] [Buffer] Erro ao adicionar mensagem: #{e.message}"
      false
    end

    # Busca todas as mensagens no buffer
    def get_buffered_messages
      buffer_key = redis_key
      message_ids = @redis.smembers(buffer_key)

      Rails.logger.info "[SDR IA] [Buffer] Recuperando #{message_ids.size} mensagens do buffer"

      message_ids.map(&:to_i)
    end

    # Limpa o buffer após processar
    def clear_buffer
      @redis.del(redis_key)
      @redis.del(job_key)
      Rails.logger.info "[SDR IA] [Buffer] Buffer limpo para conversation #{conversation_id}"
    end

    # Verifica se há mensagens no buffer
    def has_buffered_messages?
      @redis.exists?(redis_key) == 1
    end

    # Retorna quantidade de mensagens no buffer
    def buffer_size
      @redis.scard(redis_key)
    end

    private

    def redis_key
      "#{REDIS_KEY_PREFIX}:conv_#{conversation_id}"
    end

    def job_key
      "#{REDIS_KEY_PREFIX}:job:conv_#{conversation_id}"
    end

    def cancel_pending_job
      job_id = @redis.get(job_key)
      return unless job_id

      # Tentar cancelar job no Sidekiq
      begin
        require 'sidekiq/api'

        # Buscar em scheduled jobs
        Sidekiq::ScheduledSet.new.each do |job|
          if job.jid == job_id
            job.delete
            Rails.logger.info "[SDR IA] [Buffer] Job anterior cancelado: #{job_id}"
            break
          end
        end
      rescue StandardError => e
        Rails.logger.warn "[SDR IA] [Buffer] Não foi possível cancelar job: #{e.message}"
      end
    end
  end
end

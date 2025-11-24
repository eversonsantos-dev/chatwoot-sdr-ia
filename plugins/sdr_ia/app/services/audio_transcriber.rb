# frozen_string_literal: true

module SdrIa
  # Serviço para transcrever áudios usando OpenAI Whisper
  class AudioTranscriber
    SUPPORTED_FORMATS = %w[mp3 mp4 mpeg mpga m4a wav webm ogg].freeze
    MAX_FILE_SIZE = 25.megabytes # Limite da API Whisper

    attr_reader :account

    def initialize(account)
      @account = account
      @config = SdrIa.config(account)
    end

    # Transcreve um áudio a partir da URL
    def transcribe_from_url(audio_url)
      Rails.logger.info "[SDR IA] [Audio] Iniciando transcrição de: #{audio_url}"

      # Download do arquivo
      audio_file = download_audio(audio_url)
      return nil unless audio_file

      # Transcrever usando Whisper
      transcription = transcribe_audio(audio_file)

      # Limpar arquivo temporário
      audio_file.close
      audio_file.unlink

      Rails.logger.info "[SDR IA] [Audio] ✅ Transcrição concluída: #{transcription&.truncate(100)}"

      transcription
    rescue StandardError => e
      Rails.logger.error "[SDR IA] [Audio] Erro na transcrição: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      nil
    end

    # Transcreve arquivo de áudio usando OpenAI Whisper API
    def transcribe_audio(audio_file)
      api_key = get_openai_api_key
      unless api_key
        Rails.logger.error "[SDR IA] [Audio] API Key da OpenAI não configurada"
        return nil
      end

      # Verificar tamanho do arquivo
      if audio_file.size > MAX_FILE_SIZE
        Rails.logger.error "[SDR IA] [Audio] Arquivo muito grande: #{audio_file.size} bytes (máx: #{MAX_FILE_SIZE})"
        return nil
      end

      # Fazer request para Whisper API
      uri = URI('https://api.openai.com/v1/audio/transcriptions')
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{api_key}"

      # Criar multipart form data
      boundary = "----WebKitFormBoundary#{SecureRandom.hex(16)}"
      request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"

      # Montar body do request
      body_parts = []

      # Parte 1: arquivo de áudio
      body_parts << "--#{boundary}\r\n"
      body_parts << "Content-Disposition: form-data; name=\"file\"; filename=\"audio.#{get_file_extension(audio_file)}\"\r\n"
      body_parts << "Content-Type: audio/mpeg\r\n\r\n"
      body_parts << audio_file.read
      body_parts << "\r\n"

      # Parte 2: modelo
      body_parts << "--#{boundary}\r\n"
      body_parts << "Content-Disposition: form-data; name=\"model\"\r\n\r\n"
      body_parts << "whisper-1\r\n"

      # Parte 3: idioma (português brasileiro)
      body_parts << "--#{boundary}\r\n"
      body_parts << "Content-Disposition: form-data; name=\"language\"\r\n\r\n"
      body_parts << "pt\r\n"

      # Parte 4: formato de resposta
      body_parts << "--#{boundary}\r\n"
      body_parts << "Content-Disposition: form-data; name=\"response_format\"\r\n\r\n"
      body_parts << "json\r\n"

      # Finalizar
      body_parts << "--#{boundary}--\r\n"

      request.body = body_parts.join

      # Rewind do arquivo
      audio_file.rewind

      # Fazer request
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 60) do |http|
        http.request(request)
      end

      if response.code == '200'
        result = JSON.parse(response.body)
        transcription = result['text']

        Rails.logger.info "[SDR IA] [Audio] Transcrição bem-sucedida: #{transcription&.truncate(200)}"
        transcription
      else
        Rails.logger.error "[SDR IA] [Audio] Erro na API Whisper: #{response.code} - #{response.body}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "[SDR IA] [Audio] Erro ao chamar Whisper API: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      nil
    end

    private

    def download_audio(url)
      uri = URI.parse(url)

      # Criar arquivo temporário
      temp_file = Tempfile.new(['audio', get_extension_from_url(url)])
      temp_file.binmode

      # Download
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', read_timeout: 30) do |http|
        request = Net::HTTP::Get.new(uri)
        http.request(request) do |response|
          if response.code == '200'
            response.read_body do |chunk|
              temp_file.write(chunk)
            end
          else
            Rails.logger.error "[SDR IA] [Audio] Erro ao baixar áudio: #{response.code}"
            temp_file.close
            temp_file.unlink
            return nil
          end
        end
      end

      temp_file.rewind
      Rails.logger.info "[SDR IA] [Audio] Download concluído: #{temp_file.size} bytes"

      temp_file
    rescue StandardError => e
      Rails.logger.error "[SDR IA] [Audio] Erro ao baixar áudio: #{e.message}"
      temp_file&.close
      temp_file&.unlink
      nil
    end

    def get_openai_api_key
      # Buscar do banco primeiro
      sdr_config = SdrIaConfig.for_account(@account)
      return sdr_config.openai_api_key if sdr_config&.openai_api_key.present?

      # Fallback para ENV
      ENV['OPENAI_API_KEY']
    end

    def get_extension_from_url(url)
      uri = URI.parse(url)
      ext = File.extname(uri.path)
      ext.presence || '.ogg' # WhatsApp geralmente usa OGG
    end

    def get_file_extension(file)
      return 'ogg' unless file.respond_to?(:path)

      ext = File.extname(file.path).delete('.')
      SUPPORTED_FORMATS.include?(ext) ? ext : 'ogg'
    end
  end
end

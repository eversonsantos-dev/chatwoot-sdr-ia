# frozen_string_literal: true

require 'net/http'
require 'json'

module SdrIa
  class OpenaiClient
    def initialize(account = nil)
      @config = SdrIa.config(account)

      # Tenta buscar a API key da config do banco primeiro
      @api_key = @config.dig('openai', 'api_key')

      # Fallback para ENV se não encontrar no banco
      @api_key ||= ENV['OPENAI_API_KEY']

      raise Error, "OpenAI API Key não configurada" unless @api_key&.present?
    end

    def analyze_conversation(conversation_history, system_prompt, analysis_prompt)
      uri = URI('https://api.openai.com/v1/chat/completions')
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@api_key}"
      request['Content-Type'] = 'application/json'

      request.body = {
        model: @config['openai']['model'],
        messages: [
          { role: 'system', content: system_prompt },
          { role: 'user', content: analysis_prompt.gsub('{conversation_history}', conversation_history) }
        ],
        temperature: @config['openai']['temperature'],
        max_tokens: @config['openai']['max_tokens'],
        response_format: { type: 'json_object' }
      }.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        result = JSON.parse(response.body)
        content = result.dig('choices', 0, 'message', 'content')
        JSON.parse(content)
      else
        Rails.logger.error "[SDR IA] Erro na API OpenAI: #{response.code} - #{response.body}"
        raise Error, "Erro na API OpenAI: #{response.code}"
      end
    rescue JSON::ParserError => e
      Rails.logger.error "[SDR IA] Erro ao parsear resposta JSON: #{e.message}"
      raise Error, "Resposta inválida da OpenAI"
    rescue StandardError => e
      Rails.logger.error "[SDR IA] Erro inesperado: #{e.message}"
      raise Error, "Erro ao comunicar com OpenAI: #{e.message}"
    end
  end
end

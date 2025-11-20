# frozen_string_literal: true

# SDR IA Initializer
#
# Este arquivo deve ser copiado para: /app/config/initializers/sdr_ia.rb
#
# Ele integra o módulo SDR IA com o Chatwoot, registrando o listener
# para capturar eventos de conversas e mensagens.

Rails.application.config.to_prepare do
  plugin_path = Rails.root.join('plugins/sdr_ia/lib/sdr_ia.rb')
  routes_path = Rails.root.join('plugins/sdr_ia/config/routes.rb')

  if File.exist?(plugin_path)
    require plugin_path

    # Carrega rotas do plugin
    if File.exist?(routes_path)
      load routes_path
      Rails.logger.info "[SDR IA] Rotas carregadas"
    end

    if SdrIa.enabled?
      Rails.logger.info "[SDR IA] Registrando listener no dispatcher..."

      begin
        listener = SdrIa::Listener.instance
        dispatcher = Rails.configuration.dispatcher

        # Registra o listener no async dispatcher
        async_dispatcher = dispatcher.instance_variable_get(:@async_dispatcher)
        async_listeners = async_dispatcher.listeners

        unless async_listeners.include?(listener)
          async_listeners << listener
          Rails.logger.info "[SDR IA] Listener registrado com sucesso"
        else
          Rails.logger.info "[SDR IA] Listener já estava registrado"
        end
      rescue StandardError => e
        Rails.logger.error "[SDR IA] Erro ao registrar listener: #{e.message}"
      end
    else
      Rails.logger.info "[SDR IA] Módulo desabilitado"
    end
  else
    Rails.logger.warn "[SDR IA] Plugin não encontrado em #{plugin_path}"
  end
end

class AsyncDispatcher < BaseDispatcher
  def dispatch(event_name, timestamp, data)
    EventDispatcherJob.perform_later(event_name, timestamp, data)
  end

  def publish_event(event_name, timestamp, data)
    event_object = Events::Base.new(event_name, timestamp, data)
    publish(event_object.method_name, event_object)
  end

  def listeners
    base_listeners = [
      AutomationRuleListener.instance,
      CampaignListener.instance,
      CsatSurveyListener.instance,
      HookListener.instance,
      InstallationWebhookListener.instance,
      NotificationListener.instance,
      ParticipationListener.instance,
      ReportingEventListener.instance,
      WebhookListener.instance
    ]

    # Adicionar SDR IA Listener se estiver disponível e habilitado
    begin
      plugin_path = Rails.root.join('plugins/sdr_ia/lib/sdr_ia.rb')
      if File.exist?(plugin_path)
        require plugin_path unless defined?(SdrIa)

        if SdrIa.respond_to?(:enabled?) && SdrIa.enabled?
          # Carregar listener
          require Rails.root.join('plugins/sdr_ia/app/listeners/sdr_ia_listener') unless defined?(SdrIa::Listener)

          base_listeners << SdrIa::Listener.instance
          Rails.logger.info "[SDR IA] Listener adicionado ao AsyncDispatcher"
        end
      end
    rescue StandardError => e
      Rails.logger.error "[SDR IA] Erro ao adicionar listener: #{e.message}"
      Rails.logger.error e.backtrace.join("\n") if e.backtrace
    end

    base_listeners
  end
end

AsyncDispatcher.prepend_mod_with('AsyncDispatcher')

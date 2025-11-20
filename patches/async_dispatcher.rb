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
    if defined?(SdrIa) && SdrIa.respond_to?(:enabled?) && SdrIa.enabled?
      begin
        base_listeners << SdrIa::Listener.instance
        Rails.logger.info "[SDR IA] Listener adicionado ao AsyncDispatcher"
      rescue StandardError => e
        Rails.logger.error "[SDR IA] Erro ao adicionar listener: #{e.message}"
      end
    end

    base_listeners
  end
end

AsyncDispatcher.prepend_mod_with('AsyncDispatcher')

module OpenProject::Webhooks
  class Hook
    attr_accessor :name, :callback

    def initialize(name, &callback)
      super()
      @name = name
      @callback = callback
    end

    def relative_url
      "webhooks/#{name}"
    end

    def handle(environment = Hash.new, params = Hash.new, user = nil, project = nil)
      callback.call self, environment, params, user, project
    end

    def send_event(event_name, payload)
      ActiveSupport::Notifications.instrument event_name, payload
    end
  end
end

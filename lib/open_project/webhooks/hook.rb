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

    def handle(environment = Hash.new, params = Hash.new, user = nil)
      callback.call self, environment, params, user
    end

  end
end

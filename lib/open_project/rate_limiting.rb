module OpenProject
  module RateLimiting
    module_function

    def active_rules
      @active_rules ||= []
    end

    def default_rules
      @default_rules ||= [
        LostPassword,
        APIV3
      ]
    end

    def set_defaults!
      Rack::Attack.clear_configuration
      Rack::Attack.throttled_responder = ->(request) { OpenProject::RateLimiting.throttled_response(request) }

      @active_rules = []
      default_rules.each do |rule|
        apply(rule)
      end
    end

    def apply(rule)
      unless rule < OpenProject::RateLimiting::Base
        raise ArgumentError.new("Rules need to subclass OpenProject::RateLimiting::Base")
      end

      active_rules << rule.new.apply! if rule.enabled?
    end

    ##
    # Try to find a matching rule to respond with
    # or use the default responder
    def throttled_response(request)
      rule = active_rules.find { |r| r.rule_name == request.env["rack.attack.matched"] }

      if rule
        rule.response(request)
      else
        OpenProject::RateLimiting::Base.response(request)
      end
    end
  end
end

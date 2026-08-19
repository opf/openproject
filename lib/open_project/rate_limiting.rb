# frozen_string_literal: true

module OpenProject
  module RateLimiting
    module_function

    def active_rules
      @active_rules ||= []
    end

    def default_rules
      @default_rules ||= [
        LostPassword,
        APIV3,
        Login
      ]
    end

    def set_defaults!
      Rack::Attack.clear_configuration
      Rack::Attack.throttled_responder = ->(request) { OpenProject::RateLimiting.throttled_response(request) }
      Rack::Attack.blocklisted_responder = ->(request) { OpenProject::RateLimiting.blocklisted_response(request) }

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

    def throttled_response(request)
      matched = request.env["rack.attack.matched"]
      rule = find_rule(matched)
      rule ? rule.response(request) : Base.new.response(request)
    end

    def blocklisted_response(request)
      matched = request.env["rack.attack.matched"]
      rule = find_rule(matched)
      rule ? rule.blocked_response : [403, {}, ["Forbidden\n"]]
    end

    def find_rule(matched)
      active_rules.find { |r| matched == r.rule_name || matched.start_with?("#{r.rule_name}/") }
    end
  end
end

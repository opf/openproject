# frozen_string_literal: true

module OpenProject
  module RateLimiting
    # Memoizes route recognition on the Rack env so every Attack rule can
    # share one lookup per request. Prefers Rails' own path_parameters when
    # the router has already run (e.g. a later controller hook).
    module RecognizedRoute
      ENV_KEY = "open_project.rate_limiting.recognized_route"

      def recognized_route(req)
        RecognizedRoute.fetch(req)
      end

      def recognized_route?(req, controller:, action:)
        RecognizedRoute.matches?(req, controller:, action:)
      end

      class << self
        def fetch(req)
          env = req.env
          return env[ENV_KEY] if env.key?(ENV_KEY)

          env[ENV_KEY] = lookup(req)
        end

        def matches?(req, controller:, action:)
          route = fetch(req)
          route && route[:controller] == controller && route[:action] == action
        end

        private

        def lookup(req)
          params = req.env[ActionDispatch::Http::Parameters::PARAMETERS_KEY]
          return params if params && params[:controller]

          OpenProject::StaticRouting.recognize_route(req.path)
        end
      end
    end
  end
end

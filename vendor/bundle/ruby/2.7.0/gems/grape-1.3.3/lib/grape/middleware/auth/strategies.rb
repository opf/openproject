# frozen_string_literal: true

module Grape
  module Middleware
    module Auth
      module Strategies
        module_function

        def add(label, strategy, option_fetcher = ->(_) { [] })
          auth_strategies[label] = StrategyInfo.new(strategy, option_fetcher)
        end

        def auth_strategies
          @auth_strategies ||= {
            http_basic: StrategyInfo.new(Rack::Auth::Basic, ->(settings) { [settings[:realm]] }),
            http_digest: StrategyInfo.new(Rack::Auth::Digest::MD5, ->(settings) { [settings[:realm], settings[:opaque]] })
          }
        end

        def [](label)
          auth_strategies[label]
        end
      end
    end
  end
end

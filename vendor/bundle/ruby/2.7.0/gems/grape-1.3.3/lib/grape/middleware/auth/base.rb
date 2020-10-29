# frozen_string_literal: true

require 'rack/auth/basic'

module Grape
  module Middleware
    module Auth
      class Base
        include Helpers

        attr_accessor :options, :app, :env

        def initialize(app, **options)
          @app = app
          @options = options
        end

        def call(env)
          dup._call(env)
        end

        def _call(env)
          self.env = env

          if options.key?(:type)
            auth_proc         = options[:proc]
            auth_proc_context = context

            strategy_info = Grape::Middleware::Auth::Strategies[options[:type]]

            throw(:error, status: 401, message: 'API Authorization Failed.') unless strategy_info.present?

            strategy = strategy_info.create(@app, options) do |*args|
              auth_proc_context.instance_exec(*args, &auth_proc)
            end

            strategy.call(env)

          else
            app.call(env)
          end
        end
      end
    end
  end
end

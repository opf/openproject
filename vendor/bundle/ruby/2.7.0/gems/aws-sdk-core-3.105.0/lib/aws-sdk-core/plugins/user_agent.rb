# frozen_string_literal: true

module Aws
  module Plugins
    # @api private
    class UserAgent < Seahorse::Client::Plugin
      option(:user_agent_suffix)

      # @api private
      class Handler < Seahorse::Client::Handler
        def call(context)
          set_user_agent(context)
          @handler.call(context)
        end

        def set_user_agent(context)
          ua = "aws-sdk-ruby3/#{CORE_GEM_VERSION}"

          begin
            ua += " #{RUBY_ENGINE}/#{RUBY_VERSION}"
          rescue
            ua += " RUBY_ENGINE_NA/#{RUBY_VERSION}"
          end

          ua += " #{RUBY_PLATFORM}"

          if context[:gem_name] && context[:gem_version]
            ua += " #{context[:gem_name]}/#{context[:gem_version]}"
          end

          if (execution_env = ENV['AWS_EXECUTION_ENV'])
            ua += " exec-env/#{execution_env}"
          end

          if context.config.user_agent_suffix
            ua += " #{context.config.user_agent_suffix}"
          end

          context.http_request.headers['User-Agent'] = ua.strip
        end
      end

      handler(Handler)
    end
  end
end

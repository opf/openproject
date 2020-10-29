# frozen_string_literal: true

require 'grape/middleware/base'

module Grape
  module Middleware
    module Versioner
      # This middleware sets various version related rack environment variables
      # based on the HTTP Accept-Version header
      #
      # Example: For request header
      #    Accept-Version: v1
      #
      # The following rack env variables are set:
      #
      #    env['api.version']  => 'v1'
      #
      # If version does not match this route, then a 406 is raised with
      # X-Cascade header to alert Grape::Router to attempt the next matched
      # route.
      class AcceptVersionHeader < Base
        def before
          potential_version = (env[Grape::Http::Headers::HTTP_ACCEPT_VERSION] || '').strip

          if strict?
            # If no Accept-Version header:
            if potential_version.empty?
              throw :error, status: 406, headers: error_headers, message: 'Accept-Version header must be set.'
            end
          end

          return if potential_version.empty?

          # If the requested version is not supported:
          throw :error, status: 406, headers: error_headers, message: 'The requested version is not supported.' unless versions.any? { |v| v.to_s == potential_version }

          env[Grape::Env::API_VERSION] = potential_version
        end

        private

        def versions
          options[:versions] || []
        end

        def strict?
          options[:version_options] && options[:version_options][:strict]
        end

        # By default those errors contain an `X-Cascade` header set to `pass`, which allows nesting and stacking
        # of routes (see Grape::Router) for more information). To prevent
        # this behavior, and not add the `X-Cascade` header, one can set the `:cascade` option to `false`.
        def cascade?
          if options[:version_options] && options[:version_options].key?(:cascade)
            options[:version_options][:cascade]
          else
            true
          end
        end

        def error_headers
          cascade? ? { Grape::Http::Headers::X_CASCADE => 'pass' } : {}
        end
      end
    end
  end
end

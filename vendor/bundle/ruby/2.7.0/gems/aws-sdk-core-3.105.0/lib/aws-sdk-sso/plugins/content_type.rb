# frozen_string_literal: true

module Aws
  module SSO
    module Plugins
      class ContentType < Seahorse::Client::Plugin

        def add_handlers(handlers, config)
          handlers.add(Handler)
        end

        class Handler < Seahorse::Client::Handler
          def call(context)
            # Some SSO operations break when given an empty content-type header.
            # The SDK adds this blank content-type header
            # since Net::HTTP provides a default that can break services.
            # We're setting one here even though it's not used or necessary.
            context.http_request.headers['content-type'] = 'application/json'
            @handler.call(context)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Seahorse
  module Client
    module Plugins
      class ContentLength < Plugin

        # @api private
        class Handler < Client::Handler

          def call(context)
            # If it's an IO object and not a File / String / String IO
            if context.http_request.body.respond_to?(:size)
              length = context.http_request.body.size
              context.http_request.headers['Content-Length'] = length
            end
            @handler.call(context)
          end

        end

        handler(Handler, step: :sign, priority: 0)

      end
    end
  end
end

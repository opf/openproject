# frozen_string_literal: true

module Aws
  module Binary

    # @api private
    class EncodeHandler < Seahorse::Client::Handler

      def call(context)
        if eventstream_member = eventstream_input?(context)
          input_es_handler = context[:input_event_stream_handler]
          input_es_handler.event_emitter.encoder = EventStreamEncoder.new(
            context.config.api.metadata['protocol'],
            eventstream_member,
            context.operation.input,
            context.config.sigv4_signer
          )
          context[:input_event_emitter] = input_es_handler.event_emitter
        end
        @handler.call(context)
      end

      private

      def eventstream_input?(ctx)
        ctx.operation.input.shape.members.each do |_, ref|
          return ref if ref.eventstream
        end
      end

    end

  end
end

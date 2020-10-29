module ActionCable
  module Connection
    class Base
      # rubocop:disable Metrics/MethodLength
      def handle_open
        ActiveSupport::Notifications.instrument('connect.action_cable', notification_payload('connect')) do
          begin
            @protocol = websocket.protocol
            connect if respond_to?(:connect)
            subscribe_to_internal_channel
            send_welcome_message

            message_buffer.process!
            server.add_connection(self)
          rescue ActionCable::Connection::Authorization::UnauthorizedError
            respond_to_invalid_request
          end
        end
      end
      # rubocop:enable Metrics/MethodLength

      def handle_close
        ActiveSupport::Notifications.instrument('disconnect.action_cable', notification_payload('disconnect')) do
          logger.info finished_request_message if Lograge.lograge_config.keep_original_rails_log

          server.remove_connection(self)

          subscriptions.unsubscribe_from_all
          unsubscribe_from_internal_channel

          disconnect if respond_to?(:disconnect)
        end
      end

      private

      def notification_payload(method_name)
        { connection_class: self.class.name, action: method_name, data: request.params }
      end
    end
  end
end

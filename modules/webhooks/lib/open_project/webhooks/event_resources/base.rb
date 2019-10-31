module OpenProject::Webhooks::EventResources
  class Base
    class << self
      ##
      # Subscribe for events on this resource schedule the respective
      # webhooks, if any.
      def subscribe!
        notification_names.each do |key|
          OpenProject::Notifications.subscribe(key) do |payload|
            Rails.logger.debug { "[Webhooks Plugin] Handling notification for '#{key}'." }
            handle_notification(payload, key)
          rescue StandardError => e
            Rails.logger.error { "[Webhooks Plugin] Failed notification handling for '#{key}': #{e}" }
          end
        end
      end

      ##
      # Return a mapping of event key to its localized name
      def available_events_map
        Hash[available_actions.map { |symbol| [ prefixed_event_name(symbol), localize_event_name(symbol) ] }]
      end

      ##
      # Get the prefix key for this module
      def prefix_key
        name.demodulize.underscore
      end

      ##
      # Create a prefixed event name
      def prefixed_event_name(action)
        "#{prefix_key}:#{action}"
      end

      def available_actions
        raise NotImplementedError
      end

      ##
      # Localize the given event name
      def localize_event_name(key)
        I18n.t(key, scope: 'webhooks.outgoing.events')
      end

      ##
      # Get the name of this resource
      def resource_name
        raise NotImplementedError
      end

      ##
      # Get the subscriptions for OP::Notifications
      def notification_names
        raise NotImplementedError
      end

      protected

      ##
      # Callback for OP::Notification
      def handle_notification(payload, event_name)
        raise NotImplementedError
      end

      ##
      # Base scope for active webhooks, helper for subclasses
      def active_webhooks
        ::Webhooks::Webhook.where(enabled: true)
      end
    end
  end
end
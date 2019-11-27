require_relative 'base'

module OpenProject::Webhooks::EventResources
  class TimeEntry < Base
    class << self
      def notification_names
        [
          OpenProject::Events::NEW_TIME_ENTRY_CREATED
        ]
      end

      def available_actions
        %i(created)
      end

      def resource_name
        I18n.t 'webhooks.resources.time_entry.name'
      end

      protected

      def handle_notification(payload, event_name)
        event_name = prefixed_event_name(:created)
        active_webhooks.with_event_name(event_name).pluck(:id).each do |id|
          TimeEntryWebhookJob.perform_later(id, payload[:time_entry], event_name)
        end
      end
    end
  end
end

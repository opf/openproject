require_relative "base"

module OpenProject::Webhooks::EventResources
  class Attachment < Base
    class << self
      def notification_names
        [
          OpenProject::Events::ATTACHMENT_CREATED
        ]
      end

      def available_actions
        %i(created)
      end

      def resource_name
        I18n.t :"attributes.attachments"
      end

      protected

      def handle_notification(payload, event_name)
        action = event_name.split("_").last
        event_name = prefixed_event_name(action)

        active_webhooks.with_event_name(event_name).pluck(:id).each do |id|
          AttachmentWebhookJob.perform_later(id, payload[:attachment], event_name)
        end
      end
    end
  end
end

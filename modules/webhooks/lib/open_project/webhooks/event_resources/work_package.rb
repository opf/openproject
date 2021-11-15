require_relative 'base'

module OpenProject::Webhooks::EventResources
  class WorkPackage < Base
    class << self
      def notification_names
        [
          OpenProject::Events::AGGREGATED_WORK_PACKAGE_JOURNAL_READY
        ]
      end

      def available_actions
        %i(updated created)
      end

      def resource_name
        I18n.t :label_work_package_plural
      end

      protected

      def handle_notification(payload, event_name)
        action = payload[:journal].initial? ? "created" : "updated"
        event_name = prefixed_event_name(action)
        work_package = payload[:journal].journable
        active_webhooks.with_event_name(event_name).pluck(:id).each do |id|
          WorkPackageWebhookJob.perform_later(id, work_package, event_name)
        end
      end
    end
  end
end

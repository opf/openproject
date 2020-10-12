module Webhooks
  module Outgoing
    class UpdateWebhookService
      attr_reader :current_user
      attr_reader :webhook

      def initialize(webhook, current_user:)
        @current_user = current_user
        @webhook = webhook
      end

      def call(attributes: {})
        ::Webhooks::Webhook.transaction do
          set_attributes attributes
          raise ActiveRecord::Rollback unless (webhook.errors.empty? && webhook.save)
        end

        ServiceResult.new success: webhook.errors.empty? , errors: webhook.errors, result: webhook
      end

      private

      def set_attributes(params)
        set_selected_projects!(params)
        set_selected_events!(params)

        webhook.attributes = params
      end

      def set_selected_events!(params)
        events = params.delete(:events) || []
        webhook.event_names = events.select(&:present?)
      end

      def set_selected_projects!(params)
        option = params.delete :project_ids
        selected = params.delete :selected_project_ids

        if option == 'all'
          webhook.all_projects = true
        else
          webhook.all_projects = false
          webhook.project_ids = selected
        end
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
        Rails.logger.error "Failed to set project association on webhook: #{e}"
        webhook.errors.add :project_ids, :invalid
      end
    end
  end
end

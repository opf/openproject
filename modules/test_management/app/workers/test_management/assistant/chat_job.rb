# frozen_string_literal: true

module TestManagement
  module Assistant
    # Answers a chat message in the background (as the user who asked).
    class ChatJob < ApplicationJob
      queue_with_priority :above_normal

      def perform(message_id)
        message = TestManagement::AssistantMessage.find_by(id: message_id)
        return unless message&.state == "pending" && message.assistant?

        User.execute_as(message.user) { ChatService.new(message:).call }
      rescue StandardError => e
        Rails.logger.error("Test assistant chat message #{message_id} failed: #{e.class}")
        message&.update_columns(state: "failed", content: I18n.t("test_management.assistant.errors.internal",
                                                                 error: e.class.name.demodulize),
                                updated_at: Time.current)
      end
    end
  end
end

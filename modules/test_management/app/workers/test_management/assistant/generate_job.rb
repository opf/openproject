# frozen_string_literal: true

module TestManagement
  module Assistant
    # Runs a Generate request in the background (as the requesting user).
    class GenerateJob < ApplicationJob
      queue_with_priority :above_normal

      def perform(generation_id)
        generation = TestManagement::AssistantGeneration.find_by(id: generation_id)
        return unless generation&.status == "queued"

        User.execute_as(generation.user) { GenerateService.new(generation:).call }
      rescue StandardError => e
        Rails.logger.error("Test assistant generation #{generation_id} failed: #{e.class}")
        generation&.update_columns(status: "failed", error: I18n.t("test_management.assistant.errors.internal",
                                                                   error: e.class.name.demodulize),
                                   updated_at: Time.current)
      end
    end
  end
end

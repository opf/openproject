# frozen_string_literal: true

module TestManagement
  module AssistantMessages
    # A question to the Test Assistant chat. One open question per user and project at a time.
    class CreateContract < ::ModelContract
      def self.model
        TestManagement::AssistantMessage
      end

      attribute :project
      attribute :user
      attribute :role
      attribute :content
      attribute :state
      attribute :provider_id # 0021: the picked provider and model (ProviderChoice)
      attribute :chosen_model

      validate :user_allowed
      validate :assistant_enabled
      validate :provider_configured
      validate :content_valid
      validate :not_busy

      private

      def user_allowed
        return if model.project.nil?
        return if model.user == user && model.role == "user" && user.allowed_in_project?(:use_test_assistant, model.project)

        errors.add :base, :error_unauthorized
      end

      def assistant_enabled
        return if model.project.nil? || TestManagement::Assistant.enabled_for?(model.project)

        errors.add :base, :tm_assistant_disabled
      end

      def provider_configured
        errors.add :base, :tm_assistant_not_configured unless TestManagement::Assistant.configured?(model.user || user)
      end

      def content_valid
        if model.content.to_s.strip.empty?
          errors.add :content, :blank
        elsif model.content.length > TestManagement::AssistantMessage::MAX_CONTENT
          errors.add :content, :too_long, count: TestManagement::AssistantMessage::MAX_CONTENT
        end
      end

      def not_busy
        return if model.project.nil? || user.nil?

        busy = TestManagement::AssistantMessage.of(user, model.project).where(state: "pending")
                 .exists?(["updated_at > ?", TestManagement::AssistantMessage::STALE_AFTER.ago])
        errors.add :base, :tm_assistant_busy if busy
      end
    end
  end
end

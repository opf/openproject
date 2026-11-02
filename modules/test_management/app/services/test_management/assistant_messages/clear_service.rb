# frozen_string_literal: true

module TestManagement
  module AssistantMessages
    class ClearService
      def initialize(user:, project:)
        @user = user
        @project = project
      end

      def call
        unless TestManagement::Assistant.allowed?(user, project)
          errors = ActiveModel::Errors.new(TestManagement::AssistantMessage.new)
          errors.add(:base, :error_unauthorized)
          return ServiceResult.failure(errors:)
        end

        deleted = TestManagement::AssistantMessage.of(user, project).delete_all
        ServiceResult.success(result: deleted)
      end

      private

      attr_reader :user, :project
    end
  end
end

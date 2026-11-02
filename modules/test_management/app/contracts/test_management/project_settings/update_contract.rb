# frozen_string_literal: true

module TestManagement
  module ProjectSettings
    class UpdateContract < ::ModelContract
      def self.model = TestManagement::ProjectSetting

      attribute :display_prefix
      attribute :folder_tree_layout
      attribute :enable_ci
      attribute :enable_milestones
      attribute :enable_test_plans
      attribute :enable_test_assistant

      validate :user_allowed_to_manage

      private

      def user_allowed_to_manage
        return if model.project.nil?

        errors.add :base, :error_unauthorized unless user.allowed_in_project?(:manage_test_management, model.project)
      end
    end
  end
end

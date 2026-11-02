# frozen_string_literal: true

module TestManagement
  module ProjectSettings
    class UpdateContract < ::ModelContract
      def self.model = TestManagement::ProjectSetting

      attribute :project
      attribute :project_id
      attribute :display_prefix
      stored_attribute :folder_tree_layout, store: :options
      stored_attribute :enable_ci, store: :options
      stored_attribute :enable_milestones, store: :options
      stored_attribute :enable_test_plans, store: :options
      stored_attribute :enable_test_assistant, store: :options

      validate :user_allowed_to_manage

      private

      def user_allowed_to_manage
        return if model.project.nil?

        errors.add :base, :error_unauthorized unless user.allowed_in_project?(:manage_test_management, model.project)
      end
    end
  end
end

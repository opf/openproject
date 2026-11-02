# frozen_string_literal: true

module TestManagement
  module ConfigurationGroups
    class BaseContract < ::ModelContract
      def self.model = TestManagement::ConfigurationGroup

      attribute :project
      attribute :name

      validate :user_allowed_to_manage

      private

      def user_allowed_to_manage
        return if model.project.nil?

        errors.add :base, :error_unauthorized unless user.allowed_in_project?(:manage_test_management, model.project)
      end
    end
  end
end

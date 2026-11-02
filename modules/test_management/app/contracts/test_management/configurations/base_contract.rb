# frozen_string_literal: true

module TestManagement
  module Configurations
    class BaseContract < ::ModelContract
      def self.model = TestManagement::Configuration

      attribute :configuration_group
      attribute :configuration_group_id
      attribute :name

      validate :user_allowed_to_manage

      private

      def user_allowed_to_manage
        project = model.configuration_group&.project
        return if project.nil?

        errors.add :base, :error_unauthorized unless user.allowed_in_project?(:manage_test_management, project)
      end
    end
  end
end

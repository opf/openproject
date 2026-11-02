# frozen_string_literal: true

module TestManagement
  module Labels
    class BaseContract < ::ModelContract
      def self.model = TestManagement::Label

      attribute :name
      attribute :color

      validate :user_allowed_to_manage

      private

      def user_allowed_to_manage
        return if model.project.nil?

        errors.add :base, :error_unauthorized unless user.allowed_in_project?(:manage_test_management, model.project)
      end
    end
  end
end

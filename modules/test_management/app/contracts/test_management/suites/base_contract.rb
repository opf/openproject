# frozen_string_literal: true

module TestManagement
  module Suites
    class BaseContract < ::ModelContract
      def self.model
        TestManagement::Suite
      end

      attribute :project
      attribute :parent
      attribute :parent_id
      attribute :name
      attribute :position

      validate :user_allowed_to_manage
      validate :parent_in_same_project

      private

      def parent_in_same_project
        return if model.parent_id.blank?

        if model.parent.nil? || model.parent.project_id != model.project_id || parent_inside_own_subtree?
          errors.add :parent_id, :invalid
        end
      end

      # Moving a folder below itself or one of its descendants would create a cycle: the
      # subtree disappears from the tree and recursive walks never end.
      def parent_inside_own_subtree?
        return false if model.new_record?

        TestManagement::Suite.subtree_ids(model.project, [model.id]).include?(model.parent_id)
      end

      def user_allowed_to_manage
        return if model.project.nil?

        unless user.allowed_in_project?(:manage_test_suites, model.project)
          errors.add :base, :error_unauthorized
        end
      end
    end
  end
end

# frozen_string_literal: true

module TestManagement
  module Milestones
    class BaseContract < ::ModelContract
      def self.model
        TestManagement::Milestone
      end

      attribute :project
      attribute :name
      attribute :description
      attribute :start_date
      attribute :due_date
      attribute :parent
      attribute :parent_id
      attribute :version
      attribute :version_id
      attribute :created_by
      # References (linked work packages), staged as join records.
      attribute :work_package_ids

      validate :user_allowed_to_manage
      validate :milestones_enabled
      validate :version_shared_with_project
      validate :linked_work_packages_visible

      private

      def user_allowed_to_manage
        return if model.project.nil?

        errors.add :base, :error_unauthorized unless user.allowed_in_project?(:manage_test_milestones, model.project)
      end

      def milestones_enabled
        return if model.project.nil? || TestManagement::ProjectSetting.milestones_enabled?(model.project)

        errors.add :base, :tm_milestones_disabled
      end

      # Same rule as the version field of work packages: versions of the project and versions
      # shared with it.
      def version_shared_with_project
        return if model.version_id.blank? || model.project.nil?
        return unless model.will_save_change_to_version_id?

        errors.add :version, :invalid unless model.project.shared_versions.exists?(id: model.version_id)
      end

      def linked_work_packages_visible
        new_ids = model.milestone_work_packages
                       .select { |link| link.new_record? && !link.marked_for_destruction? }
                       .map(&:work_package_id)
        return if new_ids.empty?

        invisible = new_ids - ::WorkPackage.visible(user).where(id: new_ids).pluck(:id)
        return if invisible.empty?

        errors.add :work_package_ids, :not_visible, ids: invisible.map { |id| "##{id}" }.join(", ")
      end
    end
  end
end

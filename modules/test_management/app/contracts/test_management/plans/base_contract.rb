# frozen_string_literal: true

module TestManagement
  module Plans
    class BaseContract < ::ModelContract
      def self.model = TestManagement::TestPlan

      attribute :project
      attribute :name
      attribute :description
      attribute :milestone
      attribute :milestone_id
      attribute :assigned_to
      attribute :assigned_to_id
      attribute :author
      attribute :start_date
      attribute :end_date
      attribute :work_package_ids

      validate :user_allowed_to_manage
      validate :plans_enabled
      validate :milestone_assignable
      validate :assignee_visible
      validate :linked_work_packages_visible

      private

      def user_allowed_to_manage
        return if model.project.nil?

        errors.add :base, :error_unauthorized unless user.allowed_in_project?(:manage_test_plans, model.project)
      end

      def plans_enabled
        return if model.project.nil? || TestManagement::ProjectSetting.plans_enabled?(model.project)

        errors.add :base, :tm_plans_disabled
      end

      def milestone_assignable
        return if model.milestone_id.blank? || model.project.nil?
        return unless model.will_save_change_to_milestone_id?

        milestone = model.milestone
        if milestone.nil? || milestone.project_id != model.project_id || milestone.completed?
          errors.add :milestone, :invalid
        end
      end

      def assignee_visible
        return if model.assigned_to_id.blank? || !model.will_save_change_to_assigned_to_id?
        return if model.project && TestManagement::Assignees.possible?(model.project, model.assigned_to_id)

        errors.add :assigned_to, :invalid
      end

      def linked_work_packages_visible
        new_ids = model.test_plan_work_packages
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

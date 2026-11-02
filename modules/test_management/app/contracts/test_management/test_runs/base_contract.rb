# frozen_string_literal: true

module TestManagement
  module TestRuns
    class BaseContract < ::ModelContract
      def self.model
        TestManagement::TestRun
      end

      attribute :project
      attribute :name
      attribute :description
      attribute :assigned_to
      attribute :assigned_to_id
      attribute :author
      attribute :start_date
      attribute :end_date
      attribute :selection_mode
      attribute :filter_options
      # Virtual: explicit case selection (specific mode), applied by SyncCasesService.
      attribute :selected_case_ids
      # References (linked work packages), staged as join records.
      attribute :work_package_ids
      # Milestone (0012): optional, same project, milestones enabled, not completed.
      attribute :milestone
      attribute :milestone_id
      attribute :test_plan
      attribute :test_plan_id
      attribute :test_plan_entry_id
      attribute :configuration_ids
      attribute :configuration_label

      validate :user_allowed_to_manage
      validate :assignee_is_possible
      validate :linked_work_packages_visible
      validate :selected_cases_in_project
      validate :filter_options_in_project
      validate :milestone_assignable

      def self.manage_permission
        :add_test_runs
      end

      private

      def user_allowed_to_manage
        return if model.project.nil?

        errors.add :base, :error_unauthorized unless user.allowed_in_project?(self.class.manage_permission, model.project)
      end

      def assignee_is_possible
        return if model.assigned_to_id.blank? || model.project.nil?
        return unless model.will_save_change_to_assigned_to_id?

        possible = TestManagement::Assignees.possible?(model.project, model.assigned_to_id)
        errors.add :assigned_to, :invalid unless possible
      end

      def linked_work_packages_visible
        new_ids = model.test_run_work_packages
                       .select { |link| link.new_record? && !link.marked_for_destruction? }
                       .map(&:work_package_id)
        return if new_ids.empty?

        invisible = new_ids - ::WorkPackage.visible(user).where(id: new_ids).pluck(:id)
        return if invisible.empty?

        errors.add :work_package_ids, :not_visible, ids: invisible.map { |id| "##{id}" }.join(", ")
      end

      # Only checked when the milestone changes, so editing a run of a completed milestone
      # keeps working; the model checks the project.
      def milestone_assignable
        return if model.milestone_id.blank? || model.project.nil?
        return unless model.will_save_change_to_milestone_id?

        milestone = TestManagement::Milestone.find_by(id: model.milestone_id, project_id: model.project.id)
        if milestone.nil? || !TestManagement::ProjectSetting.milestones_enabled?(model.project)
          errors.add :milestone, :invalid
        elsif milestone.completed?
          errors.add :milestone, :tm_milestone_completed
        end
      end

      def selected_cases_in_project
        ids = Array(model.selected_case_ids)
        return if ids.empty? || model.project.nil?

        found = model.project.tm_test_cases.not_deleted.where(id: ids).count
        errors.add :selected_case_ids, :invalid if found != ids.uniq.size
      end

      def filter_options_in_project
        return if model.project.nil? || model.selection_mode != "dynamic"

        label_ids = model.filter_label_ids
        suite_ids = model.filter_suite_ids
        if label_ids.any? && TestManagement::Label.where(project_id: model.project.id, id: label_ids).count != label_ids.uniq.size
          errors.add :filter_options, :invalid
        end
        if suite_ids.any? && model.project.tm_suites.where(id: suite_ids).count != suite_ids.uniq.size
          errors.add :filter_options, :invalid
        end
      end
    end
  end
end

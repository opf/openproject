# frozen_string_literal: true

module TestManagement
  module TestCases
    class UpdateContract < BaseContract
      # Changes that only the system makes on every update (see SetAttributesService).
      SYSTEM_ATTRIBUTES = %w[updated_at updated_by_id lock_version].freeze

      private

      # edit_test_cases allows everything. Without it, a user may still
      #   - change the status (change_test_case_status) and/or
      #   - re-link work packages (link_test_cases_to_work_packages),
      # as long as nothing else changed. Steps and labels are content: nested step
      # changes do not show up in the case's own `changed` list, so they are checked
      # separately (otherwise a status-only user could rewrite the steps).
      def permitted?
        return true if user.allowed_in_project?(:edit_test_cases, model.project)
        return false if content_changed?

        status_changed = model.status_changed?
        links_changed = model.work_package_links_changed?
        return false unless status_changed || links_changed
        return false if status_changed && !user.allowed_in_project?(:change_test_case_status, model.project)
        return false if links_changed && !user.allowed_in_project?(:link_test_cases_to_work_packages, model.project)

        true
      end

      def content_changed?
        (model.changed - SYSTEM_ATTRIBUTES - %w[status]).any? ||
          model.label_links_changed? ||
          steps_changed?
      end

      def steps_changed?
        model.steps.any? { |step| step.new_record? || step.marked_for_destruction? || step.changed? }
      end
    end
  end
end

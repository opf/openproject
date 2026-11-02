# frozen_string_literal: true

module TestManagement
  module TestCases
    class BaseContract < ::ModelContract
      def self.model
        TestManagement::TestCase
      end

      attribute :project
      attribute :suite
      attribute :suite_id
      attribute :title
      attribute :description
      attribute :preconditions
      attribute :priority
      attribute :status
      attribute :automated
      attribute :automation_reference
      attribute :assigned_to
      attribute :assigned_to_id
      attribute :author
      # updated_by is set by the system (SetAttributesService#change_by_system), not by users,
      # so it is intentionally not declared writable here.
      # Steps are written through `steps_attributes=` (accepts_nested_attributes_for).
      # Do NOT declare `attribute :steps_attributes`: contracts are Disposable twins
      # that read every declared property on initialize, and the nested-attributes
      # macro only defines a writer, which caused
      # NoMethodError: undefined method 'steps_attributes'. Nested step changes
      # never show up in the test case's own `changed` list, so they don't need to
      # be whitelisted here.
      attribute :steps
      # Linked work packages. Changes are staged as join records by the
      # SetAttributesService; the attribute is declared so it counts as writable.
      attribute :work_package_ids
      # Labels, edited as a comma-separated list (staged like work package links).
      attribute :label_names

      validate :user_allowed_to_manage
      validate :suite_in_same_project
      validate :linked_work_packages_visible

      private

      def user_allowed_to_manage
        return if model.project.nil?

        unless permitted?
          errors.add :base, :error_unauthorized
        end
      end

      # A folder of another project would leak its name (breadcrumb, exports) and
      # detach the case from its own folder tree.
      def suite_in_same_project
        return if model.suite_id.blank?
        return if model.suite && model.suite.project_id == model.project_id

        errors.add :suite_id, :invalid
      end

      # Only allow linking work packages the acting user can see. Links that already
      # exist are kept as-is (another user may have linked them).
      def linked_work_packages_visible
        new_ids = model.test_case_work_packages
                       .select { |link| link.new_record? && !link.marked_for_destruction? }
                       .map(&:work_package_id)
        return if new_ids.empty?

        visible_ids = ::WorkPackage.visible(user).where(id: new_ids).pluck(:id)
        invisible_ids = new_ids - visible_ids
        return if invisible_ids.empty?

        errors.add :work_package_ids,
                   :not_visible,
                   ids: invisible_ids.map { |id| "##{id}" }.join(", ")
      end

      def permitted?
        raise TestManagement::AbstractMethodError
      end
    end
  end
end

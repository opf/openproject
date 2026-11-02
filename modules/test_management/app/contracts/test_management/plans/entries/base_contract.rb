# frozen_string_literal: true

module TestManagement
  module Plans
    module Entries
      class BaseContract < ::ModelContract
        def self.model = TestManagement::TestPlanEntry

        attribute :test_plan
        attribute :test_plan_id
        attribute :name
        attribute :description
        attribute :position
        attribute :selection_mode
        attribute :filter_options
        attribute :case_ids
        attribute :configuration_ids
        attribute :assigned_to
        attribute :assigned_to_id

        validate :user_allowed_to_manage
        validate :plan_active
        validate :configurations_in_project

        private

        def user_allowed_to_manage
          project = model.test_plan&.project
          return if project.nil?

          errors.add :base, :error_unauthorized unless user.allowed_in_project?(:manage_test_plans, project)
        end

        def plan_active
          return if model.test_plan.nil? || model.test_plan.active?

          errors.add :base, :error_readonly
        end

        def configurations_in_project
          ids = Array(model.configuration_ids).map(&:to_i).reject(&:zero?)
          return if ids.empty? || model.project.nil?

          valid = Configuration.joins(:configuration_group)
                               .where(configuration_groups: { project_id: model.project.id }, id: ids)
                               .pluck(:id)
          errors.add :configuration_ids, :invalid if (ids - valid).any?
        end
      end
    end
  end
end

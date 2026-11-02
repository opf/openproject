# frozen_string_literal: true

module API
  module V3
    module TestManagement
      class PlanRepresenter < ::API::Decorators::Single
        include ::API::Decorators::DateProperty

        link :self do
          { href: api_v3_paths.test_management_plan(represented.id), title: represented.name }
        end

        link :project do
          { href: api_v3_paths.project(represented.project_id) }
        end

        link :milestone do
          next unless represented.milestone_id

          { href: api_v3_paths.test_management_milestone(represented.milestone_id), title: represented.milestone&.name }
        end

        link :complete do
          next unless manage? && represented.active?

          { href: api_v3_paths.test_management_plan_complete(represented.id), method: :post }
        end

        link :reopen do
          next unless manage? && represented.completed?

          { href: api_v3_paths.test_management_plan_reopen(represented.id), method: :post }
        end

        link :rerun do
          next unless manage?

          { href: api_v3_paths.test_management_plan_rerun(represented.id), method: :post }
        end

        link :update do
          next unless manage? && represented.active?

          { href: api_v3_paths.test_management_plan(represented.id), method: :patch }
        end

        link :delete do
          next unless manage?

          { href: api_v3_paths.test_management_plan(represented.id), method: :delete }
        end

        link :entries do
          { href: api_v3_paths.test_management_plan_entries(represented.id) }
        end

        property :id
        property :name
        property :description
        property :state
        property :formatted_id, exec_context: :decorator
        property :milestone_id, as: :milestoneId
        property :assigned_to_id, as: :assignedToId
        property :runs_count, as: :runsCount
        property :pass_rate, as: :passRate
        property :status_counts, as: :statusCounts
        date_property :start_date, as: :startDate
        date_property :end_date, as: :endDate
        date_property :finished_at, as: :finishedAt, datetime: true

        def _type = "TestManagementPlan"

        delegate :formatted_id, to: :represented

        def manage?
          current_user.allowed_in_project?(:manage_test_plans, represented.project)
        end
      end
    end
  end
end

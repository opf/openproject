# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # A milestone with its aggregated progress: the latest status of every case in every
      # non-cancelled run of the milestone and of its sub-milestones. passRate excludes
      # skipped cases (like runs).
      class MilestoneRepresenter < ::API::Decorators::Single
        include ::API::Decorators::DateProperty

        link :self do
          { href: api_v3_paths.test_management_milestone(represented.id), title: represented.name }
        end

        link :project do
          { href: api_v3_paths.project(represented.project_id) }
        end

        link :parent do
          next unless represented.parent_id

          { href: api_v3_paths.test_management_milestone(represented.parent_id), title: represented.parent&.name }
        end

        links :children do
          represented.children.map do |child|
            { href: api_v3_paths.test_management_milestone(child.id), title: child.name }
          end
        end

        link :version do
          next unless represented.version_id

          { href: api_v3_paths.version(represented.version_id), title: represented.version&.name }
        end

        # Linked work packages the current user may see.
        links :workPackages do
          ids = represented.linked_work_package_ids
          next [] if ids.empty?

          ::WorkPackage.visible(current_user).where(id: ids).order(:id).pluck(:id, :subject).map do |id, subject|
            { href: api_v3_paths.work_package(id), title: subject }
          end
        end

        link :runs do
          { href: "#{api_v3_paths.project_test_management_runs(represented.project_id)}?milestoneId=#{represented.id}" }
        end

        link :start do
          next unless manage? && represented.status == "open"

          { href: api_v3_paths.test_management_milestone_start(represented.id), method: :post }
        end

        link :complete do
          next unless manage? && !represented.completed?

          { href: api_v3_paths.test_management_milestone_complete(represented.id), method: :post }
        end

        link :reopen do
          next unless manage? && represented.completed?

          { href: api_v3_paths.test_management_milestone_reopen(represented.id), method: :post }
        end

        link :update do
          next unless manage?

          { href: api_v3_paths.test_management_milestone(represented.id), method: :patch }
        end

        link :delete do
          next unless manage?

          { href: api_v3_paths.test_management_milestone(represented.id), method: :delete }
        end

        property :id
        property :name
        property :description, getter: ->(*) { { format: "markdown", raw: description.to_s } }
        property :status
        property :overdue, getter: ->(*) { overdue? }
        date_property :start_date, render_nil: true
        date_property :due_date, render_nil: true
        date_time_property :started_at, render_nil: true
        date_time_property :completed_at, render_nil: true
        property :status_counts, as: :statusCounts, getter: ->(*) { status_counts }
        property :total_cases, as: :totalCases, getter: ->(*) { total_cases }
        property :pass_rate, as: :passRate, getter: ->(*) { pass_rate }
        property :runs_count, as: :runsCount, getter: ->(*) { runs_count }
        date_time_property :created_at
        date_time_property :updated_at

        def manage?
          current_user.allowed_in_project?(:manage_test_milestones, represented.project)
        end

        def _type
          "TestManagementMilestone"
        end
      end
    end
  end
end

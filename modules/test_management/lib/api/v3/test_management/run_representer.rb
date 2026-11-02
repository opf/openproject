# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # A test run with its status counts and pass rate (skipped tests are not
      # part of the pass rate; they are reported separately in statusCounts).
      class RunRepresenter < ::API::Decorators::Single
        include ::API::Decorators::DateProperty

        link :self do
          { href: api_v3_paths.test_management_run(represented.id), title: represented.name }
        end

        link :project do
          { href: api_v3_paths.project(represented.project_id) }
        end

        link :imports do
          { href: api_v3_paths.test_management_run_imports(represented.id) }
        end

        link :iterations do
          { href: api_v3_paths.test_management_run_iterations(represented.id) }
        end

        link :connection do
          next unless represented.connection_id

          { href: api_v3_paths.test_management_ci_connection(represented.connection_id),
            title: represented.connection&.name }
        end

        link :milestone do
          next unless represented.milestone_id

          { href: api_v3_paths.test_management_milestone(represented.milestone_id), title: represented.milestone&.name }
        end

        link :plan do
          next unless represented.test_plan_id

          { href: api_v3_paths.test_management_plan(represented.test_plan_id), title: represented.test_plan&.name }
        end

        link :attachments do
          { href: api_v3_paths.test_management_run_attachments(represented.id) }
        end

        link :complete do
          next unless represented.active?

          { href: api_v3_paths.test_management_run_complete(represented.id), method: :post }
        end

        link :cancel do
          next unless represented.active?

          { href: api_v3_paths.test_management_run_cancel(represented.id), method: :post }
        end

        property :id
        property :name
        property :state
        property :source
        property :completion_source, as: :completionSource, render_nil: true
        property :selection_mode, as: :selectionMode
        property :external_ref, as: :externalRef, render_nil: true
        property :test_plan_id, as: :planId, render_nil: true
        property :configuration_ids, as: :configurationIds, getter: ->(*) { selected_configuration_ids }
        property :configuration_label, as: :configurationLabel, render_nil: true
        property :ci, getter: ->(*) { ci_info }
        property :status_counts, as: :statusCounts, getter: ->(*) { status_counts }, exec_context: :decorator
        property :total_cases, as: :totalCases, getter: ->(*) { status_counts.values.sum }, exec_context: :decorator
        property :pass_rate, as: :passRate,
                             getter: ->(*) { ::TestManagement::TestRun.pass_rate(status_counts) },
                             exec_context: :decorator
        property :current_iteration, as: :currentIteration, exec_context: :decorator, render_nil: true,
                                     getter: ->(*) { represented.current_iteration_number }
        property :iterations_count, as: :iterationsCount, getter: ->(*) { iterations_count }
        property :unmatched_tests, as: :unmatchedTests, getter: ->(*) { unmatched_tests_count }
        # Last "Run in CI" (0011): { status, url, error, triggeredAt } or null.
        property :ci_trigger, as: :ciTrigger, exec_context: :decorator, render_nil: true,
                              getter: ->(*) { ci_trigger }
        # Only on GET /test_management/runs/{id} (not in collections).
        property :run_cases, as: :runCases, exec_context: :decorator,
                             getter: ->(*) { run_case_summaries if @with_cases }
        date_time_property :finished_at, render_nil: true
        date_time_property :created_at
        date_time_property :updated_at

        def initialize(model, current_user:, embed_links: false, with_cases: false)
          @with_cases = with_cases
          super(model, current_user:, embed_links:)
        end

        def status_counts
          @status_counts ||= represented.status_counts
        end

        def run_case_summaries
          represented.run_cases.includes(:test_case).order(:id).map do |run_case|
            {
              id: run_case.id,
              testCaseId: run_case.test_case_id,
              title: run_case.title,
              status: run_case.effective_status,
              automationReference: run_case.test_case&.automation_reference,
              _links: { self: { href: api_v3_paths.test_management_run_case(run_case.id) } }
            }
          end
        end

        def ci_trigger
          return nil if represented.ci_trigger_status.blank?

          { "status" => represented.ci_trigger_status, "url" => represented.ci_trigger_url,
            "error" => represented.ci_trigger_error,
            "triggeredAt" => represented.ci_triggered_at&.utc&.iso8601 }
        end

        def _type
          "TestManagementRun"
        end
      end
    end
  end
end

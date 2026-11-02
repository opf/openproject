# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # A case inside a run, with its results (manual and automated).
      class RunCaseRepresenter < ::API::Decorators::Single
        include ::API::Decorators::DateProperty

        link :self do
          { href: api_v3_paths.test_management_run_case(represented.id), title: represented.title }
        end

        link :run do
          { href: api_v3_paths.test_management_run(represented.test_run_id) }
        end

        link :attachments do
          { href: api_v3_paths.test_management_run_case_attachments(represented.id) }
        end

        link :addResult do
          next unless represented.test_run.active? &&
                      (current_user.allowed_in_project?(:execute_test_runs, represented.project) ||
                       current_user.allowed_in_project?(:add_test_runs, represented.project))

          { href: api_v3_paths.test_management_run_case_results(represented.id), method: :post }
        end

        link :addAttachment do
          next unless represented.attachments_addable?(current_user)

          { href: api_v3_paths.test_management_run_case_attachments(represented.id), method: :post }
        end

        property :id
        property :test_case_id, as: :testCaseId
        property :title
        property :status, getter: ->(*) { effective_status }
        property :assigned_to_id, as: :assigneeId, render_nil: true
        property :results, exec_context: :decorator, getter: ->(*) { result_hashes }
        date_time_property :updated_at

        # Results oldest first, each with errorMessage / errorTrace / failedStep / stepResults (0020).
        def result_hashes
          represented.results.includes(:step_results).map { |result| ResultRepresenter.hash_for(result) }
        end

        def _type
          "TestManagementRunCase"
        end
      end
    end
  end
end

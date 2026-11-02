# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # One result of a run case (0020), with the printed error and the step results.
      #   GET  /api/v3/test_management/results/:id
      #   POST /api/v3/test_management/run_cases/:id/results (manual result, 201)
      class ResultRepresenter < ::API::Decorators::Single
        include ::API::Decorators::DateProperty

        link :self do
          { href: api_v3_paths.test_management_result(represented.id) }
        end

        link :runCase do
          { href: api_v3_paths.test_management_run_case(represented.run_case_id) }
        end

        property :id
        property :status
        property :source
        property :comment, render_nil: true
        property :error_message, as: :errorMessage, render_nil: true
        property :error_trace, as: :errorTrace, render_nil: true
        property :duration_ms, as: :durationMs, render_nil: true
        property :external_id, as: :externalId, render_nil: false
        property :import_id, as: :importId, render_nil: false
        property :iteration_number, as: :iteration, exec_context: :decorator, getter: ->(*) {
          represented.iteration&.number
        }, render_nil: true
        property :failed_step, as: :failedStep, exec_context: :decorator, getter: ->(*) {
          represented.failed_step&.number
        }, render_nil: true
        property :user_name, as: :userName, exec_context: :decorator, getter: ->(*) { represented.user&.name }, render_nil: true
        property :step_results, as: :stepResults, exec_context: :decorator,
                                getter: ->(*) { represented.step_results.map { |step| StepResultHash.call(step) } }
        date_time_property :created_at

        def self.hash_for(result)
          {
            id: result.id, status: result.status, source: result.source, comment: result.comment,
            durationMs: result.duration_ms, externalId: result.external_id, importId: result.import_id,
            details: result.details_hash.slice("projectName", "retry", "flaky", "attachmentIds", "ciRunUrl"),
            errorMessage: result.error_message, errorTrace: result.error_trace,
            failedStep: result.failed_step&.number,
            stepResults: result.step_results.map { |step| StepResultHash.call(step) }.presence,
            createdAt: result.created_at&.utc&.iso8601
          }.compact
        end

        def _type
          "TestManagementResult"
        end
      end
    end
  end
end

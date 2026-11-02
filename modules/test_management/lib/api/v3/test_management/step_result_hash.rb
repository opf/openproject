# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # One step result as embedded in results (0020), `_type` "TestManagementStepResult".
      # Texts are returned as plain strings (clients must not render them as HTML).
      module StepResultHash
        module_function

        def call(step)
          {
            _type: "TestManagementStepResult",
            id: step.id,
            kind: step.kind,
            position: step.number,
            testStepId: step.test_step_id,
            title: step.label.presence,
            reportedTitle: step.reported_title,
            status: step.status,
            matchedBy: step.match_method,
            durationMs: step.duration_ms,
            errorMessage: step.error_message,
            errorTrace: step.error_trace,
            actualResult: step.actual_result,
            substeps: step.substeps.presence,
            attachments: step.attachment_refs.map { |ref| ref.slice("name", "attachmentId") }.presence
          }.compact
        end
      end
    end
  end
end

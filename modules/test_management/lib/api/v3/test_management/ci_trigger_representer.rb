# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # Outcome of "Run in CI" (TestManagement::CiTriggers::TriggerService::Outcome): the run and
      # iteration the results will be filed into, and how the CI provider answered.
      #   status      triggered | failed | manual (inbound-only connection, 0015: nothing was sent;
      #               `manualStart` holds the CI variables and a command to start the pipeline by hand)
      #   url         CI run / pipeline / job URL (when the provider returns one)
      #   externalId  provider run id, pipeline id or Jenkins queue item URL (if returned)
      #   error       provider error ("HTTP 422: …"), without secrets
      class CiTriggerRepresenter < ::API::Decorators::Single
        link :run do
          { href: api_v3_paths.test_management_run(represented.run.id), title: represented.run.name }
        end

        link :iteration do
          { href: api_v3_paths.test_management_run_iteration(represented.run.id, represented.iteration.number) }
        end

        link :connection do
          next unless represented.iteration.connection_id

          { href: api_v3_paths.test_management_ci_connection(represented.iteration.connection_id) }
        end

        property :status
        property :run_id, as: :runId, exec_context: :decorator, getter: ->(*) { represented.run.id }
        property :iteration_id, as: :iterationId, exec_context: :decorator, getter: ->(*) { represented.iteration.id }
        property :iteration_number, as: :iterationNumber, exec_context: :decorator,
                                    getter: ->(*) { represented.iteration.number }
        property :ref
        property :grep
        property :url, render_nil: true
        property :external_id, as: :externalId, render_nil: true
        property :error, render_nil: true
        property :manual_start, as: :manualStart, exec_context: :decorator,
                                getter: ->(*) { manual_start_hash },
                                render_nil: false

        def manual_start_hash
          return nil unless represented.status == "manual" && represented.iteration.connection

          start = ::TestManagement::CiTriggers::ManualStart.new(
            connection: represented.iteration.connection, run: represented.run, iteration: represented.iteration,
            op_url: "#{Setting.protocol}://#{Setting.host_name}"
          )
          { "variables" => start.variables, "command" => start.command }
        end

        def _type
          "TestManagementCiTrigger"
        end
      end
    end
  end
end

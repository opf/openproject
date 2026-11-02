# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # Response of an ingest: the import summary plus the run it reported into.
      class IngestResultRepresenter < ::API::Decorators::Single
        link :self do
          { href: api_v3_paths.test_management_import(represented.import.id) }
        end

        link :run do
          { href: api_v3_paths.test_management_run(represented.run.id), title: represented.run.name }
        end

        link :iteration do
          next unless represented.iteration

          { href: api_v3_paths.test_management_run_iteration(represented.run.id, represented.iteration.number) }
        end

        link :connection do
          next unless represented.connection

          { href: api_v3_paths.test_management_ci_connection(represented.connection.id), title: represented.connection.name }
        end

        property :created_run, as: :createdRun, getter: ->(*) { created_run? }
        property :created_iteration, as: :createdIteration, getter: ->(*) { created_iteration? }
        property :mode
        property :iteration, exec_context: :decorator, render_nil: true,
                             getter: ->(*) {
                               iteration = represented.iteration
                               iteration && { id: iteration.id, number: iteration.number, name: iteration.display_name }
                             }
        property :replay, getter: ->(*) { replay? }
        property :import, exec_context: :decorator,
                          getter: ->(*) { ImportRepresenter.new(represented.import, current_user:).to_hash }
        property :run, exec_context: :decorator,
                       getter: ->(*) { RunRepresenter.new(represented.run.reload, current_user:).to_hash }

        def _type
          "TestManagementIngestResult"
        end
      end
    end
  end
end

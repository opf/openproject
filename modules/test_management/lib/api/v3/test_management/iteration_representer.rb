# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # One iteration (execution) of a test run. statusCounts / passRate use the last result
      # of every run case within the iteration; for the current iteration they equal the run's.
      class IterationRepresenter < ::API::Decorators::Single
        include ::API::Decorators::DateProperty

        link :self do
          { href: api_v3_paths.test_management_run_iteration(represented.test_run_id, represented.number),
            title: represented.display_name }
        end

        link :run do
          { href: api_v3_paths.test_management_run(represented.test_run_id) }
        end

        link :connection do
          next unless represented.connection_id

          { href: api_v3_paths.test_management_ci_connection(represented.connection_id) }
        end

        property :id
        property :number
        property :name, getter: ->(*) { display_name }
        property :source
        property :current, exec_context: :decorator, getter: ->(*) { current? }
        property :external_ref, as: :externalRef, render_nil: true
        property :ci, getter: ->(*) { ci_info }
        property :status_counts, as: :statusCounts, exec_context: :decorator, getter: ->(*) { status_counts }
        property :total_cases, as: :totalCases, exec_context: :decorator, getter: ->(*) { status_counts.values.sum }
        property :pass_rate, as: :passRate, exec_context: :decorator,
                             getter: ->(*) { ::TestManagement::TestRun.pass_rate(status_counts) }
        date_time_property :created_at

        def initialize(model, current_user:, embed_links: false, current_number: nil)
          @current_number = current_number
          super(model, current_user:, embed_links:)
        end

        def current?
          return represented.preloaded_current unless represented.preloaded_current.nil?

          @current_number ||= represented.test_run.iterations.maximum(:number)
          represented.number == @current_number
        end

        def status_counts
          @status_counts ||= represented.preloaded_status_counts ||
                             (current? ? represented.test_run.status_counts : represented.status_counts)
        end

        def _type
          "TestManagementRunIteration"
        end
      end
    end
  end
end

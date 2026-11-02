# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # One automation upload into a run (counts, unmatched tests, warnings).
      class ImportRepresenter < ::API::Decorators::Single
        include ::API::Decorators::DateProperty

        link :self do
          { href: api_v3_paths.test_management_import(represented.id) }
        end

        link :run do
          next unless represented.test_run_id

          { href: api_v3_paths.test_management_run(represented.test_run_id) }
        end

        link :project do
          { href: api_v3_paths.project(represented.project_id) }
        end

        property :id
        property :format
        property :state
        property :parsed_count, as: :parsedCount
        property :matched_count, as: :matchedCount
        property :created_cases_count, as: :createdCasesCount
        property :unmatched_count, as: :unmatchedCount
        property :attachments_count, as: :attachmentsCount
        property :unmatched, getter: ->(*) { unmatched_list }
        property :warnings, getter: ->(*) { warnings_list }
        property :digest
        property :external_ref, as: :externalRef, render_nil: true
        property :iteration, exec_context: :decorator, render_nil: true,
                             getter: ->(*) { represented.iteration&.number }
        date_time_property :created_at

        def _type
          "TestManagementAutomationImport"
        end
      end
    end
  end
end

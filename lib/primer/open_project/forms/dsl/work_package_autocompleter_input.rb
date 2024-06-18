# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        class WorkPackageAutocompleterInput < AutocompleterInput
          def derive_autocompleter_options(options)
            options.reverse_merge(
              component: "opce-autocompleter",
              resource: "work_packages",
              searchKey: "subjectOrId"
            )
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        class ProjectAutocompleterInput < AutocompleterInput
          def derive_autocompleter_options(options)
            options.reverse_merge!(
              component: "opce-project-autocompleter",
              defaultData: false,
              filters: [{ name: "active", operator: "=", values: ["t"] }]
            )

            if options[:disabledProjects]
              options[:disabledProjects].stringify_keys!
            end

            options
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        module InputMethods
          def autocompleter(**, &)
            add_input AutocompleterInput.new(builder: @builder, form: @form, **, &)
          end

          def work_package_autocompleter(**, &)
            add_input WorkPackageAutocompleterInput.new(builder: @builder, form: @form, **, &)
          end

          def project_autocompleter(**, &)
            add_input ProjectAutocompleterInput.new(builder: @builder, form: @form, **, &)
          end

          def rich_text_area(**)
            add_input RichTextAreaInput.new(builder: @builder, form: @form, **)
          end

          def storage_manual_project_folder_selection(**)
            add_input StorageManualProjectFolderSelectionInput.new(builder: @builder, form: @form, **)
          end
        end
      end
    end
  end
end

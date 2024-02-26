# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        module InputMethods
          def autocompleter(**, &block)
            add_input AutocompleterInput.new(builder: @builder, form: @form, **, &block)
          end

          def user_autocompleter(**, &block)
            add_input UserAutocompleterInput.new(builder: @builder, form: @form, **, &block)
          end

          def rich_text_area(**)
            add_input RichTextAreaInput.new(builder: @builder, form: @form, **)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module OpPrimer
  module Forms
    module Dsl
      module InputMethods
        def autocompleter(**)
          add_input AutocompleterInput.new(builder: @builder, form: @form, **)
        end

        def rich_text_area(**)
          add_input RichTextAreaInput.new(builder: @builder, form: @form, **)
        end
      end
    end
  end
end

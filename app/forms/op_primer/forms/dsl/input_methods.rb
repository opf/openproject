# frozen_string_literal: true

module OpPrimer
  module Forms
    module Dsl
      module InputMethods
        def field_set(**, &)
          add_input InputFieldSet.new(builder: @builder, form: @form, **, &)
        end
      end
    end
  end
end

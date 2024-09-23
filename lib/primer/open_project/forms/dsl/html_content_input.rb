# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        class HtmlContentInput < Primer::Forms::Dsl::Input
          def initialize(**system_arguments, &html_block)
            @html_block = html_block

            super(**system_arguments)
          end

          def to_component
            HtmlContent.new(&@html_block)
          end

          def type
            :html_content
          end

          def name = nil
          def form_control? = false
        end
      end
    end
  end
end

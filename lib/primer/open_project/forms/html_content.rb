# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class HtmlContent < Primer::Forms::BaseComponent
        def initialize(&html_block)
          super()
          @html_block = html_block
        end

        def rendered_html_content
          @view_context.capture do
            @view_context.instance_exec(&@html_block)
          end
        end
      end
    end
  end
end

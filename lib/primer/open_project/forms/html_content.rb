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

        def hidden? = false

        def perform_render(&)
          super(&@html_block)
        end
      end
    end
  end
end

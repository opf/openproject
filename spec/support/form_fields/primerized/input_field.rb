require_relative 'form_field'

module FormFields
  module Primerized
    class InputField < FormField
      delegate :fill_in, to: :input_element

      def field_container
        page.find(selector).first(:xpath, ".//..").first(:xpath, ".//..")
      end

      def input_element
        field_container
      end

      def send_keys(*)
        input_element.send_keys(*)
      end

      # expectations

      def expect_error(string = nil)
        expect(page).to have_css("#{selector}[invalid='true']")
        expect(field_container).to have_content(string) if string
      end
    end
  end
end

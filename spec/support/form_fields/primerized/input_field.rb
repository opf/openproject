require_relative "form_field"

module FormFields
  module Primerized
    class InputField < FormField
      delegate :fill_in, :check, :uncheck, to: :input_element

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

      def expect_value(value)
        scroll_to_element(field_container)
        expect(field_container).to have_css("input") { |el| el.value == value }
      end
    end
  end
end

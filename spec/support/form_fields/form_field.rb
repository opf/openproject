# frozen_string_literal: true

module FormFields
  class FormField
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include RSpec::Matchers

    attr_reader :property, :selector

    def initialize(property, selector: nil)
      @property = property
      @selector = selector || "[data-test-selector='#{property_name}']"
    end

    def expect_visible
      raise NotImplementedError
    end

    def expect_not_visible
      expect(page).to have_no_selector(selector)
    end

    def expect_required
      expect(field_container)
        .to have_css ".spot-form-field--label-indicator", text: "*"
    end

    def field_container
      page.find(selector)
    end

    def property_name
      if property.is_a? CustomField
        property.attribute_name(:camel_case)
      else
        property.to_s
      end
    end
  end
end

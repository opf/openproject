module FormFields
  class FormField
    include Capybara::DSL
    include RSpec::Matchers

    attr_reader :property, :selector

    def initialize(property, selector: nil)
      @property = property
      @selector = selector || "[data-qa-field-name='#{property_name}']"
    end

    def expect_visible
      raise NotImplementedError
    end

    def expect_required
      expect(field_container)
        .to have_selector '.op-form-field--label-indicator', text: '*'
    end

    def field_container
      page.find(selector)
    end

    def property_name
      if property.is_a? CustomField
        "customField#{property.id}"
      else
        property.to_s
      end
    end
  end
end
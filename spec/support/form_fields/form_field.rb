module FormFields
  class SelectFormField
    include Capybara::DSL
    include RSpec::Matchers

    attr_reader :property

    def initialize(property)
      @property = property
    end

    def expect_selected(*values)
      values.each do |val|
        expect(field_container).to have_selector('.ng-value', text: val)
      end
    end

    def select_option(*values)
      values.each do |val|
        field_container.find('.ng-select-container').click
        page.find('.ng-option', text: val).click
        sleep 1
      end
    end

    def field_container
      page.find("[data-field-name='#{property_name}']")
    end

    def property_name
      @property_name ||= begin
        if property.is_a? CustomField
          "customField#{property.id}"
        else
          property.to_s
        end
      end
    end
  end
end
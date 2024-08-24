require_relative "form_field"

module FormFields
  class SelectFormField < FormField
    def expect_selected(*values)
      values.each do |val|
        expect(field_container).to have_css(".ng-value", text: val)
      end
    end

    def expect_no_option(option)
      field_container.find(".ng-select-container").click

      expect(page)
        .to have_no_css(".ng-option", text: option, visible: :all)
    end

    def expect_visible
      expect(field_container).to have_css("ng-select")
    end

    def select_option(*values)
      values.each do |val|
        field_container.find(".ng-select-container").click
        page.find(".ng-option", text: val, visible: :all).click
        sleep 1
      end
    end

    def search(text)
      field_container.find(".ng-select-container input").set text
    end
  end
end

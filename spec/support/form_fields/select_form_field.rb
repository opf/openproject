require_relative './form_field'

module FormFields
  class SelectFormField < FormField
    def expect_selected(*values)
      values.each do |val|
        expect(field_container).to have_selector('.ng-value', text: val)
      end
    end

    def expect_visible
      expect(field_container).to have_selector('ng-select')
    end

    def select_option(*values)
      values.each do |val|
        field_container.find('.ng-select-container').click
        page.find('.ng-option', text: val, visible: :all).click
        sleep 1
      end
    end
  end
end
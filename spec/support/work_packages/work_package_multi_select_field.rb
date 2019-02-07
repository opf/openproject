require_relative './work_package_field'

class WorkPackageMultiSelectField < WorkPackageField

  def multiselect?
    field_container.has_selector?('.wp-inline-edit--toggle-multiselect .icon-minus2')
  end

  def expect_save_button(enabled: true)
    if enabled
      expect(field_container).to have_no_selector("#{control_link}[disabled]")
    else
      expect(field_container).to have_selector("#{control_link}[disabled]")
    end
  end

  def save!
    submit_by_click
  end

  def field_type
    'ng-select'
  end

  def control_link(action = :save)
    raise 'Invalid link' unless [:save, :cancel].include?(action)
    ".inplace-edit--control--#{action}"
  end
end

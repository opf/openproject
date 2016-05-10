class WorkPackageTextAreaField < WorkPackageField

  attr_reader :trigger

  def initialize(context, property_name, selector: nil, trigger: nil)
    super(context, property_name, selector: selector)
    @trigger = trigger
  end

  def trigger_link_selector
    @trigger || super
  end

  def input_selector
    'textarea'
  end

  def submit_by_click
    element.find('.inplace-edit--control--save').click
  end

  def submit_by_keyboard
    input_element.native.send_keys :tab
  end

  def cancel_by_click
    element.find('.inplace-edit--control--cancel').click
  end

  def field_type
    'textarea'
  end
end

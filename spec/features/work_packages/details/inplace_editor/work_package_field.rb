class WorkPackageField

  attr_reader :element

  def initialize(element)
    @element = element
  end

  def read_state_text
    @element.find('.inplace-edit--read-value span').text
  end

  def trigger_link
    @element.find trigger_link_selector
  end

  def trigger_link_selector
    'a.inplace-editing--trigger-link'
  end

  def activate_edition
    @element.click
  end

  def input_element
    @element.find('.focus-input')
  end

  def submit_by_click
    @element.find('.inplace-edit--control--save').click
  end

  def submit_by_enter
    input_element.native.send_keys :return
  end

  def cancel_by_click
    @element.find('.inplace-edit--control--cancel').click
  end

  def cancel_by_escape
    input_element.native.send_keys :escape
  end

  def editable?
    !!@element.find('.inplace-edit--write') rescue false
  end
end

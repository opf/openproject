require_relative './edit_field'

class WorkPackageStatusField < EditField
  def initialize(context)
    @context = context
    @selector = ".wp-status-button"
  end

  def input_selector
    '#wp-status-context-menu'
  end

  def input_element
    page.find "#{input_selector}"
  end

  def display_element
    @context.find "#{@selector} .button"
  end

  def activate!
    retry_block do
      unless active?
        scroll_to_and_click(display_element)
      end
    end
  end
  alias :activate_edition :activate!

  def update(value, save: true, expect_failure: false)
    retry_block do
      activate_edition
      set_value value

      expect_state! open: expect_failure
    end
  end

  def set_value(content)
    input_element.find('a', text: content).click
  end

  def active?
    page.has_selector? input_selector, wait: 1
  end
  alias :editing? :active?

  def expect_active!
    expect(page).to have_selector(input_selector, wait: 10),
          "Expected context menu for status."
  end

  def expect_inactive!
    expect(page).to have_no_selector(input_selector)
  end
end

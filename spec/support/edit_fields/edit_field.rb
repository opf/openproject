class EditField
  include Capybara::DSL
  include Capybara::RSpecMatchers
  include RSpec::Matchers
  include ::Components::Autocompleter::NgSelectAutocompleteHelpers

  attr_reader :selector,
              :property_name,
              :context

  attr_accessor :field_type

  def initialize(context,
                 property_name,
                 selector: nil)

    @property_name = property_name.to_s
    @context = context
    @field_type = derive_field_type

    @selector = selector || ".inline-edit--container.#{property_name}"
  end

  def field_container
    context.find @selector
  end

  def display_selector
    '.inline-edit--display-field'
  end

  def display_element
    context.find "#{@selector} #{display_selector}"
  end

  def input_element
    context.find "#{@selector} #{input_selector}"
  end

  def label_element
    context.find ".wp-replacement-label[data-qa-selector='#{property_name}']"
  end

  def clear(with_backspace: false)
    if with_backspace
      input_element.set(' ', fill_options: { clear: :backspace })
    else
      input_element.native.clear
    end
  end

  def expect_read_only
    expect(context).to have_selector "#{@selector} #{display_selector}.-read-only"
  end

  def expect_state_text(text)
    expect(context).to have_selector(@selector, text:)
  end

  alias :expect_text :expect_state_text

  def expect_value(value)
    expect(input_element.value).to eq(value)
  end

  def expect_display_value(value)
    expect(display_element)
      .to have_content(value)
  end

  ##
  # Activate the field and check it opened correctly
  def activate!(expect_open: true)
    retry_block do
      unless active?
        SeleniumHubWaiter.wait unless using_cuprite?
        scroll_to_and_click(display_element)
        SeleniumHubWaiter.wait unless using_cuprite?
      end

      if expect_open && !active?
        raise "Expected field for attribute '#{property_name}' to be active."
      end
    end
  end

  alias :activate_edition :activate!

  def openSelectField
    autocomplete_selector.click
    wait_for_network_idle if using_cuprite?
  end

  def set_select_field_value(value)
    retry_block do
      openSelectField
      set_value value
    end
  end

  def expect_state!(open:)
    if open
      expect_active!
    else
      expect_inactive!
    end
  end

  def active?
    @context.has_selector? "#{@selector} #{input_selector}", wait: 1
  end

  alias :editing? :active?

  def expect_active!
    expect(field_container)
      .to have_selector(field_type, wait: 10),
          "Expected field input type '#{field_type}' for attribute '#{property_name}'."

    # Also ensure the element is not disabled
    expect_enabled!
  end

  def expect_inactive!
    expect(field_container).to have_selector(display_selector, wait: 10)
    expect(field_container).not_to have_selector(field_type)
  end

  def expect_enabled!
    expect(@context).not_to have_selector "#{@selector} #{input_selector}[disabled]"
  end

  def expect_invalid
    expect(page).to have_selector("#{@selector} #{field_type}:invalid")
  end

  def expect_error
    expect(page).to have_selector("#{@selector} .-error")
  end

  def save!
    submit_by_enter
  end

  def submit_by_dashboard
    field_container.find('.inplace-edit--control--save').click
    wait_for_reload if using_cuprite?
  end

  ##
  # Set or select the given value.
  # For fields of type select, will check for an option with that value.
  def set_value(content)
    scroll_to_element(input_element)
    if autocompleter_field?
      autocomplete(content)
    elsif using_cuprite?
      clear_input_field_contents(input_element)
      input_element.fill_in with: content
    else
      # A normal fill_in would cause the focus loss on the input for empty strings.
      # Thus the form would be submitted.
      # https://github.com/erikras/redux-form/issues/686
      input_element.fill_in with: content, fill_options: { clear: :backspace }
    end
  end

  def autocomplete(query, select: true)
    raise ArgumentError.new('Is not an autocompleter field') unless autocompleter_field?

    if select
      select_autocomplete field_container, query:, results_selector: 'body'
    else
      search_autocomplete field_container, query:, results_selector: 'body'
    end
  end

  def autocompleter_field?
    field_type.end_with?('-autocompleter')
  end

  ##
  # Set or select the given value.
  # For fields of type select, will check for an option with that value.
  def unset_value(content = nil, multi: false)
    activate!
    scroll_to_element(input_element)

    if field_type.end_with?('-autocompleter')
      if multi
        page.find('.ng-value-label', visible: :all, text: content).sibling('.ng-value-icon').click
      else
        ng_select_clear(field_container)
      end
    else
      input_element.set('')
    end
  end

  ##
  # Use option of ng-select field to create new element from within the autocompleter
  def set_new_value(content)
    scroll_to_element(input_element)
    input_element.find('input').set content

    page.find('.ng-option', text: "Create: #{content}").click
  end

  def type(text)
    scroll_to_element(input_element)
    input_element.send_keys text
  end

  ##
  # Update this attribute while retrying to open the field
  # if unsuccessful at first.
  def update(value, save: true, expect_failure: false)
    # Retry to set attributes due to reloading the page after setting
    # an attribute, which may cause an input not to open properly.
    retry_block do
      activate_edition
      set_value value

      # select fields are saved on change
      save! if save && !field_type.end_with?('-autocompleter')
      expect_state! open: expect_failure
    end
  end

  def submit_by_enter
    if field_type.end_with? '-autocompleter'
      autocomplete_selector.send_keys :return
    else
      input_element.native.send_keys :return
    end
  end

  def cancel_by_escape
    if field_type.end_with? '-autocompleter'
      autocomplete_selector.send_keys :escape
    else
      input_element.native.send_keys :escape
    end
  end

  def editable?
    field_container.has_selector? "#{display_selector}.-editable"
  end

  def input_selector
    if property_name == 'description'
      '.op-ckeditor--wrapper'
    else
      '.inline-edit--field'
    end
  end

  def autocomplete_selector
    field_container.find('.ng-input input')
  end

  def derive_field_type
    case property_name.to_sym
    when :version
      'version-autocompleter'
    when :assignee, :responsible, :user
      'op-user-autocompleter'
    when :priority, :status, :type, :category, :workPackage, :parent
      'create-autocompleter'
    when :project
      'op-autocompleter'
    when :activity
      'activity-autocompleter'
    else
      'input'
    end
  end
end

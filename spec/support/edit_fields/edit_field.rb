class EditField
  include Capybara::DSL
  include Capybara::RSpecMatchers
  include RSpec::Matchers
  include ::Components::Autocompleter::NgSelectAutocompleteHelpers

  attr_reader :context,
              :property_name,
              :selector

  attr_accessor :field_type

  # Initializes a new EditField object. It represents a work package field on a
  # work packages table page, a work package view page (split or full), or a
  # work package creation page (split or full).
  #
  # @param context [Object] The context in which the EditField is being used.
  # @param property_name [Symbol] The name of the property associated with the
  #   EditField. Generally camel case.
  # @param selector [String] (optional) The CSS selector used to locate the
  #   EditField element. if unspecified, the `property_name` is used.
  # @param create_form [Boolean] (optional) Indicates whether the EditField is
  #   used in a create form. It changes the way the field is clicked or not to
  #   activate it on edition. It is `false` by default.
  def initialize(context,
                 property_name,
                 selector: nil,
                 create_form: false)

    @property_name = property_name.to_s
    @context = context
    @field_type = derive_field_type
    @create_form = create_form

    @selector = selector || ".inline-edit--container.#{property_name}"
  end

  def create_form?
    @create_form
  end

  def visible_on_create_form?
    true
  end

  def field_container
    context.find @selector
  end

  def display_selector
    ".inline-edit--display-field"
  end

  def display_element
    context.find "#{@selector} #{display_selector}"
  end

  def display_trigger_element
    if display_element.has_selector?(".inline-edit--display-trigger", wait: 0)
      display_element.find(".inline-edit--display-trigger")
    else
      display_element
    end
  end

  def input_element
    context.find "#{@selector} #{input_selector}"
  end

  def label_element
    context.find ".wp-replacement-label[data-test-selector='#{property_name}']"
  end

  def clear(with_backspace: false)
    if with_backspace
      if using_cuprite?
        clear_input_field_contents(input_element)
      else
        input_element.set(" ", fill_options: { clear: :backspace })
      end
    else
      input_element.native.clear
    end
  end

  def expect_read_only
    expect(context).to have_css "#{@selector} #{display_selector}.-read-only"
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
  # @return [EditField] self
  def activate!(expect_open: true)
    retry_block(args: { tries: 2 }) do
      unless active?
        SeleniumHubWaiter.wait unless using_cuprite?
        scroll_to_and_click(display_trigger_element)
        SeleniumHubWaiter.wait unless using_cuprite?
      end

      if expect_open && !active?
        raise "Expected field for attribute '#{property_name}' to be active."
      end

      self
    end
  end

  alias :activate_edition :activate!

  def openSelectField
    autocomplete_selector.click
    wait_for_network_idle
  end

  def set_select_field_value(value)
    retry_block do
      openSelectField
      set_value value
    end
  end

  def expect_state!(open:)
    if open || (create_form? && visible_on_create_form?)
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
    expect(field_container).to have_no_selector(field_type)
  end

  def expect_enabled!
    expect(@context).to have_no_css "#{@selector} #{input_selector}[disabled]"
  end

  def expect_invalid
    expect(page).to have_css("#{@selector} #{field_type}:invalid")
  end

  def expect_error
    expect(page).to have_css("#{@selector} .-error")
  end

  def save!
    submit_by_enter
  end

  def submit_by_dashboard
    field_container.find(".inplace-edit--control--save").click
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

  def autocomplete(query, select: true, select_text: query)
    raise ArgumentError.new("Is not an autocompleter field") unless autocompleter_field?

    if select
      select_autocomplete field_container, query:, select_text:, results_selector: "body"
    else
      search_autocomplete field_container, query:, results_selector: "body"
    end
  end

  def autocompleter_field?
    field_type.end_with?("-autocompleter")
  end

  ##
  # Set or select the given value.
  # For fields of type select, will check for an option with that value.
  def unset_value(content = nil, multi: false)
    activate!
    scroll_to_element(input_element)

    if autocompleter_field?
      if multi
        page.find(".ng-value-label", visible: :all, text: content).sibling(".ng-value-icon").click
      else
        ng_select_clear(field_container)
      end
    else
      input_element.set("")
    end
  end

  ##
  # Use option of ng-select field to create new element from within the autocompleter
  def set_new_value(content)
    scroll_to_element(input_element)
    input_element.find("input").set content

    page.find(".ng-option", text: "Create: #{content}").click
  end

  def type(text)
    scroll_to_element(input_element)
    input_element.send_keys text
  end

  # Updates the value of the edit field. It retries if unsuccessful at first.
  #
  # @param value [Object] The new value to set.
  # @param save [Boolean] Whether to save the field after updating. Save happens
  #   by pressing Enter key. Default is `true` for non-create pages.
  # @param expect_failure [Boolean] Whether to expect the update to fail. This
  #   will check if field is still in edit state after save. Default is `false`.
  def update(value, save: !create_form?, expect_failure: false)
    # Retry to set attributes due to reloading the page after setting
    # an attribute, which may cause an input not to open properly.
    retry_block do
      activate_edition
      wait_for_network_idle
      set_value value

      # select fields are saved on change
      save! if save && !autocompleter_field?
      expect_state! open: expect_failure
    end
  end

  def submit_by_enter
    if autocompleter_field?
      autocomplete_selector.send_keys :return
    else
      input_element.native.send_keys :return
    end
  end

  def cancel_by_escape
    if autocompleter_field?
      autocomplete_selector.send_keys :escape
    else
      input_element.native.send_keys :escape
    end
  end

  def editable?
    field_container.has_selector? "#{display_selector}.-editable"
  end

  def input_selector
    if property_name == "description"
      ".op-ckeditor--wrapper"
    else
      ".inline-edit--field"
    end
  end

  def autocomplete_selector
    field_container.find(".ng-input input")
  end

  def derive_field_type
    case property_name.to_sym
    when :version
      "version-autocompleter"
    when :assignee, :responsible, :user
      "op-user-autocompleter"
    when :priority, :status, :type, :category, :workPackage, :parent
      "create-autocompleter"
    when :project
      "op-project-autocompleter"
    when :activity
      "activity-autocompleter"
    else
      "input"
    end
  end
end

# frozen_string_literal: true

module Components::Autocompleter
  module NgSelectAutocompleteHelpers
    def search_autocomplete(element, query:, results_selector: "body", wait_dropdown_open: true, wait_for_fetched_options: true)
      SeleniumHubWaiter.wait unless using_cuprite?

      # Wait for dropdown to open
      dropdown_open = ng_dropdown_open?(element, results_selector:) if wait_dropdown_open
      ng_click_autocompleter(element) unless dropdown_open

      # Wait for autocompleter options to be loaded (data fetching is debounced by 250ms after creation or typing)
      wait_for_network_idle if using_cuprite? && wait_for_fetched_options
      expect(element).to have_no_css(".ng-spinner-loader")

      # Insert the text to find
      within(element) do
        retry_block do
          ng_enter_query(element, query, wait_for_fetched_options:)
        end
      end

      # Wait for options to be refreshed after having entered some text.
      expect(element).to have_no_css(".ng-spinner-loader")

      # probably not necessary anymore
      sleep(0.5) unless using_cuprite?

      # Find the open dropdown
      dropdown_list = ng_find_dropdown(element, results_selector:)
      scroll_to_element(dropdown_list)
      dropdown_list
    end

    def ng_click_autocompleter(target)
      input = ng_select_input(target)

      scroll_to_element(input, block: :nearest)
      input.click
    end

    def ng_find_dropdown(element, results_selector: "body", raise_on_missing: true)
      retry_block do
        if results_selector
          results_selector = "#{results_selector} .ng-dropdown-panel" if results_selector == "body"
          within_window(current_window) do
            page.find(results_selector, wait: raise_on_missing ? 5 : 0)
          end
        else
          within(element) do
            page.find("ng-select .ng-dropdown-panel", wait: raise_on_missing ? 5 : 0)
          end
        end
      rescue Capybara::ElementNotFound => e
        return nil unless raise_on_missing

        ng_click_autocompleter(element)
        raise e
      end
    end

    def ng_dropdown_open?(element, results_selector: "body")
      if results_selector
        within_window(current_window) do
          page.has_css?(ng_panel_selector(results_selector), wait: 0)
        end
      else
        element.has_css?("ng-select .ng-dropdown-panel", wait: 0)
      end
    end

    def ng_panel_selector(results_selector)
      return "body .ng-dropdown-panel" if results_selector == "body"
      return results_selector if results_selector.include?(".ng-dropdown-panel")

      "#{results_selector} .ng-dropdown-panel"
    end

    def expect_ng_option(element, option, grouping: nil, results_selector: "body", present: true)
      within(ng_find_dropdown(element, results_selector:)) do
        if grouping && present
          # Make sure the option is displayed under correct grouping title.
          option_group = find(".ng-optgroup", text: grouping)
          option = find(".ng-option.ng-option-child", text: option, visible: :visible)

          expected_group = begin
            option.find(:xpath,
                        "preceding-sibling::*[contains(@class, 'ng-optgroup')][1]",
                        wait: false)
          rescue Capybara::ElementNotFound
            raise "Unable to find the '.ng-optgroup' grouping for option '#{option.text}'"
          end

          expect(option_group).to eq(expected_group), <<~MSG
            Expected the option '#{option.text}' to be under the group '#{option_group.text}',
            but it was under '#{expected_group.text}' instead.
          MSG
        else
          expect(page).to have_conditional_selector(present, ".ng-option", text: option)
        end
      end
    end

    def expect_no_ng_option(element, option, results_selector: "body")
      within(ng_find_dropdown(element, results_selector:)) do
        expect(page).to have_no_css(".ng-option", text: option)
      end
    end

    def expect_ng_value_label(field_id, labels)
      Array(labels).each do |text|
        expect(page).to have_css("##{field_id} .ng-value-label", text:)
      end
    end

    ##
    # Insert the query, typing
    def ng_enter_query(element, query, wait_for_fetched_options: true)
      input = element.find("input[type=text]", visible: :all).native
      if using_cuprite?
        clear_input_field_contents(input)
      else
        input.clear
      end

      query = query.to_s

      # Send all keys but last one, and then with a delay the last one
      # to emulate normal typing
      send_keys(input, query.to_s[0..-2], after_typing_sleep: 0.2)
      send_keys(input, query.to_s[-1])

      wait_for_network_idle if using_cuprite? && wait_for_fetched_options
    end

    def send_keys(input, text, after_typing_sleep: nil)
      return if text.blank?

      if using_cuprite?
        input.native.node.type(text)
      else
        input.send_keys(text)
      end

      sleep after_typing_sleep if after_typing_sleep
    end

    ##
    # Get the ng_select input element
    def ng_select_input(from_element = page)
      from_element.find(".ng-input input")
    end

    ##
    # clear the ng select field
    def ng_select_clear(from_element, raise_on_missing: true)
      if raise_on_missing || from_element.has_css?(".ng-clear-wrapper", visible: :all, wait: 1)
        clear_button = from_element.find(".ng-clear-wrapper", visible: :all)

        scroll_to_element(clear_button, block: :nearest)
        clear_button.click
      end
    end

    def select_autocomplete(element,
                            query:,
                            select_text: nil,
                            results_selector: "body",
                            wait_dropdown_open: true,
                            wait_for_fetched_options: true)
      search_autocomplete(element,
                          query:,
                          results_selector:,
                          wait_dropdown_open:,
                          wait_for_fetched_options:)

      ##
      # If a specific select_text is given, use that to locate the match,
      # otherwise use the query
      text = select_text.presence || query

      retry_block do
        # Re-resolve the option on each attempt because ng-select may rerender
        # the dropdown between find and click in Cuprite.
        ng_find_dropdown(element, results_selector:)
          .first(".ng-option", text:, wait: 15)
          .click
      end
    end

    def expect_current_autocompleter_value(element, value)
      expect(element).to have_css(".ng-value .ng-value-label", text: value, wait: 10)
    end

    # Checks for the currently visible, expanded user auto completer to contain the provided options.
    # A user always has a name, but their email is only visible in certain circumstances, so that value
    # might be nil.
    #
    # The expected options are to be provided as an Array of Hashes, like this example with two users:
    #
    #   [
    #     { name: "Bob", email: nil },
    #     { name: "Alice", email: "alice@example.com" }
    #   ]
    #
    # The order the elements are provided in is also expected.
    def expect_visible_user_auto_completer_options(expected)
      within(".ng-dropdown-panel [role='listbox']") do
        expected.each_with_index do |option, index|
          expect(page)
            .to have_css(".ng-option[role='option']:nth-child(#{index + 1}) .op-user-autocompleter--name",
                         text: option[:name])
          if option[:email]
            expect(page)
              .to have_css(".ng-option[role='option']:nth-child(#{index + 1}) .op-autocompleter__option-principal-email",
                           text: option[:email])
          else
            expect(page)
              .to have_no_css(".ng-option[role='option']:nth-child(#{index + 1}) .op-autocompleter__option-principal-email")
          end
        end
      end
    end
  end
end

module Components::Autocompleter
  module NgSelectAutocompleteHelpers
    def search_autocomplete(element, query:, results_selector: nil, wait_dropdown_open: true, wait_for_fetched_options: true)
      SeleniumHubWaiter.wait unless using_cuprite?
      # Open the element
      element.click

      # Wait for dropdown to open
      ng_find_dropdown(element, results_selector:) if wait_dropdown_open

      # Wait for autocompleter options to be loaded (data fetching is debounced by 250ms after creation or typing)
      wait_for_network_idle if wait_for_fetched_options
      expect(element).to have_no_css(".ng-spinner-loader")

      # Insert the text to find
      within(element) do
        ng_enter_query(element, query, wait_for_fetched_options:)
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

    def ng_find_dropdown(element, results_selector: nil)
      retry_block do
        if results_selector
          results_selector = "#{results_selector} .ng-dropdown-panel" if results_selector == "body"
          page.find(results_selector)
        else
          within(element) do
            page.find("ng-select .ng-dropdown-panel")
          end
        end
      rescue StandardError => e
        ng_select_input(element)&.click
        raise e
      end
    end

    def expect_ng_option(element, option, results_selector: nil, present: true)
      within(ng_find_dropdown(element, results_selector:)) do
        expect(page).to have_conditional_selector(present, ".ng-option", text: option)
      end
    end

    def expect_no_ng_option(element, option, results_selector: nil)
      within(ng_find_dropdown(element, results_selector:)) do
        expect(page).to have_no_css(".ng-option", text: option)
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

      if query.length > 1
        # Send all keys, and then with a delay the last one
        # to emulate normal typing
        if using_cuprite?
          input.native.node.type(query[0..-2])
          sleep 0.2
          input.native.node.type(query[-1])
        else
          input.send_keys(query[0..-2])
          sleep 0.2
          input.send_keys(query[-1])
        end
      end

      wait_for_network_idle if wait_for_fetched_options
    end

    ##
    # Get the ng_select input element
    def ng_select_input(from_element = page)
      from_element.find(".ng-input input")
    end

    ##
    # clear the ng select field
    def ng_select_clear(from_element)
      from_element.find(".ng-clear-wrapper", visible: :all).click
    end

    def select_autocomplete(element,
                            query:,
                            select_text: nil,
                            results_selector: nil,
                            wait_dropdown_open: true,
                            wait_for_fetched_options: true)
      target_dropdown = search_autocomplete(element,
                                            query:,
                                            results_selector:,
                                            wait_dropdown_open:,
                                            wait_for_fetched_options:)

      ##
      # If a specific select_text is given, use that to locate the match,
      # otherwise use the query
      text = select_text.presence || query

      # click the element to select it
      target_dropdown.find(".ng-option", text:, match: :first, wait: 15).click
    end
  end
end

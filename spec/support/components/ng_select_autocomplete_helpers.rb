module Components
  module NgSelectAutocompleteHelpers
    def search_autocomplete(element, query:, results_selector: nil)
      SeleniumHubWaiter.wait
      # Open the element
      element.click
      # Insert the text to find
      within(element) do
        ng_enter_query(query)
      end
      sleep(0.5)

      ##
      # Find the open dropdown
      list =
        if results_selector
          page.find(results_selector)
        else
          within(element) do
            page.find('ng-select .ng-dropdown-panel')
          end
        end

      scroll_to_element(list)
      list
    end

    ##
    # Insert the query, typing
    def ng_enter_query(query)
      input = page.find('input', visible: :all).native
      input.clear

      query = query.to_s

      if query.length > 1
        # Send all keys, and then with a delay the last one
        # to emulate normal typing
        input.send_keys(query[0..-2])
        sleep 0.2
        input.send_keys(query[-1])
      else
        input.send_keys(query)
      end
    end

    ##
    # Get the ng_select input element
    def ng_select_input(from_element)
      from_element.find('.ng-input input')
    end

    def select_autocomplete(element, query:, results_selector: nil, select_text: nil, option_selector: nil)
      target_dropdown = search_autocomplete(element, results_selector: results_selector, query: query)

      ##
      # If a specific select_text is given, use that to locate the match,
      # otherwise use the query
      text = select_text.presence || query

      # click the element to select it
      target_dropdown.find('.ng-option', text: text, match: :first, wait: 60).click
    end
  end
end

module Components
  module NgSelectAutocompleteHelpers
    def search_autocomplete(element, query:, results_selector: nil)
      # Open the element
      element.click
      # Insert the text to find
      within(element) do
        page.find('input').set(query)
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
      target_dropdown.find('.ng-option', text: text, match: :first).click
    end
  end
end

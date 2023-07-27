# frozen_string_literal: true

require 'support/pages/page'

module Pages
  class NewBoard < Page
    include ::Components::Autocompleter::NgSelectAutocompleteHelpers

    def visit!
      visit new_work_package_board_path
    end

    def navigate_by_create_button
      visit boards_all_path unless page.current_path == boards_all_path

      within '.toolbar-items' do
        click_link 'Board'
      end
    end

    def set_title(title)
      fill_in 'Title', with: title
    end

    def set_project(project)
      select_autocomplete(find('[data-qa-selector="project_id"]'),
                          query: project,
                          results_selector: 'body',
                          wait_for_fetched_options: false)
    end

    def set_board_type(board_type)
      choose board_type, match: :first
    end

    def click_on_submit
      click_on 'Create'
    end

    def click_on_cancel_button
      click_on 'Cancel'
    end
  end
end

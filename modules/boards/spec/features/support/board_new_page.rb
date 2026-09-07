# frozen_string_literal: true

require "support/pages/page"

module Pages
  class NewBoard < Page
    include ::Components::Autocompleter::NgSelectAutocompleteHelpers

    def visit!
      visit new_work_package_board_path
    end

    def navigate_by_create_button
      visit work_package_boards_path unless page.current_path == work_package_boards_path

      page.find_test_selector("add-board-button").click
      expect_loaded
    end

    def expect_loaded
      page.find_field(I18n.t(:label_title), disabled: false, wait: 30)
    end

    def set_title(title)
      page.find_field(I18n.t(:label_title), disabled: false, wait: 30).set(title)
    end

    def expect_project_dropdown
      find "[data-test-selector='project_id']"
    end

    def set_project(project)
      select_autocomplete(find('[data-test-selector="project_id"]'),
                          query: project,
                          results_selector: "body",
                          wait_for_fetched_options: false)
    end

    def set_board_type(board_type)
      choose board_type, match: :first
    end

    def click_on_submit
      click_on I18n.t(:button_create)
    end

    def click_on_cancel_button
      click_on "Cancel"
    end
  end
end

# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

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
    end

    def set_title(title)
      fill_in I18n.t(:label_title), with: title
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

    # Types +query+ into the project autocompleter without selecting anything
    # and returns the open dropdown, so that its options can be tested.
    def search_project(query)
      search_autocomplete(find('[data-test-selector="project_id"]'),
                          query:,
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

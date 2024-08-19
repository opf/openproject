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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "support/pages/page"
require_relative "board_list_page"
require_relative "board_new_page"

module Pages
  class BoardIndex < BoardListPage
    attr_reader :project

    def initialize(project = nil)
      @project = project
    end

    def visit!
      if project
        visit project_work_package_boards_path(project)
      else
        visit work_package_boards_path
      end
    end

    def expect_editable(editable)
      # Editable / draggable check
      expect(page).to have_conditional_selector(editable, ".buttons a.icon-delete")
      # Create button
      expect(page).to have_conditional_selector(editable, ".toolbar-item a", text: "Board")
    end

    def expect_board(name, present: true)
      expect(page).to have_conditional_selector(present, "td.name", text: name)
    end

    def create_board(action: "Basic", title: "#{action} Board", expect_empty: false, via_toolbar: true)
      if via_toolbar
        within ".toolbar-items" do
          click_link "Board"
        end
      else
        find('[data-test-selector="boards--create-button"]').click
      end

      new_board_page = NewBoard.new

      new_board_page.set_title title
      new_board_page.set_board_type action
      new_board_page.click_on_submit

      new_board_page.expect_and_dismiss_toaster

      if expect_empty
        expect(page).to have_css(".boards-list--add-item-text", wait: 10)
        expect(page).to have_no_css(".boards-list--item")
      else
        expect(page).to have_css(".boards-list--item", wait: 10)
      end

      ::Pages::Board.new ::Boards::Grid.last
    end

    def open_board(board)
      page.find("td.name a", text: board.name).click
      wait_for_reload
      ::Pages::Board.new board
    end
  end
end

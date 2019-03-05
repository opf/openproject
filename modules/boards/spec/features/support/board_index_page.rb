#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'support/pages/page'
require_relative './board_page'

module Pages
  class BoardIndex < Page
    attr_reader :project

    def initialize(project = nil)
      @project = project
    end

    def visit!
      if project
        visit project_work_package_boards_path(project_id: project.id)
      else
        visit work_package_boards_path
      end
    end

    def expect_editable(editable)
      # Editable / draggable check
      expect(page).to have_conditional_selector(editable, '.buttons a.icon-delete')
      # Create button
      expect(page).to have_conditional_selector(editable, '.toolbar-item a', text: 'Board')
    end

    def expect_board(name, present: true)
      expect(page).to have_conditional_selector(present, 'td.name', text: name)
    end

    def create_board(action: nil)
      page.find('.toolbar-item a', text: 'Board').click

      if action == nil
        find('.button', text: 'Free board').click
      else
        select action, from: 'new_board_action_select'
        find('.button', text: 'Action board').click
      end

      expect(page).to have_selector('.boards-list--item', wait: 10)
      ::Pages::Board.new ::Boards::Grid.last
    end

    def open_board(board)
      page.find('td.name a', text: board.name).click
      ::Pages::Board.new board
    end
  end
end

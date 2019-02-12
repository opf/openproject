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
  class Board < Page
    attr_reader :board

    def initialize(board)
      @board = board
    end

    def card_view?
      board.options['display_mode'] == 'cards'
    end

    def visit!
      if board.project
        visit project_work_package_boards_path(project_id: board.project.id, state: board.id)
      else
        visit work_package_boards_path(state: board.id)
      end
    end

    def back_to_index
      find('.board--back-button').click
    end

    def expect_editable(editable)
      expect(page).to have_conditional_selector(editable, '.board--container.-editable')
      expect(page).to have_conditional_selector(editable, '.board--settings-dropdown')
    end

    def expect_query(name, editable: true)
      if editable
        expect(page).to have_field('editable-toolbar-title', with: name)
      else
        expect(page).to have_selector('.editable-toolbar-title--fixed', text: name)
      end
    end
  end
end

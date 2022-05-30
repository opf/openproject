#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

module HotBoards
  class RowCell < ::RowCell
    def board
      model
    end

    def button_links
      [edit_link, delete_link].compact
    end

    def title
      link_to board.title,
              hot_board_path(board)
    end

    private

    def edit_link
      link_to '',
              { controller: '/hot_boards', action: 'edit', id: board },
              class: 'icon icon-edit',
              title: t(:button_edit)
    end

    def delete_link
      link_to '',
              { controller: '/hot_boards', action: 'destroy', id: board },
              data: { confirm: t(:text_are_you_sure) },
              method: :delete,
              class: 'icon icon-delete',
              title: t(:button_delete)
    end
  end
end

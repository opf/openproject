# OpenProject Boards module
#
# Copyright (C) 2018 OpenProject GmbH
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

module OpenProject::Boards
  class Engine < ::Rails::Engine
    engine_name :openproject_boards

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-backlogs',
             author_url: 'https://community.openproject.com',
             settings: {},
             name: 'OpenProject Boards' do

      project_module :board_view do
        permission :view_boards, 'boards/boards': %i[index show]
        permission :manage_boards, 'boards/boards': %i[index show edit update destroy new create]
      end

      menu :project_menu,
           :board_view,
           { controller: '/boards/boards', action: :index },
           caption: :'boards.label_boards',
           param: :project_id,
           icon: 'icon2 icon-backlogs'
    end
  end
end

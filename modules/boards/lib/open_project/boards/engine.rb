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

    register 'openproject-boards',
             author_url: 'https://community.openproject.com',
             bundled: true,
             settings: {},
             name: 'OpenProject Boards' do

      project_module :board_view, order: 80 do
        permission :show_board_views, 'boards/boards': %i[index], dependencies: :view_work_packages
        permission :manage_board_views, 'boards/boards': %i[index], dependencies: :manage_public_queries
      end

      menu :project_menu,
           :board_view,
           { controller: '/boards/boards', action: :index },
           caption: :'boards.label_boards',
           after: :work_packages,
           param: :project_id,
           icon: 'icon2 icon-boards'

      menu :project_menu,
           :board_menu,
           { controller: '/boards/boards', action: :index },
           param: :project_id,
           parent: :board_view,
           partial: 'boards/boards/menu_board',
           last: true,
           caption: :'boards.label_boards'
    end

    patch_with_namespace :BasicData, :SettingSeeder

    config.to_prepare do
      OpenProject::Boards::GridRegistration.register!
    end
  end
end

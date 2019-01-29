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

    config.to_prepare do
      Grids::Configuration.register_grid('Boards::Grid',
                                         ->(path) {
                                           begin
                                             recognized = Rails.application.routes.recognize_path(path)

                                             if recognized[:controller] == 'boards/boards'
                                               recognized.slice(:project_id, :id, :user_id)&.merge(class: Boards::Grid)
                                             end
                                           rescue ActionController::RoutingError
                                             nil
                                           end
                                         },
                                         :project_boards_path,
                                         -> {
                                           view_allowed = Project.allowed_to(User.current, :view_boards)
                                           manage_allowed = Project.allowed_to(User.current, :manage_boards)

                                           board_projects = Project
                                                              .where(id: view_allowed)
                                                              .or(Project.where(id: manage_allowed))

                                           url_helper = OpenProject::StaticRouting::StaticUrlHelpers.new

                                           paths = board_projects.map { |p| url_helper.project_boards_path(p) }

                                           paths if paths.any?
                                         })

      Grids::Configuration.register_widget('work_package_query', 'Boards::Grid')
    end
  end
end

# OpenProject Team Planner module
#
# Copyright (C) 2021 OpenProject GmbH
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

module OpenProject::Storages
  class Engine < ::Rails::Engine
    engine_name :openproject_storages

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-storages',
             author_url: 'https://www.openproject.org',
             bundled: true,
             settings: {},
             name: 'OpenProject Storages' do
      project_module :storages, dependencies: :work_package_tracking do
        permission :view_file_links,
                   {},
                   dependencies: %i[view_work_packages]
        permission :manage_file_links,
                   {},
                   dependencies: %i[view_file_links]
        permission :manage_storage_in_project,
                   { 'storages/admin/projects_storages': %i[index new create destroy] },
                   dependencies: %i[]
      end

      # Menu extensions
      menu :admin_menu,
           :storages_admin_settings,
           { controller: '/storages/admin/storages', action: :index },
           if: Proc.new { User.current.admin? },
           caption: :project_module_storages,
           icon: 'icon2 icon-hosting'

      menu :project_menu,
           :settings_projects_storages,
           { controller: '/storages/admin/projects_storages', action: 'index' },
           caption: :'storages.label_storage',
           parent: :settings
    end
  end
end

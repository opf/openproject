# OpenProject Calendar module
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

module OpenProject::Calendar
  class Engine < ::Rails::Engine
    engine_name :openproject_calendar

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-calendar',
             author_url: 'https://www.openproject.org',
             bundled: true,
             settings: {},
             name: 'OpenProject Calendar' do
      project_module :calendar_view, dependencies: :work_package_tracking do
        permission :view_calendar,
                   { 'calendar/calendar': %i[index] }
      end

      menu :project_menu,
           :calendar_view,
           { controller: '/calendar/calendar', action: 'index' },
           caption: :label_calendar,
           icon: 'icon2 icon-calendar',
           after: :work_packages

      menu :project_menu,
           :calendar_menu,
           { controller: '/calendar/calendar', action: 'index' },
           parent: :calendar_view,
           partial: 'calendar/calendar/menu',
           last: true,
           caption: :label_calendar
    end

    add_view :WorkPackagesCalendar,
             contract_strategy: 'Calendar::Views::ContractStrategy'
  end
end

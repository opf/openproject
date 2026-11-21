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

module OpenProject
  module Hotkeys
    PROJECT_MENU = {
      overview: "g o",
      work_packages: "g w p",
      activity: "g a",
      calendar_view: "g c",
      news: "g n"
    }.freeze

    ALWAYS = { my_page: "g m" }.freeze

    GLOBAL_FALLBACK = {
      work_packages: "g w p",
      activity: "g a",
      calendar_view: "g c",
      news: "g n",
      wikis: "g w i"
    }.freeze

    ACTIONS = {
      edit: "g e",
      project_search: "p",
      shortcuts_help: "?,Shift+?",
      new_work_package: "n w p"
    }.freeze

    class << self
      def for_project_menu_item(name)
        PROJECT_MENU[name.to_sym]
      end

      def for_modules_menu_item(name, project)
        ALWAYS[name.to_sym] || (project.nil? ? GLOBAL_FALLBACK[name.to_sym] : nil)
      end

      def for_action(name)
        ACTIONS.fetch(name.to_sym)
      end
    end
  end
end

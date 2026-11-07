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

module TestManagement
  module NavigationHelper
    def tm_render_horizontal_section_nav(header, project:)
      menu = TestManagement::Menu.new(project:, params:)
      return unless menu.horizontal_navigation?

      header.with_tab_nav(label: t(:project_module_test_management), test_selector: "tm-section-nav") do |nav|
        menu.visible_sections.each do |section|
          nav.with_tab(
            selected: section == menu.current_section,
            href: menu.section_path(section)
          ) do |tab|
            tab.with_text { t("test_management.menu.#{section}") }
          end
        end
      end
    end
  end
end

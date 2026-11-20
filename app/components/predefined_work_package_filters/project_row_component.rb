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

module PredefinedWorkPackageFilters
  class ProjectRowComponent < OpPrimer::BorderBoxRowComponent
    alias_method :project, :model

    def name
      render(Projects::InfoLineComponent.new(project:))
    end

    def button_links
      [render(Primer::Alpha::ActionMenu.new(anchor_align: :end)) do |menu|
        menu.with_show_button(icon: "kebab-horizontal", scheme: :invisible,
                              "aria-label": t("predefined_work_package_filters.actions", name: project.name))
        menu.with_item(
          label: t(:button_remove),
          tag: :button,
          href: project_admin_predefined_work_package_filter_path(table.filter, project),
          form_arguments: { method: :delete }
        ) do |item|
          item.with_leading_visual_icon(icon: :unlink)
        end
      end]
    end
  end
end

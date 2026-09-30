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

module Overviews
  class GridRegistration < ::Grids::Configuration::InProjectBaseRegistration
    grid_class "Grids::Overview"
    to_scope :project_overview_path

    view_permission :view_project
    edit_permission :manage_dashboards
    in_project_scope_path nil

    defaults -> {
      {
        row_count: 3,
        column_count: 2,
        widgets: [
          {
            identifier: "project_description",
            start_row: 1,
            end_row: 3,
            start_column: 1,
            end_column: 2,
            options: {
              name: I18n.t("js.grid.widgets.project_description.title")
            }
          },
          {
            identifier: "project_status",
            start_row: 1,
            end_row: 2,
            start_column: 2,
            end_column: 3,
            options: {
              name: I18n.t("js.grid.widgets.project_status.title")
            }
          },
          {
            identifier: "work_packages_overview",
            start_row: 3,
            end_row: 4,
            start_column: 1,
            end_column: 3,
            options: {
              name: I18n.t("js.grid.widgets.work_packages_overview.title")
            }
          },
          {
            identifier: "members",
            start_row: 2,
            end_row: 3,
            start_column: 2,
            end_column: 3,
            options: {
              name: I18n.t("js.grid.widgets.members.title")
            }
          }
        ]
      }
    }

    validations :create, ->(*_args) {
      if Grids::Overview.exists?(project_id: model.project_id)
        errors.add(:scope, :taken)
      end
    }

    validations :create, ->(*_args) {
      next if user.allowed_in_project?(:manage_dashboards, model.project)

      defaults = Overviews::GridRegistration.defaults

      %i[row_count column_count].each do |count|
        if model.send(count) != defaults[count]
          errors.add(count, :unchangeable)
        end
      end

      model.widgets.each do |widget|
        widget_default = defaults[:widgets].detect { |w| w[:identifier] == widget.identifier }

        if widget.attributes.except("options") != widget_default.attributes.except("options") ||
           widget.attributes["options"].stringify_keys != widget_default.attributes["options"].stringify_keys
          errors.add(:widgets, :unchangeable)
        end
      end
    }

    class << self
      def writable?(grid, user)
        # New records are allowed to be saved by everybody. Other parts
        # of the application prevent a user from saving arbitrary pages.
        # Only the default config is allowed and only one page per project is allowed.
        # That way, a new page can be created on the fly without the user noticing.
        super || (grid.new_record? && user.allowed_in_project?(:view_project, grid.project))
      end
    end
  end
end

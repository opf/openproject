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

module Overviews
  class DashboardPageRegistration < ::Grids::Configuration::InProjectBaseRegistration
    PORTABLE_WIDGETS = %w[
      project_description project_status subprojects work_packages_calendar work_packages_overview
      time_entries_list members news documents custom_text
    ].freeze

    grid_class "Grids::DashboardPage"
    to_scope :project_dashboard_page_path
    view_permission :view_project
    edit_permission :manage_dashboards
    defaults -> { { row_count: 1, column_count: 1, widgets: [] } }

    self._widget_strategies = ::Grids::Configuration::InProjectBaseRegistration._widget_strategies.dup
    self._validations = nil

    widgets.each do |identifier|
      project_strategy = widget_strategy(identifier)

      widget_strategy(identifier) do
        allowed ->(user, project) {
          if project
            project_strategy.allowed?(user, project)
          else
            PORTABLE_WIDGETS.include?(identifier) && user.allowed_globally?(:manage_standard_dashboards)
          end
        }
        after_destroy project_strategy.after_destroy
        options_representer project_strategy.options_representer
      end
    end

    validations :update, ->(*_args) {
      next unless model.central?

      widgets = model.widgets.reject(&:marked_for_destruction?)
      errors.add(:widgets, :inclusion) if widgets.any? { |widget| PORTABLE_WIDGETS.exclude?(widget.identifier) }
    }

    class << self
      def from_scope(_scope) = nil

      def all_scopes = []

      def writable_scopes = []

      def visible(user = User.current)
        projects = Project.visible(user)
        local = Grids::Grid.where(type: grid_class, project_id: projects, disabled: false)
        central = Grids::Grid.where(type: grid_class, project_id: nil)
        return local.or(central) if user.allowed_globally?(:manage_standard_dashboards)

        visible = local.or(central.where(id: DashboardPageAssignment.where(project: projects, active: true).select(:grid_id)))
        if Project.allowed_to(user, :view_project).exists?
          visible.or(central.where(active_in_all_projects: true))
        else
          visible
        end
      end

      def writable?(grid, user)
        if grid.central?
          user.allowed_globally?(:manage_standard_dashboards)
        else
          super
        end
      end
    end
  end
end

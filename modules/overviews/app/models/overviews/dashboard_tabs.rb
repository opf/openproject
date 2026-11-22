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
  class DashboardTabs
    SORTABLE_LIST_TYPE = "project-dashboard-tabs"

    Entry = Data.define(:key, :dashboard, :active) do
      def original? = key == "original"

      def standard? = !original? && dashboard.central?

      def display_name
        original? ? (dashboard&.display_name || I18n.t("overviews.label_dashboard")) : dashboard.name
      end
    end

    def initialize(project)
      @project = project
    end

    def entries
      by_key = default_entries.index_by(&:key)
      ordered = Array(@project.dashboard_tab_order).filter_map { |key| by_key.delete(key) }
      ordered + by_key.values
    end

    def move_after(key, previous_key)
      @project.with_lock do
        keys = entries.map(&:key)
        next false unless keys.delete(key)
        next false if previous_key && keys.exclude?(previous_key)

        position = previous_key ? keys.index(previous_key) + 1 : 0
        keys.insert(position, key)
        @project.update!(dashboard_tab_order: keys)
      end
    end

    private

    def default_entries
      original = ::Grids::Overview.find_by(project: @project)
      active_ids = ::Grids::DashboardPage.active_in(@project).pluck(:id).to_set
      dashboards = ::Grids::DashboardPage.in_project(@project).order(:name, :id).map do |dashboard|
        Entry.new(key: dashboard.id.to_s, dashboard:, active: active_ids.include?(dashboard.id))
      end

      [Entry.new(key: "original", dashboard: original, active: !original&.disabled?), *dashboards]
    end
  end
end

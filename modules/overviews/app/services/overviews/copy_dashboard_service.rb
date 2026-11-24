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
  class CopyDashboardService
    def initialize(user:, source:, project:)
      @user = user
      @source = source
      @project = project
    end

    def call(name:)
      dashboard = ::Grids::DashboardPage.new(
        name:, project: @project,
        row_count: @source.row_count, column_count: @source.column_count, options: @source.options.deep_dup
      )
      persist_copy(dashboard)
    end

    private

    def persist_copy(dashboard)
      dashboard.transaction do
        dashboard.save!
        @source.widgets.each { |widget| copy_widget(widget, dashboard) }
      end

      dashboard
    rescue ActiveRecord::RecordInvalid => e
      dashboard.errors.add(:base, I18n.t("overviews.dashboards.copy_widgets_error")) unless e.record == dashboard
      dashboard
    end

    def copy_widget(widget, dashboard)
      copy = widget.dup
      copy.grid = dashboard
      copy.options = widget.options.deep_dup

      if (query_id = copy.options["queryId"])
        copy.options["queryId"] = copy_widget_query(copy, query_id).id
      end

      copy.save!
    end

    def copy_widget_query(widget, query_id)
      query = ::Query.find_by(id: query_id)
      unless query && QueryPolicy.new(@user).allowed?(query, :show) &&
             Grids::Configuration.allowed_widget?(widget.grid.class, widget.identifier, @user, @project)
        raise ActiveRecord::RecordInvalid, widget
      end

      copy = query.dup
      copy.assign_attributes(project: @project, user: @user, public: true)
      copy.save!
      copy
    end
  end
end

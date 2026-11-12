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

module MyPage
  class GridRegistration < ::Grids::Configuration::Registration
    grid_class "Grids::MyPage"
    to_scope :my_page_path

    widgets "custom_text",
            "documents",
            "work_packages_assigned",
            "work_packages_accountable",
            "work_packages_watched",
            "work_packages_created",
            "work_packages_calendar",
            "work_packages_table",
            "time_entries_current_user",
            "project_favorites",
            "news"

    wp_table_strategy_proc = Proc.new do
      after_destroy -> {
        @query = ::Query.find_by(id: options["queryId"])

        next unless @query && QueryPolicy.new(User.current).allowed?(@query, :destroy)

        @query.destroy!
      }

      allowed ->(user, _project) { user.allowed_in_any_project?(:save_queries) }

      options_representer "::API::V3::Grids::Widgets::QueryOptionsRepresenter"
    end

    # Allow users without save_queries permission to access the widgets
    # but they are not allowed to update the underlying query
    wp_static_table_strategy_proc = Proc.new do
      after_destroy -> {
        @query = ::Query.find_by(id: options["queryId"])

        next unless @query && QueryPolicy.new(User.current).allowed?(@query, :destroy)

        @query.destroy!
      }

      options_representer "::API::V3::Grids::Widgets::QueryOptionsRepresenter"
    end

    widget_strategy "work_packages_table", &wp_table_strategy_proc
    widget_strategy "work_packages_assigned", &wp_static_table_strategy_proc
    widget_strategy "work_packages_accountable", &wp_static_table_strategy_proc
    widget_strategy "work_packages_watched", &wp_static_table_strategy_proc
    widget_strategy "work_packages_created", &wp_static_table_strategy_proc

    widget_strategy "custom_text" do
      # Requiring a permission here as one is required to assign attachments.
      # Should be replaced by a global permission to have a my page
      allowed ->(user, _project) { user.allowed_in_any_project?(:view_project) }

      options_representer "::API::V3::Grids::Widgets::CustomTextOptionsRepresenter"
    end

    defaults -> {
      {
        row_count: 1,
        column_count: 2,
        widgets: [
          {
            identifier: "work_packages_assigned",
            start_row: 1,
            end_row: 2,
            start_column: 1,
            end_column: 2,
            options: {
              name: I18n.t("js.grid.widgets.work_packages_assigned.title"),
              queryProps: {
                "columns[]": %w(id project type subject),
                filters: JSON.dump([{ status: { operator: "o", values: [] } },
                                    { assignee: { operator: "=", values: ["me"] } }])
              }
            }
          },
          {
            identifier: "work_packages_created",
            start_row: 1,
            end_row: 2,
            start_column: 2,
            end_column: 3,
            options: {
              name: I18n.t("js.grid.widgets.work_packages_created.title"),
              queryProps: {
                "columns[]": %w(id project type subject),
                filters: JSON.dump([{ status: { operator: "o", values: [] } },
                                    { author: { operator: "=", values: ["me"] } }])
              }
            }
          }
        ]
      }
    }

    class << self
      def from_scope(scope)
        if scope == url_helpers.my_page_path
          { class: Grids::MyPage }
        end
      end

      def visible(user = User.current)
        super
          .where(user_id: user.id)
      end
    end
  end
end

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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

FactoryBot.define do
  factory :overview, class: "Grids::Overview" do
    project
    row_count { 7 }
    column_count { 4 }
    widgets do
      []
    end
  end

  factory :dashboard, class: "Grids::Overview" do
    project
    row_count { 7 }
    column_count { 4 }
    widgets do
      [
        Grids::Widget.new(
          identifier: "work_packages_table",
          start_row: 1,
          end_row: 7,
          start_column: 1,
          end_column: 3
        )
      ]
    end
  end

  factory :dashboard_with_table_narrow, class: "Grids::Overview" do
    project
    row_count { 1 }
    column_count { 3 }
    widgets do
      [
        Grids::Widget.new(
          identifier: "work_packages_table",
          start_row: 1,
          end_row: 2,
          start_column: 1,
          end_column: 2
        )
      ]
    end
  end

  factory :dashboard_with_table, class: "Grids::Overview" do
    project
    row_count { 7 }
    column_count { 4 }

    callback(:after_build) do |dashboard|
      query = create(:query, project: dashboard.project, public: true)

      widget = build(:grid_widget,
                     identifier: "work_packages_table",
                     start_row: 1,
                     end_row: 7,
                     start_column: 1,
                     end_column: 3,
                     options: {
                       name: "Work package table",
                       queryId: query.id
                     })

      dashboard.widgets = [widget]
    end
  end

  factory :dashboard_with_custom_text, class: "Grids::Overview" do
    project
    row_count { 7 }
    column_count { 4 }

    callback(:after_build) do |dashboard|
      widget = build(:grid_widget,
                     identifier: "custom_text",
                     start_row: 1,
                     end_row: 7,
                     start_column: 1,
                     end_column: 3,
                     options: {
                       name: "Custom text",
                       text: "Lorem ipsum"
                     })

      dashboard.widgets = [widget]
    end
  end
end

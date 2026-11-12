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

module Boards
  class BasicBoardCreateService < BaseCreateService
    private

    def query_name
      "Unnamed list"
    end

    def query_filters
      [{ manual_sort: { operator: "ow", values: [] } }]
    end

    def options_for_widgets(params)
      [
        Grids::Widget.new(
          start_row: 1,
          start_column: 1,
          end_row: 2,
          end_column: 2,
          identifier: "work_package_query",
          options: {
            "queryId" => params[:query_id],
            "filters" => query_filters
          }
        )
      ]
    end
  end
end

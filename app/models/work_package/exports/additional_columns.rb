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

module WorkPackage::Exports
  # Adds extra columns when some particular columns are present.
  #
  # For instance, adds a 'Total work' column when the 'Work' column is present.
  module AdditionalColumns
    ADDITIONAL_COLUMNS = {
      estimated_hours: [:derived_estimated_hours],
      remaining_hours: [:derived_remaining_hours],
      done_ratio: [:derived_done_ratio]
    }.freeze

    def get_columns
      super.flat_map { |column| [column] + additional_columns(column) }
    end

    def additional_columns(column)
      ADDITIONAL_COLUMNS
        .fetch(column.name, [])
        .map do |additional_column_name|
          Queries::WorkPackages::Selects::PropertySelect.new(additional_column_name)
        end
    end
  end
end

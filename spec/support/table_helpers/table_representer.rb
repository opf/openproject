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

module TableHelpers
  class TableRepresenter
    attr_reader :tables_data, :columns

    def initialize(tables_data:, columns:)
      @tables_data = tables_data
      @columns = columns
    end

    # rubocop:disable Style/MultilineBlockChain
    def render(table_data)
      column_and_cell_sizes
        .map do |column, cell_size|
          header = column.title.ljust(cell_size)
          cells = table_data.values_for_attribute(column.attribute).map { column.cell_format(_1, cell_size) }
          [header, *cells]
        end
        .transpose
        .map { |row| "| #{row.join(' | ')} |\n" }
        .join
    end
    # rubocop:enable Style/MultilineBlockChain

    private

    def column_and_cell_sizes
      @column_and_cell_sizes ||=
        columns.index_with do |column|
          values = tables_data.flat_map { _1.values_for_attribute(column.attribute) }
          values_max_size = values.map { column.format(_1).size }.max
          [column.title.size, values_max_size].max
        end
    end
  end
end

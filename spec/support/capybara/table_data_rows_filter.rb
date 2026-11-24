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

# Adds `data_rows:` and `with_data_rows:` filters to the `:table` selector.
#
# Unlike the built-in `rows:`/`with_rows:`, rows are header-keyed Hashes whose
# cells may be `<th>` row headers or `<td>` cells, and values match exactly.
# Headers come from the table's first row; data rows are rows with a `<td>`.
# Row order is not asserted.
#
# `data_rows:` checks that each Hash matches some row and that the number of
# data rows equals the number of Hashes. Pass complete, distinct rows: a
# partial Hash, or two Hashes matching the same row, still pass.
#
# Columns are located by header position, so tables with duplicate header
# texts, `colspan`, `<td>` header cells or nested tables are not supported.
#
# @example Every body row
#   expect(page).to have_table("Burndown chart: data", visible: :all, data_rows: [
#     { "Date" => "11/03/2026", "Remaining" => "40", "Guideline" => "40" }
#   ])
#
# @example Some rows, some columns
#   expect(page).to have_table("Burndown chart: data", with_data_rows: [{ "Guideline" => "36" }])

module TableDataRowsFilter
  module_function

  def header_row
    XPath.ancestor(:table)[1].axis(:descendant, :tr)[1]
  end

  def data_row
    XPath.descendant(:tr)[XPath.child(:td)]
  end

  def match_cell(header, value)
    header_cell = header_row.child(:th)[XPath.string.n.equals(header)]
    XPath.child(:th, :td)[
      XPath.string.n.equals(value) &
      header_cell.boolean &
      XPath.position.equals(header_cell.preceding_sibling(:th).count.plus(1))
    ]
  end

  def match_row(row)
    data_row[row.map { |header, value| match_cell(header, value) }.reduce(:&)]
  end

  def match_rows(xpath, rows)
    xpath[rows.map { |row| match_row(row) }.reduce(:&)]
  end
end

Capybara.modify_selector(:table) do
  expression_filter(:with_data_rows, valid_values: [Array]) do |xpath, rows|
    TableDataRowsFilter.match_rows(xpath, rows)
  end

  expression_filter(:data_rows, valid_values: [Array]) do |xpath, rows|
    TableDataRowsFilter.match_rows(xpath, rows)[TableDataRowsFilter.data_row.count.equals(rows.size)]
  end

  describe_expression_filters do |data_rows: nil, with_data_rows: nil, **|
    desc = +""
    desc << " with exactly #{data_rows.size} data rows #{data_rows.inspect}" if data_rows
    desc << " with data rows #{with_data_rows.inspect}" if with_data_rows
    desc
  end
end

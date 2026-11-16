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

class Widget::Table::ReportTable < Widget::Table
  attr_accessor :walker

  # rubocop:disable Metrics/AbcSize
  def configure_walker
    @walker ||= @subject.walker
    @walker.for_final_row do |row, cells|
      content_tag(:th, class: "normal inner left -break-word", scope: "row") do
        concat show_row(row)
        concat safe_join(cells)
        concat content_tag(:td, show_result(row), class: "normal inner right")
      end
    end

    @walker.for_row do |row, subrows|
      subrows.flatten!
      unless row.fields.empty?
        subrows[0] = capture do
          concat content_tag(:th, show_row(row), class: "top left -breakword", rowspan: subrows.size)
          concat subrows[0].html_safe_gsub("class='normal", "class='top")
          concat content_tag(:th, show_result(row), class: "top right", rowspan: subrows.size)
        end
      end
      subrows[-1] = subrows.last.html_safe_gsub("class='normal", "class='bottom")
      subrows[-1] = subrows.last.html_safe_gsub("class='top", "class='bottom top")

      subrows
    end

    @walker.for_empty_cell { content_tag(:td, "\u00A0", class: "normal empty") }

    @walker.for_cell do |result|
      content_tag(:td, show_result(result), class: "normal right")
    end
  end
  # rubocop:enable Metrics/AbcSize

  def call
    configure_walker
    concat "<table class='report'>".html_safe
    render_thead
    render_tfoot
    render_tbody
    concat "</table>".html_safe
  end

  def render_tbody
    concat "<tbody>".html_safe
    first = true
    odd = true
    walker.body do |line|
      if first
        line = line.html_safe_gsub("class='normal", "class='top")
        first = false
      end
      line = mark_penultimate_column(line)
      concat content_tag(:tr, line, class: odd ? "odd" : "even")
      odd = !odd
    end
    concat "</tbody>".html_safe
  end

  def mark_penultimate_column(line)
    line.html_safe_gsub(/(<td class='([^']+)'[^<]+<\/td>)[^<]*<th .+/) do |m|
      m.sub /class='([^']+)'/, 'class=\'\1 penultimate\''
    end
  end

  # rubocop:disable Metrics/AbcSize
  def render_thead
    walker.headers
    return if walker.headers_empty?

    concat "<thead>".html_safe
    column_dimensions = @subject.group_bys(:column)
    level = -1
    walker.headers do |list, first, first_in_col, last_in_col|
      if first_in_col
        level += 1
        concat "<tr>".html_safe
        render_dimension_labels(column_dimensions[level])
      end
      list.each do |column|
        opts = { colspan: column.final_number(:column) }
        opts[:class] = "inner" if column.final?(:column)
        concat(content_tag(:th, opts) do
          show_row column
        end)
      end
      if first
        concat(content_tag(:th, "", rowspan: header_row_count, colspan: @subject.depth_of(:row)))
      end
      concat "</tr>".html_safe if last_in_col
    end
    render_row_dimension_label_row if row_labels_in_own_row?
    concat "</thead>".html_safe
  end

  def row_labels_in_own_row?
    @subject.group_bys(:column).first.display? && @subject.group_bys(:row).first.display?
  end

  def header_row_count
    row_labels_in_own_row? ? @subject.depth_of(:column) + 1 : @subject.depth_of(:column)
  end

  def render_dimension_labels(column_dimension)
    if column_dimension.display?
      concat content_tag(:th, column_dimension.class.label, colspan: @subject.depth_of(:row))
    else
      concat safe_join(row_dimension_labels)
    end
  end

  def render_row_dimension_label_row
    value_columns = content_tag(:th, "", colspan: @subject.column_first.final_number(:column))

    concat content_tag(:tr, safe_join([*row_dimension_labels, value_columns]))
  end

  def row_dimension_labels
    @subject.group_bys(:row).map { |row_dimension| content_tag(:th, row_dimension.class.label) }
  end

  def render_tfoot
    return if walker.headers_empty?

    concat "<tfoot>".html_safe
    walker.reverse_headers do |list, first, first_in_col, last_in_col|
      if first_in_col
        concat "<tr>".html_safe
        if first
          concat(content_tag(:th, " ", rowspan: @subject.depth_of(:column), colspan: @subject.depth_of(:row), class: "top"))
        end
      end

      list.each do |column|
        opts = { colspan: column.final_number(:column) }
        opts[:class] = "inner" if first
        concat(content_tag(:th, show_result(column), opts))
      end
      if last_in_col
        if first
          concat(
            content_tag(:th,
                        rowspan: @subject.depth_of(:column),
                        colspan: @subject.depth_of(:row),
                        class: "top result") do
              show_result @subject
            end
          )
        end
        concat "</tr>".html_safe
      end
    end
    concat "</tfoot>".html_safe
  end
  # rubocop:enable Metrics/AbcSize
end

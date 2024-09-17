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

class Widget::Table::ReportTable < Widget::Table
  attr_accessor :walker

  def configure_query
    if @subject.depth_of(:row) == 0
      @subject.row(:singleton_value)
    elsif @subject.depth_of(:column) == 0
      @subject.column(:singleton_value)
    end
  end

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
          concat html_safe_gsub(subrows[0], "class='normal", "class='top")
          concat content_tag(:th, show_result(row), class: "top right", rowspan: subrows.size)
        end
      end
      subrows[-1] = html_safe_gsub(subrows.last, "class='normal", "class='bottom")
      subrows[-1] = html_safe_gsub(subrows.last, "class='top", "class='bottom top")

      subrows
    end

    @walker.for_empty_cell { "<td class='normal empty'>&nbsp;</td>".html_safe }

    @walker.for_cell do |result|
      content_tag(:td, show_result(result), class: "normal right")
    end
  end
  # rubocop:enable Metrics/AbcSize

  def render
    configure_query
    configure_walker
    write "<table class='report'>".html_safe
    render_thead
    render_tfoot
    render_tbody
    write "</table>".html_safe
  end

  def render_tbody
    write "<tbody>".html_safe
    first = true
    odd = true
    walker.body do |line|
      if first
        line = html_safe_gsub(line, "class='normal", "class='top")
        first = false
      end
      line = mark_penultimate_column(line)
      write content_tag(:tr, line, class: odd ? "odd" : "even")
      odd = !odd
    end
    write "</tbody>".html_safe
  end

  def mark_penultimate_column(line)
    html_safe_gsub(line, /(<td class='([^']+)'[^<]+<\/td>)[^<]*<th .+/) do |m|
      m.sub /class='([^']+)'/, 'class=\'\1 penultimate\''
    end
  end

  # rubocop:disable Metrics/AbcSize
  def render_thead
    walker.headers
    return if walker.headers_empty?

    write "<thead>".html_safe
    walker.headers do |list, first, first_in_col, last_in_col|
      write "<tr>".html_safe if first_in_col
      if first
        write(content_tag(:th, "", rowspan: @subject.depth_of(:column), colspan: @subject.depth_of(:row)))
      end
      list.each do |column|
        opts = { colspan: column.final_number(:column) }
        opts[:class] = "inner" if column.final?(:column)
        write(content_tag(:th, opts) do
          show_row column
        end)
      end
      if first
        write(content_tag(:th, "", rowspan: @subject.depth_of(:column), colspan: @subject.depth_of(:row)))
      end
      write "</tr>".html_safe if last_in_col
    end
    write "</thead>".html_safe
  end

  def render_tfoot
    return if walker.headers_empty?

    write "<tfoot>".html_safe
    walker.reverse_headers do |list, first, first_in_col, last_in_col|
      if first_in_col
        write "<tr>".html_safe
        if first
          write(content_tag(:th, " ", rowspan: @subject.depth_of(:column), colspan: @subject.depth_of(:row), class: "top"))
        end
      end

      list.each do |column|
        opts = { colspan: column.final_number(:column) }
        opts[:class] = "inner" if first
        write(content_tag(:th, show_result(column), opts))
      end
      if last_in_col
        if first
          write(content_tag(:th,
                            rowspan: @subject.depth_of(:column),
                            colspan: @subject.depth_of(:row),
                            class: "top result") do
                  show_result @subject
                end)
        end
        write "</tr>".html_safe
      end
    end
    write "</tfoot>".html_safe
  end
  # rubocop:enable Metrics/AbcSize
end

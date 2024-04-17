#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

# Paint helper for Gantt chart

class GanttPainter
  GANTT_GRID_COLOR = "9b9ea3".freeze
  GANTT_LINE_COLOR = "0000ff".freeze

  def initialize(pdf)
    @pdf = pdf
  end

  def paint(pages)
    paint_pages(pages)
  end

  private

  def paint_pages(pages)
    pages.each_with_index do |page, page_index|
      paint_page(page)
      # start a new page if not last
      @pdf.start_new_page if page_index != pages.size - 1
    end
  end

  def paint_page(page)
    paint_grid(page)
    paint_header_row(page)
    page.columns.each { |column| paint_grid_line_v(page.header_row_height, page.height, column.right) }
    paint_grid_line_h(0, page.width, page.rows.last.bottom)
    page.lines.each { |line| paint_gantt_line(line) }
    page.rows.each { |row| paint_row(row) }
  end

  def paint_grid(page)
    paint_grid_line_v(0, page.height, 0)
    paint_grid_line_v(0, page.height, page.width)
    paint_grid_line_v(0, page.height, page.text_column.width) unless page.text_column.nil?
    paint_grid_line_h(0, page.width, page.height)
    page.rows.each { |row| paint_grid_line_h(0, page.width, row.top) }
  end

  def paint_header_text_column(page)
    paint_text_box(page.text_column.title, 0, 0, page.text_column.width, page.header_row_height,
                   page.text_column.padding_h, 0, { size: 10, style: :bold })
    paint_grid_line_h(0, page.text_column.width, 0)
  end

  def paint_header_column_cell(cell)
    paint_text_box(cell.text, cell.left, cell.top, cell.width, cell.height,
                   0, 0,
                   { size: 10, style: :bold, align: :center })
    paint_grid_line_h(cell.left, cell.right, cell.top)
    paint_grid_line_v(cell.top, cell.bottom, cell.left)
  end

  def paint_work_package_title(row)
    paint_text_box(
      "#{row.work_package.type} ##{row.work_package.id} - #{row.work_package.subject}",
      row.left, row.top, row.page.text_column.width, row.page.text_column.height,
      row.page.text_column.padding_h, row.page.text_column.padding_v
    )
  end

  def paint_row(row)
    paint_work_package_title(row) unless row.page.text_column.nil?
    paint_shape(row.shape) unless row.shape.nil?
  end

  def paint_header_row(page)
    paint_header_text_column(page) unless page.text_column.nil?
    page.header_cells.each { |cell| paint_header_column_cell(cell) }
  end

  def paint_header_cell(text, columns, top, height)
    left = columns.first.left
    right = columns.last.right
    paint_text_box(text, left, top, right - left, height, 0, 0, { size: 8, style: :bold, align: :center })
    paint_grid_line_h(left, right, top)
    paint_grid_line_v(top, top + height, left)
  end

  def paint_shape(shape)
    if shape.type == :milestone
      paint_diamond(shape.left, shape.top, shape.width, shape.height, shape.color)
    else
      paint_rect(shape.left, shape.top, shape.width, shape.height, shape.color)
    end
  end

  def paint_line(line_x1, line_y1, line_x2, line_y2, color)
    @pdf.stroke do
      @pdf.line_width = 0.5
      @pdf.stroke_color color
      @pdf.line @pdf.bounds.left + line_x1, @pdf.bounds.top - line_y1,
                @pdf.bounds.left + line_x2, @pdf.bounds.top - line_y2
    end
  end

  def paint_gantt_line(line)
    paint_line(line[:left], line[:top], line[:right], line[:bottom], GANTT_LINE_COLOR)
  end

  def paint_grid_line_h(left, right, top)
    paint_line(left, top, right, top, GANTT_GRID_COLOR)
  end

  def paint_grid_line_v(top, bottom, left)
    paint_line(left, top, left, bottom, GANTT_GRID_COLOR)
  end

  def paint_diamond(left, top, width, height, color)
    half = width / 2
    current_color = @pdf.fill_color
    @pdf.fill_color color
    @pdf.fill_polygon *[[0, half], [half, 0], [width, half], [half, height]]
                         .map { |p| [@pdf.bounds.left + left + p[0], @pdf.bounds.top - top - p[1]] }
    @pdf.fill_color = current_color
  end

  def paint_rect(left, top, width, height, color)
    current_color = @pdf.fill_color
    @pdf.fill_color color
    @pdf.fill_rectangle([@pdf.bounds.left + left, @pdf.bounds.top - top], width, height)
    @pdf.fill_color = current_color
  end

  def paint_text_box(text, left, top, width, height, padding_h, padding_v, additional_options = {})
    @pdf.text_box(text,
                  at: [@pdf.bounds.left + left + padding_h, @pdf.bounds.top - padding_v - top],
                  width: width - (padding_h * 2),
                  height: height - 2 - (padding_v * 2),
                  overflow: :shrink_to_fit,
                  min_font_size: 5,
                  valign: :center,
                  size: 8,
                  leading: 0,
                  **additional_options)
  end
end

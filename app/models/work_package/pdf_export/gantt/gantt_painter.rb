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

module WorkPackage::PDFExport::Gantt
  class GanttPainter
    GANTT_GRID_COLOR = "9b9ea3".freeze
    GANTT_LINE_COLOR = "2b8bd5".freeze

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
      paint_lines(page)
      paint_rows(page)
    end

    def paint_rows(page)
      page.rows.each { |row| paint_row(row) }
    end

    def paint_lines(page)
      @pdf.stroke do
        @pdf.line_width = 1
        @pdf.stroke_color GANTT_LINE_COLOR
        page.lines.each { |line| paint_line(line[:left], line[:top], line[:right], line[:bottom]) }
      end
    end

    def grid_v(page)
      page_height = page.height
      [
        [0, page_height, 0],
        [0, page_height, page.width],
        page.text_column.nil? ? nil : [0, page_height, page.text_column.width],
        page.columns.map { |column| [page.header_row_height, page_height, column.right] },
        page.header_cells.map { |cell| [cell.top, cell.bottom, cell.left] }
      ]
    end

    def grid_h(page)
      page_width = page.width
      text_column = page.text_column
      [
        [0, page_width, page.height],
        [0, page_width, page.rows.last.bottom],
        text_column.nil? ? nil : [0, text_column.width, 0],
        page.rows.map { |row| [0, page_width, row.top] },
        page.header_cells.map { |cell| [cell.left, cell.right, cell.top] }
      ]
    end

    def paint_grid_h(page)
      grid_h(page).compact.flatten.each_slice(3) { |left, right, top| paint_line(left, top, right, top) }
    end

    def paint_grid_v(page)
      grid_v(page).compact.flatten.each_slice(3) { |top, bottom, left| paint_line(left, top, left, bottom) }
    end

    def paint_grid(page)
      @pdf.stroke do
        @pdf.line_width = 0.5
        @pdf.stroke_color GANTT_GRID_COLOR
        paint_grid_v(page)
        paint_grid_h(page)
      end
    end

    def paint_row(row)
      row.text_lines.each { |line| paint_row_text_line(line) }
      unless row.shape.nil?
        paint_shape(row.shape)
      end
    end

    def paint_header_row(page)
      paint_header_text_column(page) unless page.text_column.nil?
      page.header_cells.each { |cell| paint_header_column_cell(cell) }
    end

    def paint_shape(shape)
      if shape.type == :milestone
        paint_diamond(shape.left, shape.top, shape.width, shape.height, shape.color)
      else
        paint_rect(shape.left, shape.top, shape.width, shape.height, shape.color)
      end
    end

    def paint_line(line_x1, line_y1, line_x2, line_y2)
      @pdf.line @pdf.bounds.left + line_x1, @pdf.bounds.top - line_y1,
                @pdf.bounds.left + line_x2, @pdf.bounds.top - line_y2
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

    def paint_header_text_column(page)
      paint_text_box(page.text_column.title, page.text_column.padding_h, 0,
                     page.text_column.width - page.text_column.padding_h, page.header_row_height,
                     { size: 10, style: :bold })
    end

    def paint_header_column_cell(cell)
      paint_text_box(cell.text, cell.left, cell.top, cell.width, cell.height, { size: 10, style: :bold, align: :center })
    end

    def paint_row_text_line(line)
      paint_text_box(truncate_ellipsis(line.text, line.width, line.font_size),
                     line.left, line.top, line.width, line.height, { size: line.font_size })
    end

    def truncate_ellipsis(text, available_width, font_size)
      return text if @pdf.width_of(text, { size: font_size }) <= available_width

      line = text.dup
      while line.present? && (@pdf.width_of("#{line}...", { size: font_size }) > available_width)
        line = line.chop
      end
      "#{line}..."
    end

    def paint_text_box(text, left, top, width, height, additional_options = {})
      @pdf.text_box(text,
                    at: [@pdf.bounds.left + left, @pdf.bounds.top - top],
                    width:,
                    height: height - 1,
                    overflow: :shrink_to_fit,
                    min_font_size: 3,
                    valign: :center,
                    size: 8,
                    leading: 0,
                    **additional_options)
    end
  end
end

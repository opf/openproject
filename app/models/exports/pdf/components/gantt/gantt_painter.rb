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

module Exports::PDF::Components::Gantt
  class GanttPainter
    GANTT_GRID_COLOR = "9b9ea3"
    GANTT_LINE_COLOR = "2b8bd5"
    GROUP_ROW_BACKGROUND_COLOR = "ffffff"
    ELLIPSIS = "..."
    HEADER_MAX_LINES = 2
    LINE_HEIGHT_TOLERANCE = 0.01
    FALLBACK_CAP_HEIGHT_RATIO = 0.7

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
      paint_group_row_backgrounds(page)
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
        page.text_columns.map { |column| [0, page_height, column.right] },
        page.columns.map { |column| [page.header_row_height, page_height, column.right] },
        page.header_cells.map { |cell| [cell.top, cell.bottom, cell.left] }
      ]
    end

    def grid_h(page)
      page_width = page.width
      [
        [0, page_width, page.height],
        [0, page_width, page.rows.last.bottom],
        text_area_top_line(page),
        page.rows.map { |row| [0, page_width, row.top] },
        page.header_cells.map { |cell| [cell.left, cell.right, cell.top] }
      ]
    end

    def text_area_top_line(page)
      [0, page.text_columns.last.right, 0] if page.text_columns.any?
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
      page.text_columns.each { |column| paint_header_text_column(column) }
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

    def paint_header_text_column(column)
      padding = GanttTextColumnLayout::PADDING_H
      paint_fitted_text(column.caption, column.left + padding, column.top, column.width - (padding * 2), column.height,
                        size: GanttTextColumnLayout::HEADER_FONT_SIZE, max_lines: HEADER_MAX_LINES, style: :bold,
                        align: :center)
    end

    def paint_header_column_cell(cell)
      paint_text_box(cell.text, cell.left, cell.top, cell.width, cell.height, { size: 10, style: :bold, align: :center })
    end

    # The grid is painted first; group titles may run on into the chart area,
    # so the grid lines inside those rows are covered. Inset by half a grid line
    # to keep the row borders.
    def paint_group_row_backgrounds(page)
      page.rows.select { |row| row.group && row.text_lines.any? }.each do |row|
        paint_rect(0.25, row.top + 0.25, page.width - 0.5, row.height - 0.5, GROUP_ROW_BACKGROUND_COLOR)
      end
    end

    def paint_row_text_line(line)
      paint_fitted_text(line.text, line.left, line.top, line.width, line.height,
                        size: line.font_size, max_lines: line.max_lines)
    end

    def paint_fitted_text(text, left, top, width, height, size:, max_lines:, style: :normal, align: :left)
      font_options = { size:, style:, leading: 0 }
      lines = fit_lines(text, width, height, max_lines, font_options)
      return if lines.empty?

      @pdf.text_box(lines.join("\n"),
                    at: [@pdf.bounds.left + left, @pdf.bounds.top - top - optical_top_offset(lines.size, height, size)],
                    width:,
                    height: lines_height(lines.size, size),
                    overflow: :truncate,
                    align:,
                    **font_options)
    end

    def optical_top_offset(line_count, height, size)
      ascender, descender, cap_height = font_metrics(size)
      ink_height = cap_height + ((line_count - 1) * @pdf.font.height_at(size)) + (descender / 2)
      ((height - ink_height) / 2) - (ascender - cap_height)
    end

    def font_metrics(size)
      font = @pdf.font
      scale = size / @pdf.font_size.to_f
      [font.ascender * scale, font.descender * scale, cap_height_ratio(font) * size]
    end

    def cap_height_ratio(font)
      return FALLBACK_CAP_HEIGHT_RATIO unless font.respond_to?(:ttf) && font.ttf.os2.exists?

      cap_height = font.ttf.os2.cap_height.to_f
      cap_height.positive? ? cap_height / font.ttf.header.units_per_em : FALLBACK_CAP_HEIGHT_RATIO
    end

    def fit_lines(text, width, height, max_lines, font_options)
      box = fitting_text_box(text, width, height, max_lines, font_options)
      remaining = box.render(dry_run: true)
      lines = box.text.split("\n")
      lines[-1] = ellipsize(lines.last, width, font_options) if remaining.present? && lines.any?
      lines
    end

    def fitting_text_box(text, width, height, max_lines, font_options)
      line_height = @pdf.font.height_at(font_options[:size])
      line_count = [max_lines, (height / line_height).floor].min.clamp(1..)
      Prawn::Text::Box.new(text, document: @pdf, width:, overflow: :truncate,
                                 height: lines_height(line_count, font_options[:size]), **font_options)
    end

    def lines_height(line_count, size)
      (line_count * @pdf.font.height_at(size)) + LINE_HEIGHT_TOLERANCE
    end

    def ellipsize(text, available_width, font_options)
      fits = ->(length) { @pdf.width_of("#{text[0, length].rstrip}#{ELLIPSIS}", font_options) <= available_width }
      length = (0..text.length).bsearch { |candidate| !fits.call(candidate) } || (text.length + 1)
      "#{text[0, length - 1].to_s.rstrip}#{ELLIPSIS}"
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

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

module WorkPackage::PDFExport::Gantt
  GANTT_ROW_HEIGHT = 20
  GANTT_GRID_COLOR = "9b9ea3".freeze
  GANTT_TEXT_CELL_PADDING = 2
  GANTT_BAR_CELL_PADDING = 5

  def write_work_packages_gantt!(work_packages, _)
    wps = work_packages.reject { |work_package| work_package.start_date.nil? }
    return if wps.empty?

    zoom_levels = [
      [:day, 48],
      [:day, 24],
      [:day, 18],
      [:month, 128],
      [:month, 64],
      [:month, 32],
      [:month, 24],
      [:quarter, 64],
      [:quarter, 32],
      [:quarter, 24]
    ]
    zoom = options[:zoom] || 1
    mode, column_width = zoom_levels[zoom.to_i - 1].nil? ? zoom_levels[1] : zoom_levels[zoom.to_i - 1]
    builder = case mode
              when :month
                GanttBuilderMonths.new(pdf, heading, column_width)
              when :quarter
                GanttBuilderQuarters.new(pdf, heading, column_width)
              else
                # when :day
                GanttBuilderDays.new(pdf, heading, column_width)
              end
    pages = builder.build(wps)
    pages = pages.filter { |page| page[:columns].pluck(:work_packages).flatten.any? } if options[:filter_empty]
    painter = GanttPainter.new(pdf)
    painter.paint(pages)
  end

  class GanttBuilder
    def initialize(pdf, title, column_width)
      @pdf = pdf
      @title = title
      @column_width = column_width
      init_defaults
    end

    def build(work_packages)
      adjust_to_pages
      pages = build_pages(work_packages)
      # if there are not enough columns for even the first page of horizontal pages => distribute space to all columns
      if pages.find { |page| page[:text_column].nil? }.nil?
        distribute_to_first_page(pages)
        pages = build_pages(work_packages)
      end
      pages
    end

    private

    def init_defaults
      @header_row_height = 30
      @text_column_width = [@pdf.bounds.width / 4, 250].min
      @nr_columns = (@pdf.bounds.width / @column_width).floor
    end

    def adjust_to_pages
      # distribute space right to the default column widths
      distribute_to_next_page_column

      # distribute space right on the first page to the first column
      distribute_to_first_column

      # distribute space bottom to the first row
      distribute_to_header_row
    end

    def distribute_to_header_row
      gant_rows_height = @pdf.bounds.height - @header_row_height
      @rows_per_page = (gant_rows_height / GANTT_ROW_HEIGHT).floor
      @header_row_height = @pdf.bounds.height - (@rows_per_page * GANTT_ROW_HEIGHT)
    end

    def distribute_to_next_page_column
      gantt_columns_space_next_page = @pdf.bounds.width - (@nr_columns * @column_width)
      @column_width += gantt_columns_space_next_page / @nr_columns
      @nr_columns = (@pdf.bounds.width / @column_width).floor
    end

    def distribute_to_first_column
      gantt_columns_width_first_page = @pdf.bounds.width - @text_column_width
      @nr_columns_first_page = (gantt_columns_width_first_page / @column_width).floor
      @text_column_width = @pdf.bounds.width - (@nr_columns_first_page * @column_width)
    end

    def distribute_to_first_page(pages)
      nr_of_columns = pages.first[:columns].length
      init_defaults
      @column_width = (@pdf.bounds.width - @text_column_width) / nr_of_columns
      @nr_columns_first_page = nr_of_columns
      @nr_columns = nr_of_columns
    end

    def build_pages(work_packages)
      dates = build_column_dates(work_packages)
      vertical_pages_needed = (work_packages.size / @rows_per_page.to_f).ceil
      horizontal_pages_needed = [((dates.size - @nr_columns_first_page) / @nr_columns.to_f).ceil, 0].max + 1
      (0..vertical_pages_needed - 1)
        .map do |v_index|
        build_horizontal_pages(work_packages.slice(v_index * @rows_per_page, @rows_per_page), dates, horizontal_pages_needed)
      end.flatten
    end

    def build_column_dates(work_packages)
      wp_dates = collect_work_packages_dates(work_packages)
      build_column_dates_range(wp_dates.first..wp_dates.last)
    end

    def collect_work_packages_dates(work_packages)
      work_packages.map do |work_package|
        [work_package.start_date, work_package.due_date.nil? ? Time.zone.today : work_package.due_date]
      end.flatten.uniq.sort
    end

    def build_header_span_cell(text, columns)
      # top: & height: will be added later
      left = columns.first[:left]
      width = columns.last[:left] + columns.last[:width] - columns.first[:left]
      { text:, left:, width:, right: left + width }
    end

    def set_header_row_y_positions(columns)
      cell_height = @header_row_height / columns.length
      columns.each_with_index do |cell_row, index|
        y = index * cell_height
        cell_row.each do |cell|
          cell[:top] = y
          cell[:height] = cell_height
          cell[:bottom] = y + cell_height
        end
      end
    end

    def build_header_row(columns)
      parts = header_row_parts
      result = parts.map do |part|
        case part
        when :years
          build_header_row_years(columns)
        when :quarters
          build_header_row_quarters(columns)
        when :months
          build_header_row_months(columns)
        when :days
          build_header_row_days(columns)
        else
          []
        end
      end
      set_header_row_y_positions(result)
      result.flatten
    end

    def build_header_row_part(columns, mapping_lambda, compare_lambda, title_lambda)
      columns
        .map { |column| mapping_lambda.call(column[:date]) }
        .uniq
        .map do |entry|
        part_columns = columns.select { |column| compare_lambda.call(column[:date], entry) }
        build_header_span_cell(title_lambda.call(entry), part_columns)
      end
    end

    def build_header_row_years(columns)
      build_header_row_part(columns,
                            ->(date) { date.year },
                            ->(date, year) { date.year == year },
                            ->(year) { year.to_s })
    end

    def build_header_row_quarters(columns)
      build_header_row_part(columns,
                            ->(date) { [date.year, date.quarter] },
                            ->(date, quarter_tuple) {
                              date.year == quarter_tuple[0] && date.quarter == quarter_tuple[1]
                            },
                            ->(quarter_tuple) { "Q#{quarter_tuple[1]}" })
    end

    def build_header_row_months(columns)
      build_header_row_part(columns,
                            ->(date) { [date.year, date.month] },
                            ->(date, month_tuple) { date.year == month_tuple[0] && date.month == month_tuple[1] },
                            ->(month_tuple) { Date.new(month_tuple[0], month_tuple[1], 1).strftime("%b") })
    end

    def build_header_row_days(columns)
      columns.map { |column| build_header_span_cell(column[:date].day.to_s, [column]) }
    end

    def build_horizontal_pages(work_packages, dates, horizontal_pages_needed)
      result = [build_page(dates.slice(0, @nr_columns_first_page), 0, work_packages)]
      (0..horizontal_pages_needed - 2).each do |index|
        result << build_page(
          dates.slice(@nr_columns_first_page + (index * @nr_columns), @nr_columns),
          index + 1, work_packages
        )
      end
      result
    end

    def build_page(dates, index, work_packages)
      x = index == 0 ? @text_column_width : 0
      columns = dates.each_with_index.map { |date, col_index| build_column(x + (col_index * @column_width), date, work_packages) }
      header = build_header_row(columns)
      {
        text_column: index == 0 ? { width: @text_column_width, title: @title } : nil,
        width: x + (dates.size * @column_width),
        height: @header_row_height + (@rows_per_page * GANTT_ROW_HEIGHT),
        rows: work_packages.each_with_index.map { |work_package, row_index| build_row(work_package, row_index, columns) },
        columns:,
        header:,
        work_packages:
      }
    end

    def build_row(work_package, row_index, columns)
      paint_columns = columns.filter { |column| column[:work_packages].include?(work_package) }
      top = @header_row_height + (row_index * GANTT_ROW_HEIGHT)
      shape = build_shape(top, paint_columns, work_package) unless paint_columns.empty?
      {
        top:,
        left: 0,
        height: GANTT_ROW_HEIGHT,
        bottom: top + GANTT_ROW_HEIGHT,
        work_package:,
        shape:
      }
    end

    def bar_layout(paint_columns, work_package)
      x1 = calc_start_offset(work_package, paint_columns.first[:date])
      x2 = paint_columns.last[:right] - paint_columns.first[:left] -
        calc_end_offset(work_package, paint_columns.last[:date])
      [x1, x2, GANTT_BAR_CELL_PADDING, GANTT_ROW_HEIGHT - GANTT_BAR_CELL_PADDING]
    end

    def build_shape_bar(top, paint_columns, work_package)
      left = paint_columns.first[:left]
      x1, x2, y1, y2 = bar_layout(paint_columns, work_package)
      {
        type: :bar,
        left: left + x1, right: left + x2,
        top: top + y1, bottom: top + y2,
        width: [x2 - x1, 0.1].max, height: y2 - y1
      }
    end

    def milestone_layout(top, paint_columns, work_package)
      diamond_size = ([@column_width, GANTT_ROW_HEIGHT].min / 2).to_f
      x1 = if milestone_position_centered?
             width = Math.sqrt((diamond_size**2) + (diamond_size**2))
             (@column_width - width) / 2
           else
             calc_start_offset(work_package, paint_columns.first[:date])
           end
      y1 = top + (GANTT_ROW_HEIGHT / 2)
      [x1, y1, diamond_size]
    end

    def build_shape_milestone(top, paint_columns, work_package)
      x1, y1, diamond_size = milestone_layout(top, paint_columns, work_package)
      {
        type: :milestone,
        left: paint_columns.first[:left] + x1,
        right: paint_columns.first[:left] + x1 + diamond_size,
        top: y1, bottom: y1 + diamond_size,
        width: diamond_size, height: diamond_size
      }
    end

    def build_shape(top, paint_columns, work_package)
      shape = {
        work_package:,
        columns: paint_columns,
        color: work_package.type.color.hexcode.sub("#", "")
      }
      if work_package.milestone?
        shape.merge(build_shape_milestone(top, paint_columns, work_package))
      else
        shape.merge(build_shape_bar(top, paint_columns, work_package))
      end
    end

    def build_column(left, date, work_packages)
      {
        date:,
        left:,
        right: left + @column_width,
        width: @column_width,
        header_row_height: @header_row_height,
        work_packages: work_packages_on_date(date, work_packages)
      }
    end

    def build_column_dates_range(_range)
      [] # to be overwritten
    end

    def header_row_parts
      [] # to be overwritten
    end

    def work_packages_on_date(_date, _work_packages)
      [] # to be overwritten
    end

    def milestone_position_centered?
      false # to be overwritten
    end

    def calc_end_offset(_work_package, _date)
      0 # to be overwritten
    end

    def calc_start_offset(_work_package, _date)
      0 # to be overwritten
    end
  end

  class GanttBuilderMonths < GanttBuilder
    def build_column_dates_range(range)
      range
        .map { |d| Date.new(d.year, d.month, -1) }
        .uniq
    end

    def header_row_parts
      %i[years quarters months]
    end

    def work_packages_on_date(date, work_packages)
      work_packages.select { |work_package| wp_on_month?(work_package, date) }
    end

    def calc_start_offset(work_package, date)
      test_date = Date.new(date.year, date.month, 1)
      return 0 if work_package.start_date <= test_date

      width_per_day = @column_width.to_f / date.end_of_month.day
      day_in_month = work_package.start_date.day - 1
      day_in_month * width_per_day
    end

    def calc_end_offset(work_package, date)
      wp_date = work_package.due_date || Time.zone.today
      test_date = Date.new(date.year, date.month, -1)
      return 0 if wp_date >= test_date

      width_per_day = @column_width.to_f / test_date.day
      day_in_month = wp_date.day
      @column_width - (day_in_month * width_per_day)
    end

    def wp_on_month?(work_package, date)
      start_date = work_package.start_date
      end_date = work_package.due_date.nil? ? Time.zone.today : work_package.due_date
      Range.new(Date.new(start_date.year, start_date.month, 1), Date.new(end_date.year, end_date.month, -1))
           .include?(date)
    end
  end

  class GanttBuilderDays < GanttBuilder
    def build_column_dates_range(range)
      range.to_a
    end

    def header_row_parts
      %i[years months days]
    end

    def work_packages_on_date(date, work_packages)
      work_packages.select { |work_package| wp_on_day?(work_package, date) }
    end

    def calc_start_offset(_work_package, _date)
      0
    end

    def calc_end_offset(_work_package, _date)
      0
    end

    def milestone_position_centered?
      true
    end

    def wp_on_day?(work_package, date)
      start_date = work_package.start_date
      end_date = work_package.due_date || Time.zone.today
      Range.new(start_date, end_date).include?(date)
    end
  end

  class GanttBuilderQuarters < GanttBuilder
    def build_column_dates_range(range)
      range
        .map { |d| [d.year, d.quarter] }
        .uniq
        .map { |year, quarter| Date.new(year, quarter * 3, -1) }
    end

    def header_row_parts
      %i[years quarters months]
    end

    def work_packages_on_date(date, work_packages)
      work_packages.select { |work_package| wp_on_quarter?(work_package, date) }
    end

    def calc_start_offset(work_package, date)
      return 0 if work_package.start_date <= date.beginning_of_quarter

      width_per_day = @column_width.to_f / days_of_quarter(date)
      day_in_quarter = day_in_quarter(work_package.start_date) - 1
      day_in_quarter * width_per_day
    end

    def calc_end_offset(work_package, date)
      wp_date = work_package.due_date.nil? ? Time.zone.today : work_package.due_date
      return 0 if wp_date >= date.end_of_quarter

      width_per_day = @column_width.to_f / GanttUtils::days_of_quarter(date)
      day_in_quarter = GanttUtils::day_in_quarter(wp_date)
      @column_width - (day_in_quarter * width_per_day)
    end

    def day_in_quarter(date)
      date.yday - date.beginning_of_quarter.yday + 1
    end

    def days_of_quarter(date)
      quarter = date.quarter
      days = 0
      (1..3).each do |q|
        days += Date.new(date.year, (quarter * 3) - 2 + q, -1).day
      end
      days
    end

    def wp_on_quarter?(work_package, date)
      end_date = work_package.due_date || Time.zone.today
      Range.new(work_package.beginning_of_quarter, end_date.end_of_quarter).include?(date)
    end
  end

  class GanttPainter
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
      page[:columns].each { |column| paint_line_v(column[:header_row_height], page[:height], column[:right]) }
      page[:rows].each { |row| paint_row(page, row) }
      paint_line_h(0, page[:width], page[:rows].last[:bottom])
    end

    def paint_grid(page)
      paint_line_v(0, page[:height], 0)
      paint_line_v(0, page[:height], page[:width])
      paint_line_v(0, page[:height], page[:text_column][:width]) unless page[:text_column].nil?
      paint_line_h(0, page[:width], page[:height])
    end

    def paint_header_text_column(page)
      paint_text_box(page[:text_column][:title], 0, 0, page[:text_column][:width], page[:columns].first[:header_row_height],
                     GANTT_TEXT_CELL_PADDING * 2, 0, { size: 10, style: :bold })
      paint_line_h(0, page[:text_column][:width], 0)
    end

    def paint_header_column_cell(cell)
      paint_text_box(cell[:text],
                     cell[:left], cell[:top], cell[:width], cell[:height],
                     0, 0,
                     { size: 10, style: :bold, align: :center })
      paint_line_h(cell[:left], cell[:right], cell[:top])
      paint_line_v(cell[:top], cell[:bottom], cell[:left])
    end

    def paint_work_package_title(page, row)
      work_package = row[:work_package]
      paint_text_box(
        "#{work_package.type} ##{work_package.id} - #{work_package.subject}",
        row[:left], row[:top], page[:text_column][:width], GANTT_ROW_HEIGHT,
        GANTT_TEXT_CELL_PADDING * 2, GANTT_TEXT_CELL_PADDING
      )
    end

    def paint_row(page, row)
      paint_line_h(0, page[:width], row[:top])
      paint_work_package_title(page, row) unless page[:text_column].nil?
      paint_shape(row[:shape]) if row[:shape]
    end

    def paint_header_row(page)
      paint_header_text_column(page) unless page[:text_column].nil?
      page[:header].each { |cell| paint_header_column_cell(cell) }
    end

    def paint_header_cell(text, columns, top, height)
      left = columns.first[:left]
      right = columns.last[:right]
      paint_text_box(text, left, top, right - left, height, 0, 0, { size: 8, style: :bold, align: :center })
      paint_line_h(left, right, top)
      paint_line_v(top, top + height, left)
    end

    def paint_shape_bar(shape)
      paint_rect(shape[:left], shape[:top], shape[:width], shape[:height], shape[:color])
    end

    def paint_shape_milestone(shape)
      @pdf.rotate(45, origin: [@pdf.bounds.left + shape[:left], @pdf.bounds.top - shape[:top]]) do
        paint_rect(shape[:left], shape[:top], shape[:width], shape[:height], shape[:color])
      end
    end

    def paint_shape(shape)
      if shape[:type] == :milestone
        paint_shape_milestone(shape)
      else
        paint_shape_bar(shape)
      end
    end

    def paint_line(line_x1, line_y1, line_x2, line_y2)
      @pdf.stroke do
        @pdf.line_width = 0.5
        @pdf.stroke_color GANTT_GRID_COLOR
        @pdf.line line_x1, line_y1, line_x2, line_y2
      end
    end

    def paint_line_h(left, right, top)
      paint_line(@pdf.bounds.left + left, @pdf.bounds.top - top, @pdf.bounds.left + right, @pdf.bounds.top - top)
    end

    def paint_line_v(top, bottom, left)
      paint_line(@pdf.bounds.left + left, @pdf.bounds.top - top, @pdf.bounds.left + left, @pdf.bounds.top - bottom)
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
end

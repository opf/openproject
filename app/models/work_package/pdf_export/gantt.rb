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
  def write_work_packages_gantt!(work_packages, _)
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
    @gantt_mode, @gant_column_width = zoom_levels[zoom.to_i - 1].nil? ? zoom_levels[1] : zoom_levels[zoom.to_i - 1]
    @gantt_header_row_height = 30
    @gant_row_height = 20
    @gant_text_cell_padding = 2
    @gant_bar_cell_padding = 5
    @gantt_filter_empty = false
    @gantt_grid_color = "9b9ea3"
    @gantt_text_column_width = pdf.bounds.width / 4

    @gantt_columns_per_next_page = (pdf.bounds.width / @gant_column_width).floor
    gantt_columns_space_next_page = pdf.bounds.width - @gantt_columns_per_next_page * @gant_column_width
    # distribute space to the default column widths
    @gant_column_width += gantt_columns_space_next_page / @gantt_columns_per_next_page
    gantt_columns_width_first_page = pdf.bounds.width - @gantt_text_column_width
    @gantt_columns_per_first_page = (gantt_columns_width_first_page / @gant_column_width).floor
    @gantt_columns_per_next_page = (pdf.bounds.width / @gant_column_width).floor
    # distribute space to the first column
    @gantt_text_column_width = pdf.bounds.width - (@gantt_columns_per_first_page * @gant_column_width)
    gant_rows_height = pdf.bounds.height - @gantt_header_row_height
    @gantt_work_packages_per_page = (gant_rows_height / @gant_row_height).floor
    # distribute space bottom to the first row
    @gantt_header_row_height = pdf.bounds.height - (@gantt_work_packages_per_page * @gant_row_height)

    pages = build_gantt_pages(work_packages)

    if pages.find { |page| !page[:text_column] }.nil?
      # if there are not enough columns for even the first page of horizontal pages => distribute space to all columns
      nr_of_columns = pages.first[:columns].length
      @gantt_text_column_width = pdf.bounds.width / 4
      @gant_column_width = (pdf.bounds.width - @gantt_text_column_width) / nr_of_columns
      @gantt_columns_per_first_page = nr_of_columns
      @gantt_columns_per_next_page = nr_of_columns
      pages = build_gantt_pages(work_packages)
    end

    pages = pages.filter { |page| page[:columns].map { |c| c[:work_packages] }.flatten.any? } if @gantt_filter_empty
    paint_pages(pages)
  end

  private

  def build_gantt_variables

  end

  def build_gantt_pages(work_packages)
    wps = work_packages.select { |work_package| !work_package.start_date.nil? }
    wp_dates = wps
                 .map { |work_package| [work_package.start_date, work_package.due_date.nil? ? Date.today : work_package.due_date] }
                 .flatten.uniq.sort
    start_date = wp_dates.first
    end_date = wp_dates.last

    dates = case @gantt_mode
            when :day
              (start_date..end_date).to_a
            when :quarter
              (start_date..end_date).map { |d| [d.year, quarter_of_date(d)] }.uniq.map { |year, quarter| Date.new(year, quarter * 3, -1) }
            else
              # when :month
              (start_date..end_date).map { |d| Date.new(d.year, d.month, -1) }.uniq
            end
    vertical_pages_needed = (wps.size.to_f / @gantt_work_packages_per_page.to_f).ceil
    (0..vertical_pages_needed - 1)
      .map { |v_index| build_gantt_horizontal_pages(wps.slice(v_index * @gantt_work_packages_per_page, @gantt_work_packages_per_page), dates) }
      .flatten
  end

  def build_gantt_header_span_cell(text, columns)
    { text: text, x: columns.first[:x], width: columns.last[:x] + columns.last[:width] - columns.first[:x] }
  end

  def build_gantt_header_row(columns)
    result = []

    years = columns.map { |column| column[:date].year }.uniq
    result << years.map do |year|
      year_columns = columns.select { |column| column[:date].year == year }
      build_gantt_header_span_cell(year.to_s, year_columns)
    end

    if [:quarter, :month].include?(@gantt_mode)
      quarters = columns.map { |column| [quarter_of_date(column[:date]), column[:date].year] }.uniq
      result << quarters.map do |quarter_tuple|
        quarter, year = quarter_tuple
        quarter_columns = columns.select { |column| column[:date].year == year && quarter_of_date(column[:date]) == quarter }
        build_gantt_header_span_cell("Q#{quarter}", quarter_columns)
      end
    end

    if [:day, :month].include?(@gantt_mode)
      months = columns.map { |column| [column[:date].month, column[:date].year] }.uniq
      result << months.map do |month_tuple|
        month, year = month_tuple
        month_columns = columns.select { |column| column[:date].year == year && column[:date].month == month }
        build_gantt_header_span_cell(month_columns.first[:date].strftime("%b"), month_columns)
      end
    end

    if @gantt_mode == :day
      result << columns.map do |column|
        build_gantt_header_span_cell(column[:date].day.to_s, [column])
      end
    end

    cell_height = @gantt_header_row_height / result.length
    result.each_with_index do |cell_row, index|
      y = index * cell_height
      cell_row.each do |cell|
        cell[:y] = y
        cell[:height] = cell_height
      end
    end

    result.flatten
  end

  def build_gantt_horizontal_pages(work_packages, dates)
    horizontal_pages_needed = [((dates.size - @gantt_columns_per_first_page).to_f / @gantt_columns_per_next_page.to_f).ceil, 0].max + 1
    result = []
    dates_on_page = dates.slice(0, @gantt_columns_per_first_page)
    result << build_gantt_page(dates_on_page, 0, work_packages)

    list = (0..horizontal_pages_needed - 2)
    list.each do |index|
      dates_on_page = dates.slice(@gantt_columns_per_first_page + index * @gantt_columns_per_next_page, @gantt_columns_per_next_page)
      result << build_gantt_page(dates_on_page, index + 1, work_packages)
    end
    result
  end

  def build_gantt_page(dates, index, work_packages)
    x = index == 0 ? @gantt_text_column_width : 0
    columns = dates.each_with_index.map { |date, col_index| build_gantt_column(x + (col_index * @gant_column_width), date, work_packages) }
    y = @gantt_header_row_height
    shapes = work_packages.each_with_index.map do |work_package, row_index|
      paint_columns = columns.filter { |column| column[:work_packages].include?(work_package) }
      build_gantt_shape(y + (row_index * @gant_row_height), paint_columns, work_package) unless paint_columns.empty?
    end.compact
    header = build_gantt_header_row(columns)
    {
      text_column: index == 0,
      width: x + (dates.size * @gant_column_width),
      height: @gantt_header_row_height + (@gantt_work_packages_per_page * @gant_row_height),
      columns: columns,
      header: header,
      shapes: shapes,
      work_packages: work_packages
    }
  end

  def build_gantt_shape(y, paint_columns, work_package)
    paint_column_first = paint_columns.first
    paint_column_last = paint_columns.last
    x = paint_column_first[:x]
    width = paint_column_last[:x] + paint_column_last[:width] - paint_column_first[:x]
    {
      x: x,
      y: y,
      width: width,
      work_package: work_package,
      column_first: paint_column_first,
      column_last: paint_column_last,
      x1: x + calc_start_offset(work_package, paint_column_first[:date]),
      x2: x + width - calc_end_offset(work_package, paint_columns.last[:date]),
      y1: y + @gant_bar_cell_padding,
      y2: y + @gant_row_height - @gant_bar_cell_padding,
      type: work_package.milestone? ? :milestone : :bar,
      color: gantt_wp_color(work_package)
    }
  end

  def build_gantt_column(x, date, work_packages)
    work_packages_on_date =
      case @gantt_mode
      when :day
        work_packages.select { |work_package| wp_on_day?(work_package, date) }
      when :quarter
        work_packages.select { |work_package| wp_on_quarter?(work_package, date) }
      else
        # when :month
        work_packages.select { |work_package| wp_on_month?(work_package, date) }
      end
    {
      date: date,
      x: x,
      width: @gant_column_width,
      work_packages: work_packages_on_date
    }
  end


  def paint_pages(pages)
    pages.each_with_index do |page, page_index|
      paint_page(page)
      # start a new page if not last
      @pdf.start_new_page if page_index != pages.size - 1
    end
  end

  def paint_page(page)
    # paint grid lines
    paint_gantt_grid(page)
    # paint header row
    paint_gantt_header_row(page)
    # paint work packages titles if first of horizontal pages
    page[:work_packages].each_with_index { |wp, index| paint_gantt_wp(wp, index) } if page[:text_column]
    # paint work packages shapes
    page[:shapes].each { |shape| paint_gantt_shape(shape) }
  end

  def paint_gantt_grid(page)
    paint_gantt_line_v(0, page[:height], 0)
    paint_gantt_line_v(0, page[:height], page[:width])
    paint_gantt_line_h(0, page[:width], page[:height])
    paint_gantt_line_v(0, page[:height], @gantt_text_column_width) if page[:text_column]
    page[:columns].each { |column| paint_gantt_line_v(@gantt_header_row_height, page[:height], column[:x] + column[:width]) }
    (0..@gantt_work_packages_per_page).each do |index|
      paint_gantt_line_h(0, page[:width], @gantt_header_row_height + index * @gant_row_height)
    end
  end

  def paint_gantt_header_row(page)
    if page[:text_column]
      paint_gantt_text_box(heading, 0, 0, @gantt_text_column_width, @gantt_header_row_height,
                           @gant_text_cell_padding * 2, 0, { size: 10, style: :bold })
      paint_gantt_line_h(0, @gantt_text_column_width, 0)
    end
    page[:header].each do |cell|
      paint_gantt_text_box(cell[:text], cell[:x], cell[:y], cell[:width], cell[:height], 0, 0, { size: 10, style: :bold, align: :center })
      paint_gantt_line_h(cell[:x], cell[:x] + cell[:width], cell[:y])
      paint_gantt_line_v(cell[:y], cell[:y] + cell[:height], cell[:x])
    end
  end

  def paint_gantt_header_cell(text, columns, y, height)
    x1 = columns.first[:x]
    x2 = columns.last[:x] + columns.last[:width]
    paint_gantt_text_box(text, x1, y, x2 - x1, height, 0, 0, { size: 8, style: :bold, align: :center })
    paint_gantt_line_h(x1, x2, y)
    paint_gantt_line_v(y, y + height, x1)
  end

  def paint_gantt_shape_bar(shape)
    paint_gant_rect(shape[:x1], shape[:y1], [shape[:x2] - shape[:x1], 0.1].max, shape[:y2] - shape[:y1], shape[:color])
  end

  def paint_gantt_shape_milestone(shape)
    diamond_size = [@gant_column_width, @gant_row_height].min / 2
    diamond_half_size = diamond_size / 2
    center_x = @gantt_mode == :day ? shape[:x] + @gant_column_width / 2 : shape[:x1] + diamond_half_size
    center_y = shape[:y] + @gant_row_height / 2
    pdf.rotate(45, origin: [@pdf.bounds.left + center_x, @pdf.bounds.top - center_y]) do
      paint_gant_rect(center_x - diamond_half_size, center_y - diamond_half_size, diamond_size, diamond_size, shape[:color])
    end
  end

  def paint_gantt_shape(shape)
    if shape[:type] == :milestone
      paint_gantt_shape_milestone(shape)
    else
      paint_gantt_shape_bar(shape)
    end
  end

  def paint_gantt_wp(wp, index)
    paint_gantt_text_box(
      "#{wp.type} ##{wp.id} - #{wp.subject}",
      0, @gantt_header_row_height + (index * @gant_row_height),
      @gantt_text_column_width, @gant_row_height,
      @gant_text_cell_padding * 2, @gant_text_cell_padding)
  end

  def paint_gantt_line(x, y, x2, y2)
    @pdf.stroke do
      @pdf.line_width = 0.5
      @pdf.stroke_color @gantt_grid_color
      @pdf.line x, y, x2, y2
    end
  end

  def paint_gantt_line_h(x1, x2, y)
    paint_gantt_line(@pdf.bounds.left + x1, @pdf.bounds.top - y, @pdf.bounds.left + x2, @pdf.bounds.top - y)
  end

  def paint_gantt_line_v(y1, y2, x)
    paint_gantt_line(@pdf.bounds.left + x, @pdf.bounds.top - y1, @pdf.bounds.left + x, @pdf.bounds.top - y2)
  end

  def paint_gant_rect(x, y, width, height, color)
    current_color = @pdf.fill_color
    @pdf.fill_color color
    @pdf.fill_rectangle([@pdf.bounds.left + x, @pdf.bounds.top - y], width, height)
    @pdf.fill_color = current_color
  end

  def paint_gantt_text_box(text, x_offset, y_offset, width, height, padding_h, padding_v, additional_options = {})
    @pdf.text_box(text, at: [@pdf.bounds.left + x_offset + padding_h, @pdf.bounds.top - padding_v - y_offset],
                  width: width - padding_h * 2,
                  height: height - 2 - padding_v * 2,
                  overflow: :shrink_to_fit, min_font_size: 5, valign: :center, size: 8, leading: 0, **additional_options)
  end


  def gantt_wp_color(wp)
    wp.type.color.hexcode.sub("#", "")
  end

  def calc_end_offset(wp, date)
    case @gantt_mode
    when :quarter
      wp_date = wp.due_date.nil? ? Date.today : wp.due_date
      quarter = quarter_of_date(date)
      test_date = Date.new(date.year, (quarter * 3), -1)
      return 0 if wp_date >= test_date

      width_per_day = @gant_column_width.to_f / days_of_quarter(date)
      day_in_quarter = day_in_quarter(wp_date)
      @gant_column_width - day_in_quarter * width_per_day
    when :month
      wp_date = wp.due_date.nil? ? Date.today : wp.due_date
      test_date = Date.new(date.year, date.month, -1)
      return 0 if wp_date >= test_date

      width_per_day = @gant_column_width.to_f / days_of_month(test_date)
      day_in_month = wp_date.day
      @gant_column_width - day_in_month * width_per_day
    else
      0
    end
  end

  def calc_start_offset(wp, date)
    case @gantt_mode
    when :quarter
      quarter = quarter_of_date(date)
      test_date = Date.new(date.year, (quarter * 3) - 2, 1)
      return 0 if wp.start_date <= test_date

      width_per_day = @gant_column_width.to_f / days_of_quarter(date)
      day_in_quarter = day_in_quarter(wp.start_date) - 1
      day_in_quarter * width_per_day
    when :month
      test_date = Date.new(date.year, date.month, 1)
      return 0 if wp.start_date <= test_date

      width_per_day = @gant_column_width.to_f / days_of_month(date)
      day_in_month = wp.start_date.day - 1
      day_in_month * width_per_day
    else
      return 0
    end
  end

  def quarter_of_date(date)
    (date.month / 3.0).ceil
  end

  def days_of_month(date)
    Date.new(date.year, date.month, -1).day
  end

  def day_in_quarter(date)
    date.yday - Date.new(date.year, (quarter_of_date(date) * 3) - 2, 1).yday + 1
  end

  def days_of_quarter(date)
    quarter = quarter_of_date(date)
    days = 0
    (1..3).each do |q|
      days += days_of_month(Date.new(date.year, (quarter * 3) - 2 + q, 1))
    end
    days
  end

  def wp_on_month?(work_package, date)
    start_date = work_package.start_date
    end_date = work_package.due_date.nil? ? Date.today : work_package.due_date
    Range.new(Date.new(start_date.year, start_date.month, 1), Date.new(end_date.year, end_date.month, -1))
         .include?(date)
  end

  def wp_on_day?(work_package, date)
    start_date = work_package.start_date
    end_date = work_package.due_date.nil? ? Date.today : work_package.due_date
    Range.new(start_date, end_date).include?(date)
  end

  def wp_on_quarter?(work_package, date)
    start_date = work_package.start_date
    end_date = work_package.due_date.nil? ? Date.today : work_package.due_date
    Range.new(Date.new(start_date.year, (quarter_of_date(start_date) * 3) - 2, 1), Date.new(end_date.year, (quarter_of_date(end_date) * 3), -1))
         .include?(date)
  end
end

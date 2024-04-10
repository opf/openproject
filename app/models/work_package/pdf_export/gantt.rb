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
    @gantt_mode = :day
    @gantt_text_column_width = pdf.bounds.width / 4
    @gant_column_width = 24
    @gantt_header_row_height = 30
    @gant_row_height = 20
    @gant_cell_padding = 1
    @gant_bar_cell_padding = 4
    @gantt_filter_empty = false
    @gantt_grid_color = "9b9ea3"

    gantt_columns_width_first_page = pdf.bounds.width - @gantt_text_column_width
    @gantt_columns_per_first_page = (gantt_columns_width_first_page / @gant_column_width).floor
    @gantt_columns_per_next_page = (pdf.bounds.width / @gant_column_width).floor

    # add space right to the first column
    @gantt_text_column_width = pdf.bounds.width - (@gantt_columns_per_first_page * @gant_column_width)
    gant_rows_height = pdf.bounds.height - @gantt_header_row_height
    @gantt_work_packages_per_page = (gant_rows_height / @gant_row_height).floor

    # add space bottom to the first row
    @gantt_header_row_height = pdf.bounds.height - (@gantt_work_packages_per_page * @gant_row_height)

    pages = build_gantt_pages(work_packages)

    pages = pages.filter { |page| page[:columns].map { |c| c[:work_packages] }.flatten.any? } if @gantt_filter_empty

    # paint pages
    pages.each_with_index do |page, page_index|
      # paint column lines
      paint_gantt_grid(page)
      # paint header row
      paint_gantt_header_row(page)
      # paint work packages
      page[:work_packages].each_with_index do |wp, index|
        paint_gantt_wp(page, wp, index)
      end
      @pdf.start_new_page if page_index != pages.size - 1
    end
  end

  private

  def build_gantt_page(dates, index, work_packages)
    {
      index: index,
      columns: dates.each_with_index.map do |date, col_index|
        build_gantt_column(col_index, date, work_packages)
      end,
      work_packages: work_packages
    }
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

  def build_gantt_column(index, date, work_packages)
    work_packages_on_date =
      case @gantt_mode
      when :day
        work_packages.select { |work_package| wp_on_day?(work_package, date) }
      else
        # when :month
        work_packages.select { |work_package| wp_on_month?(work_package, date) }
      end
    {
      index: index,
      date: date,
      work_packages: work_packages_on_date
    }
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
            else
              # when :month
              (start_date..end_date).map { |d| Date.new(d.year, d.month, -1) }.uniq
            end
    vertical_pages_needed = (wps.size.to_f / @gantt_work_packages_per_page.to_f).ceil
    (0..vertical_pages_needed - 1)
      .map { |v_index| build_gantt_horizontal_pages(wps.slice(v_index * @gantt_work_packages_per_page, @gantt_work_packages_per_page), dates) }
      .flatten
  end

  def build_gantt_horizontal_pages(work_packages, dates)
    horizontal_pages_needed = [((dates.size - @gantt_columns_per_first_page).to_f / @gantt_columns_per_next_page.to_f).ceil, 0].max + 1
    result = []
    dates_on_page = dates.slice(0, @gantt_columns_per_first_page)
    result << build_gantt_page(dates_on_page, 0, work_packages)

    list = (0..horizontal_pages_needed - 2)
    list.map do |index|
      dates_on_page = dates.slice(@gantt_columns_per_first_page + index * @gantt_columns_per_next_page, @gantt_columns_per_next_page)
      result << build_gantt_page(dates_on_page, index + 1, work_packages)
    end
    result
  end

  def paint_gantt_wp_milestone(y, page, wp, paint_columns)
    paint_column_first = paint_columns.first
    offset = page[:index] == 0 ? @gantt_text_column_width : 0
    x = offset + (paint_column_first[:index] * @gant_column_width)
    center_x = @pdf.bounds.left + x + @gant_column_width / 2
    center_y = @pdf.bounds.top - y - @gant_row_height / 2
    diamond_size = @gant_column_width / 3
    pdf.rotate(45, origin: [center_x, center_y]) do
      paint_gant_rect(center_x - diamond_size / 2, center_y + diamond_size / 2, diamond_size, diamond_size, gantt_wp_color(wp))
    end
  end

  def paint_gant_rect(x, y, width, height, color)
    current_color = @pdf.fill_color
    @pdf.fill_color color
    @pdf.fill_rectangle([x, y], width, height)
    @pdf.fill_color = current_color
  end

  def paint_gantt_wp_bar(y, page, wp, paint_columns)
    paint_column_first = paint_columns.first
    paint_column_last = paint_columns.last
    start_offset = calc_start_offset(wp, paint_column_first[:date])
    end_offset = calc_end_offset(wp, paint_column_last[:date])
    offset = page[:index] == 0 ? @gantt_text_column_width : 0
    x1 = offset + (paint_column_first[:index] * @gant_column_width) + start_offset
    x2 = offset + ((paint_column_last[:index] + 1) * @gant_column_width) - end_offset
    paint_gant_rect(@pdf.bounds.left + x1, @pdf.bounds.top - y - @gant_bar_cell_padding, x2 - x1, @gant_row_height - @gant_bar_cell_padding * 2, gantt_wp_color(wp))
  end

  def gantt_wp_color(wp)
    wp.type.color.hexcode.sub("#", "")
  end

  def paint_gantt_wp(page, wp, index)
    y = @gantt_header_row_height + (index * @gant_row_height)
    # paint row line
    paint_gantt_line_h(0, @pdf.bounds.width, y + @gant_row_height)
    # paint row title
    if page[:index] == 0
      paint_gantt_text_box("#{wp.type} ##{wp.id} - #{wp.subject}", 0, y, @gantt_text_column_width, @gant_row_height,
                           @gant_bar_cell_padding * 2, @gant_bar_cell_padding)
    end
    # paint work package in gantt
    paint_columns = page[:columns].select { |column| column[:work_packages].include?(wp) }
    return if paint_columns.empty?
    if wp.milestone?
      paint_gantt_wp_milestone(y, page, wp, paint_columns)
    else
      paint_gantt_wp_bar(y, page, wp, paint_columns)
    end
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

  def paint_gantt_grid(page)
    paint_gantt_line_v(0, @pdf.bounds.height, 0)
    paint_gantt_line_v(0, @pdf.bounds.height, @gantt_text_column_width) if page[:index] == 0
    offset = page[:index] == 0 ? @gantt_text_column_width : 0
    page[:columns].each_with_index do |_, index|
      paint_gantt_line_v(@gantt_header_row_height, @pdf.bounds.height, offset + ((index + 1) * @gant_column_width))
    end
    paint_gantt_line_h(0, @pdf.bounds.width, 0)
    paint_gantt_line_h(0, @pdf.bounds.width, @gantt_header_row_height)
    paint_gantt_line_h(0, @pdf.bounds.width, @pdf.bounds.height)
    paint_gantt_line_v(0, @pdf.bounds.height, @pdf.bounds.width)
  end

  def paint_gantt_text_box(text, x_offset, y_offset, width, height, padding_h, padding_v, additional_options = {})
    @pdf.text_box(text, at: [@pdf.bounds.left + x_offset + padding_h, @pdf.bounds.top - padding_v - y_offset],
                  width: width - padding_h * 2,
                  height: height - 2 - padding_v * 2,
                  overflow: :shrink_to_fit, min_font_size: 5, valign: :center, size: 8, leading: 0, **additional_options)
  end

  def paint_gantt_header_cell(text, page, columns, y, height)
    offset = page[:index] == 0 ? @gantt_text_column_width : 0
    x = offset + (columns.first[:index] * @gant_column_width)
    x2 = offset + ((columns.last[:index] + 1) * @gant_column_width)
    paint_gantt_text_box(text, x, y, columns.size * @gant_column_width, height,
                         0, 0, { size: 8, style: :bold, align: :center })
    paint_gantt_line_h(x, x2, y + height)
    paint_gantt_line_v(y, y + height, x2)
  end

  def paint_gantt_header_row(page)
    if page[:index] == 0
      paint_gantt_text_box(heading, 0, 0, @gantt_text_column_width, @gantt_header_row_height,
                           @gant_bar_cell_padding * 2, 0, { size: 10, style: :bold })
    end
    height = @gantt_header_row_height / 3
    y = 0
    years = page[:columns].map { |column| column[:date].year }.uniq
    years.each do |year|
      year_columns = page[:columns].select { |column| column[:date].year == year }
      paint_gantt_header_cell(year.to_s, page, year_columns, y, height)
    end

    if @gantt_mode == :month
      y += height
      quarters = page[:columns].map { |column| [quarter_of_date(column[:date]), column[:date].year] }.uniq
      quarters.each do |quarter_tuple|
        quarter, year = quarter_tuple
        quarter_columns = page[:columns].select { |column| column[:date].year == year && quarter_of_date(column[:date]) == quarter }
        paint_gantt_header_cell("Q#{quarter}", page, quarter_columns, y, height)
      end
    end

    y += height
    months = page[:columns].map { |column| [column[:date].month, column[:date].year] }.uniq
    months.each do |month_tuple|
      month, year = month_tuple
      month_columns = page[:columns].select { |column| column[:date].year == year && column[:date].month == month }
      paint_gantt_header_cell(month_columns.first[:date].strftime("%b"), page, month_columns, y, height)
    end

    return unless @gantt_mode == :day

    y += height
    page[:columns].each_with_index do |column|
      paint_gantt_header_cell(column[:date].day.to_s, page, [column], y, height)
    end
  end

  def calc_end_offset(wp, date)
    return 0 if @gantt_mode == :day

    wp_date = wp.due_date.nil? ? Date.today : wp.due_date
    test_date = Date.new(date.year, date.month, -1)
    return 0 if wp_date >= test_date

    days = days_of_month(test_date)
    width_per_day = @gant_column_width.to_f / days.to_f
    day_in_month = wp_date.day
    @gant_column_width - (day_in_month * width_per_day)
  end

  def calc_start_offset(wp, date)
    return 0 if @gantt_mode == :day

    test_date = Date.new(date.year, date.month, 1)
    return 0 if wp.start_date <= test_date

    days = days_of_month(date)
    width_per_day = @gant_column_width.to_f / days.to_f
    day_in_month = wp.start_date.day - 1
    day_in_month * width_per_day
  end

  def quarter_of_date(date)
    (date.month / 3.0).ceil
  end

  def days_of_month(date)
    Date.new(date.year, date.month, -1).day
  end
end

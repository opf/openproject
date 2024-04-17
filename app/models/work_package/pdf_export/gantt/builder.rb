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

require_relative "data"

# Builder for Gantt charts

class GanttBuilder
  GANTT_BAR_CELL_PADDING = 5
  GANTT_TEXT_CELL_PADDING = 2
  GANTT_ROW_HEIGHT = 20

  def initialize(pdf, title, column_width)
    @pdf = pdf
    @title = title
    @column_width = column_width
    @draw_gantt_lines = true
    init_defaults
  end

  def build(work_packages)
    @all_work_packages = work_packages
    adjust_to_pages
    page_groups = build_pages(work_packages)
    # if there are not enough columns for even the first page of horizontal pages => distribute space to all columns
    if page_groups[0].pages.length == 1
      distribute_to_first_page(page_groups[0].pages.first.columns.length)
      page_groups = build_pages(work_packages)
    end
    build_dep_lines(page_groups) if @draw_gantt_lines
    page_groups.flat_map { |page_group| page_group.pages }
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

  def distribute_to_first_page(nr_of_columns)
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
      group_work_packages = work_packages.slice(v_index * @rows_per_page, @rows_per_page)
      GanttPageGroup.new(v_index, group_work_packages, build_horizontal_pages(group_work_packages, dates, horizontal_pages_needed))
    end
  end

  def build_column_dates(work_packages)
    wp_dates = collect_work_packages_dates(work_packages)
    build_column_dates_range(wp_dates.first..wp_dates.last)
  end

  def collect_work_packages_dates(work_packages)
    work_packages.map do |work_package|
      [work_package.start_date || work_package.due_date, work_package.due_date || Time.zone.today]
    end.flatten.uniq.sort
  end

  def build_header_span_cell(text, top, height, columns)
    GanttHeaderCell.new(text, columns.first.left, columns.last.right, top, top + height)
  end

  def build_header_cells(columns)
    parts = header_row_parts
    height = @header_row_height / parts.length
    result = parts.each_with_index.map do |part, index|
      top = index * height
      case part
      when :years
        build_header_cells_years(top, height, columns)
      when :quarters
        build_header_cells_quarters(top, height, columns)
      when :months
        build_header_cells_months(top, height, columns)
      when :days
        build_header_cells_days(top, height, columns)
      else
        []
      end
    end
    result.flatten
  end

  def build_header_row_part(columns, top, height, mapping_lambda, compare_lambda, title_lambda)
    columns
      .map { |column| mapping_lambda.call(column.date) }
      .uniq
      .map do |entry|
      part_columns = columns.select { |column| compare_lambda.call(column.date, entry) }
      build_header_span_cell(title_lambda.call(entry), top, height, part_columns)
    end
  end

  def build_header_cells_years(top, height, columns)
    build_header_row_part(columns, top, height,
                          ->(date) { date.year },
                          ->(date, year) { date.year == year },
                          ->(year) { year.to_s })
  end

  def build_header_cells_quarters(top, height, columns)
    build_header_row_part(columns, top, height,
                          ->(date) { [date.year, date.quarter] },
                          ->(date, quarter_tuple) {
                            date.year == quarter_tuple[0] && date.quarter == quarter_tuple[1]
                          },
                          ->(quarter_tuple) { "Q#{quarter_tuple[1]}" })
  end

  def build_header_cells_months(top, height, columns)
    build_header_row_part(columns, top, height,
                          ->(date) { [date.year, date.month] },
                          ->(date, month_tuple) { date.year == month_tuple[0] && date.month == month_tuple[1] },
                          ->(month_tuple) { Date.new(month_tuple[0], month_tuple[1], 1).strftime("%b") })
  end

  def build_header_cells_days(top, height, columns)
    columns.map { |column| build_header_span_cell(column.date.day.to_s, top, height, [column]) }
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

  def build_dep_lines(page_groups)
    @all_work_packages.each do |work_package|
      work_package.relations.each do |relation|
        target_work_package = relation.other_work_package(work_package)
        next unless @all_work_packages.include?(target_work_package)

        if relation.to == work_package && relation.relation_type == Relation::TYPE_FOLLOWS
          build_dep_line(work_package, target_work_package, page_groups)
        end
        if relation.from == work_package && relation.relation_type == Relation::TYPE_PRECEDES
          build_dep_line(work_package, target_work_package, page_groups)
        end
      end
    end
  end

  def collect_line_infos(work_package, page_groups)
    rows = page_groups.map do |page_group|
      page_group.pages.filter_map { |page| page.rows.find { |r| r.work_package == work_package } }
    end.flatten
    draw_rows = rows.reject { |row| row.shape.nil? }
    start = draw_rows.max_by { |row| row.page.index }
    finish = draw_rows.max_by { |row| row.page.index }
    GanttLineInfo.new(rows[0].page.group, rows, draw_rows,
                      start, start.shape.left, start.shape.top + (start.shape.height / 2),
                      finish, finish.shape.right, finish.shape.top + (finish.shape.height / 2)
    )
  end

  def build_dep_line(work_package, target_work_package, page_groups)
    line_source = collect_line_infos(work_package, page_groups)
    line_target = collect_line_infos(target_work_package, page_groups)
    if line_source.finish_row.page == line_target.start_row.page
      build_same_page_dep_lines(line_source, line_target)
    elsif line_source.page_group == line_target.page_group
      build_multi_page_dep_line(line_source, line_target)
    else
      build_multi_group_page_dep_line(line_source, line_target, page_groups)
    end
  end

  def build_same_page_dep_lines(line_source, line_target)
    lines = if line_target.start_x - 10 <= line_source.finish_x
              dep_lines_step(line_source.finish_row.bottom, line_source.finish_x, line_source.finish_y, line_target.start_x, line_target.start_y)
            else
              dep_lines_straight(line_source.finish_x, line_source.finish_y, line_target.start_x, line_target.start_y)
            end
    line_source.start_row.page.add_lines(lines)
  end

  def build_multi_page_dep_line(line_source, line_target)
    page_group = line_source.page_group
    i = line_source.page_group.pages.index(line_source.finish_row.page)
    j = line_target.page_group.pages.index(line_target.start_row.page)
    if i < j
      page = line_source.finish_row.page
      lines = [{ left: line_source.finish_x, right: page.columns.last.right, top: line_source.finish_y, bottom: line_source.finish_y }]
      page.add_lines(lines)

      ((i + 1)..(j - 1)).each do |index|
        page = page_group.pages[index]
        lines = [{ left: page.columns.first.left, right: page.columns.last.right, top: line_source.finish_y, bottom: line_source.finish_y }]
        page.add_lines(lines)
      end

      page = line_target.start_row.page
      lines = dep_lines_straight(page.columns.first.left, line_source.finish_y, line_target.start_x, line_target.start_y)
      page.add_lines(lines)
    else
      y = line_source.finish_row.bottom
      page = line_source.finish_row.page
      lines = [
        { left: line_source.finish_x, right: line_source.finish_x + 5, top: line_source.finish_y, bottom: line_source.finish_y },
        { left: line_source.finish_x + 5, right: line_source.finish_x + 5, top: line_source.finish_y, bottom: y },
        { left: line_source.finish_row.left, right: line_source.finish_x + 5, top: y, bottom: y }
      ]
      page.add_lines(lines)

      ((j + 1)..(i - 1)).each do |index|
        page = page_group.pages[index]
        lines = [{ left: page.columns.first.left, right: page.columns.last.right, top: y, bottom: y }]
        page.add_lines(lines)
      end
      page = line_target.start_row.page
      lines = [
        { left: line_target.start_x - 5, right: page.columns.last.right, top: y, bottom: y },
        { left: line_target.start_x - 5, right: line_target.start_x - 5, top: y, bottom: line_target.start_y },
        { left: line_target.start_x - 5, right: line_target.start_x, top: line_target.start_y, bottom: line_target.start_y }
      ]
      page.add_lines(lines)
    end
  end

  def build_multi_group_page_dep_line(line_source, line_target, page_groups) end

  def dep_lines_straight(source_left, source_top, target_left, target_top)
    [
      { left: source_left, right: target_left - 5, top: source_top, bottom: source_top },
      { left: target_left - 5, right: target_left - 5, top: source_top, bottom: target_top },
      { left: target_left - 5, right: target_left, top: target_top, bottom: target_top }
    ]
  end

  def dep_lines_step(source_row_bottom, source_left, source_top, target_left, target_top)
    [
      { left: source_left, right: source_left + 5, top: source_top, bottom: source_top },
      { left: source_left + 5, right: source_left + 5, top: source_top, bottom: source_row_bottom },
      { left: target_left - 5, right: source_left + 5, top: source_row_bottom, bottom: source_row_bottom },
      { left: target_left - 5, right: target_left - 5, top: source_row_bottom, bottom: target_top },
      { left: target_left - 5, right: target_left, top: target_top, bottom: target_top }
    ]
  end

  def build_page(dates, index, work_packages)
    x = index == 0 ? @text_column_width : 0
    columns = dates.each_with_index.map { |date, col_index| build_column(date, x + (col_index * @column_width), work_packages) }
    rows = work_packages.each_with_index.map { |work_package, row_index| build_row(work_package, row_index, columns) }
    GanttPage.new(
      index,
      work_packages,
      build_header_cells(columns),
      rows,
      columns,
      index == 0 ? GanttTextColumn.new(@title,
                                       0, @text_column_width, 0, GANTT_ROW_HEIGHT,
                                       GANTT_TEXT_CELL_PADDING * 2, GANTT_TEXT_CELL_PADDING) : nil,
      x + (dates.size * @column_width),
      @header_row_height + (@rows_per_page * GANTT_ROW_HEIGHT),
      @header_row_height
    )
  end

  def build_row(work_package, row_index, columns)
    paint_columns = columns.filter { |column| column.work_packages.include?(work_package) }
    top = @header_row_height + (row_index * GANTT_ROW_HEIGHT)
    shape = build_shape(top, paint_columns, work_package) unless paint_columns.empty?
    GanttRow.new(row_index, work_package, shape, 0, top, GANTT_ROW_HEIGHT)
  end

  def bar_layout(paint_columns, work_package)
    x1 = calc_start_offset(work_package, paint_columns.first.date)
    x2 = paint_columns.last.right - paint_columns.first.left -
      calc_end_offset(work_package, paint_columns.last.date)
    [x1, x2, GANTT_BAR_CELL_PADDING, GANTT_ROW_HEIGHT - GANTT_BAR_CELL_PADDING]
  end

  def build_shape_bar(top, paint_columns, work_package)
    left = paint_columns.first.left
    x1, x2, y1, y2 = bar_layout(paint_columns, work_package)
    GanttShape.new(:bar, left + x1, [x2 - x1, 0.1].max, top + y1, y2 - y1,
                   work_package, paint_columns, wp_type_color(work_package))
  end

  def wp_type_color(work_package)
    work_package.type.color.hexcode.sub("#", "")
  end

  def milestone_layout(top, paint_columns, work_package)
    diamond_size = ([@column_width, GANTT_ROW_HEIGHT].min / 3).to_f * 2
    x1 = if milestone_position_centered?
           (@column_width - diamond_size) / 2
         else
           calc_start_offset(work_package, paint_columns.first.date)
         end
    y1 = top + ((GANTT_ROW_HEIGHT - diamond_size) / 2)
    [x1, y1, diamond_size]
  end

  def build_shape_milestone(top, paint_columns, work_package)
    left = paint_columns.first.left
    x1, y1, diamond_size = milestone_layout(top, paint_columns, work_package)
    GanttShape.new(:milestone, left + x1, diamond_size, y1, diamond_size,
                   work_package, paint_columns, wp_type_color(work_package))
  end

  def build_shape(top, paint_columns, work_package)
    if work_package.milestone?
      build_shape_milestone(top, paint_columns, work_package)
    else
      build_shape_bar(top, paint_columns, work_package)
    end
  end

  def build_column(date, left, work_packages)
    GanttColumn.new(date, left, @column_width, work_packages_on_date(date, work_packages))
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
    start_date = work_package.start_date || work_package.due_date
    return 0 if start_date <= test_date

    width_per_day = @column_width.to_f / date.end_of_month.day
    day_in_month = start_date.day - 1
    day_in_month * width_per_day
  end

  def calc_end_offset(work_package, date)
    end_date = work_package.due_date || Time.zone.today
    test_date = Date.new(date.year, date.month, -1)
    return 0 if end_date >= test_date

    width_per_day = @column_width.to_f / test_date.day
    day_in_month = end_date.day
    @column_width - (day_in_month * width_per_day)
  end

  def wp_on_month?(work_package, date)
    start_date = work_package.start_date || work_package.due_date
    end_date = work_package.due_date || Time.zone.today
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
    start_date = work_package.start_date || work_package.due_date
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
    %i[years quarters]
  end

  def work_packages_on_date(date, work_packages)
    work_packages.select { |work_package| wp_on_quarter?(work_package, date) }
  end

  def calc_start_offset(work_package, date)
    start_date = work_package.start_date || work_package.due_date
    return 0 if start_date <= date.beginning_of_quarter

    width_per_day = @column_width.to_f / days_of_quarter(date)
    day_in_quarter = day_in_quarter(start_date) - 1
    day_in_quarter * width_per_day
  end

  def calc_end_offset(work_package, date)
    end_date = work_package.due_date || Time.zone.today
    return 0 if end_date >= date.end_of_quarter

    width_per_day = @column_width.to_f / days_of_quarter(date)
    day_in_quarter = day_in_quarter(end_date)
    @column_width - (day_in_quarter * width_per_day)
  end

  def day_in_quarter(date)
    date.yday - date.beginning_of_quarter.yday + 1
  end

  def days_of_quarter(date)
    (1..3).map { |q| Date.new(date.year, (date.quarter * 3) - 3 + q, -1).day }.sum
  end

  def wp_on_quarter?(work_package, date)
    start_date = work_package.start_date || work_package.due_date
    end_date = work_package.due_date || Time.zone.today
    Range.new(start_date.beginning_of_quarter, end_date.end_of_quarter).include?(date)
  end
end


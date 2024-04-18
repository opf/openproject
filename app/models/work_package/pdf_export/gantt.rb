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

# How this works:
# The Gantt chart PDF export is built up of several components:
# - GanttBuilder: This is the main class that builds the Gantt chart. It is responsible for creating the pages, columns, rows, and shapes.
#   - GanttBuilderMonths: This class is a subclass of GanttBuilder and is responsible for building the Gantt chart with months as the zoom level.
#   - GanttBuilderDays: This class is a subclass of GanttBuilder and is responsible for building the Gantt chart with days as the zoom level.
#   - GanttBuilderQuarters: This class is a subclass of GanttBuilder and is responsible for building the Gantt chart with quarters as the zoom level.
# - GanttPainter: This class is responsible for painting the Gantt chart. It paints the grid, header row, lines, bars, milestones, and rows.
# - Data classes: These classes are used to store the data that is used to build the Gantt chart.
#
# 1. Build the data classes, do the layout, measuring, etc.
# 2. Paint the Gantt chart into the PDF

module WorkPackage::PDFExport::Gantt
  def write_work_packages_gantt!(work_packages, _)
    wps = work_packages.reject { |work_package| work_package.start_date.nil? && work_package.due_date.nil? }
    return if wps.empty?

    zoom_levels = [
      [:day, 32],
      [:day, 24],
      [:day, 18],
      [:month, 128],
      [:month, 64],
      [:month, 32],
      [:month, 24],
      [:quarter, 128],
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
    pages = pages.filter { |page| page.columns.pluck(:work_packages).flatten.any? } if options[:filter_empty]
    painter = GanttPainter.new(pdf)
    painter.paint(pages)
  end


  class GanttBuilder
    BAR_CELL_PADDING = 5
    TEXT_CELL_PADDING = 2
    GANTT_ROW_HEIGHT = 20
    DEFAULT_HEADER_ROW_HEIGHT = 30
    DEFAULT_TEXT_COLUMN_DIVIDER = 4
    TEXT_COLUMN_MAX_WIDTH = 250
    LINE_STEP = 5

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
      if page_groups[0].pages.length == 1
        # if there are not enough columns for even the first page of horizontal pages => distribute space to all columns
        distribute_to_first_page(page_groups[0].pages.first.columns.length)
        page_groups = build_pages(work_packages)
      end
      build_dep_lines(page_groups) if @draw_gantt_lines
      page_groups.flat_map(&:pages)
    end

    private

    # Initializes the default values
    def init_defaults
      @header_row_height = DEFAULT_HEADER_ROW_HEIGHT
      @text_column_width = [@pdf.bounds.width / DEFAULT_TEXT_COLUMN_DIVIDER, TEXT_COLUMN_MAX_WIDTH].min
      @nr_columns = (@pdf.bounds.width / @column_width).floor
    end

    def adjust_to_pages
      # distribute empty space right to the default column widths
      distribute_to_next_page_column

      # distribute empty space right on the first page to the first column
      distribute_to_first_column

      # distribute empty space bottom to the first row
      distribute_to_header_row
    end

    # distribute empty space right to the default column widths
    def distribute_to_next_page_column
      gantt_columns_space_next_page = @pdf.bounds.width - (@nr_columns * @column_width)
      @column_width += gantt_columns_space_next_page / @nr_columns
      @nr_columns = (@pdf.bounds.width / @column_width).floor
    end

    # distribute empty space right on the first horizontal page to the text column
    def distribute_to_first_column
      gantt_columns_width_first_page = @pdf.bounds.width - @text_column_width
      @nr_columns_first_page = (gantt_columns_width_first_page / @column_width).floor
      @text_column_width = @pdf.bounds.width - (@nr_columns_first_page * @column_width)
    end

    # distribute empty space at bottom to the header row
    def distribute_to_header_row
      gant_rows_height = @pdf.bounds.height - @header_row_height
      @rows_per_page = (gant_rows_height / GANTT_ROW_HEIGHT).floor
      @header_row_height = @pdf.bounds.height - (@rows_per_page * GANTT_ROW_HEIGHT)
    end

    # distribute space to all columns on first horizontal page
    # if there are not enough columns for more horizontal pages
    def distribute_to_first_page(nr_of_columns)
      init_defaults
      @column_width = (@pdf.bounds.width - @text_column_width) / nr_of_columns
      @nr_columns_first_page = nr_of_columns
      @nr_columns = nr_of_columns
    end

    # Builds all page groups for the given work packages
    # @param [Array<WorkPackage>] work_packages
    # @return [Array<GanttDataPageGroup>]
    def build_pages(work_packages)
      dates = collect_column_dates(work_packages)
      vertical_pages_needed = (work_packages.size / @rows_per_page.to_f).ceil
      horizontal_pages_needed = [((dates.size - @nr_columns_first_page) / @nr_columns.to_f).ceil, 0].max + 1
      build_vertical_pages(work_packages, dates, vertical_pages_needed, horizontal_pages_needed)
    end

    # Builds all page groups for the given work packages and dates
    # @param [Array<WorkPackage>] work_packages
    # @param [Array<Date>] dates
    # @param [Integer] vertical_pages_needed
    # @param [Integer] horizontal_pages_needed
    # @return [Array<GanttDataPageGroup>]
    def build_vertical_pages(work_packages, dates, vertical_pages_needed, horizontal_pages_needed)
      (0..vertical_pages_needed - 1).map do |v_index|
        group_work_packages = work_packages.slice(v_index * @rows_per_page, @rows_per_page)
        GanttDataPageGroup.new(v_index, group_work_packages,
                               build_horizontal_pages(group_work_packages, dates, horizontal_pages_needed))
      end
    end

    # Builds pages for the given work packages and dates
    # @param [Array<WorkPackage>] work_packages
    # @param [Array<Date>] dates
    # @param [Integer] horizontal_pages_needed
    # @return [Array<GanttDataPage>]
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

    # Builds a page for the given dates and work packages
    # @param [Array<Date>] dates
    # @param [Integer] page_index
    # @param [Array<WorkPackage>] work_packages
    # @return [GanttDataPage]
    def build_page(dates, page_index, work_packages)
      left = (page_index == 0 ? @text_column_width : 0)
      columns = build_columns(left, dates, work_packages)
      GanttDataPage.new(
        page_index,
        work_packages,
        build_header_cells(columns),
        build_rows(columns, work_packages),
        columns,
        build_text_column(page_index),
        left + (dates.size * @column_width),
        @header_row_height + (@rows_per_page * GANTT_ROW_HEIGHT),
        @header_row_height
      )
    end

    # Builds the gantt columns for the given dates
    # @param [Float] left
    # @param [Array<Date>] dates
    # @param [Array<WorkPackage>] work_packages
    # @return [Array<GanttDataColumn>]
    def build_columns(left, dates, work_packages)
      dates.each_with_index.map { |date, col_index| build_column(date, left + (col_index * @column_width), work_packages) }
    end

    # Builds the gantt column for the given date
    # @param [Date] date
    # @param [Float] left
    # @param [Array<WorkPackage>] work_packages
    # @return [GanttDataColumn]
    def build_column(date, left, work_packages)
      GanttDataColumn.new(date, left, @column_width, work_packages_on_date(date, work_packages))
    end

    # Builds the header cells for the given columns
    # @param [Array<GanttDataColumn>] columns
    # @return [Array<GanttDataHeaderCell>]
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

    # Builds the header cells for the given text spanning the given columns
    # @param [String] text
    # @param [Float] top
    # @param [Float] height
    # @param [Array<GanttDataColumn>] columns
    # @return [GanttDataHeaderCell]
    def build_header_cell(text, top, height, columns)
      GanttDataHeaderCell.new(text, columns.first.left, columns.last.right, top, top + height)
    end

    # Builds the header cells for the given columns
    # @param [Array<GanttDataColumn>] columns
    # @param [Float] top
    # @param [Float] height
    # @param [Proc] mapping_lambda - lambda to map the date to a column
    # @param [Proc] compare_lambda - lambda to compare a date with the column date
    # @param [Proc] title_lambda - lambda to get the title for the header cell
    # @return [Array<GanttDataHeaderCell>]
    def build_header_cells_parts(columns, top, height, mapping_lambda, compare_lambda, title_lambda)
      columns
        .map { |column| mapping_lambda.call(column.date) }
        .uniq
        .map do |entry|
        part_columns = columns.select { |column| compare_lambda.call(column.date, entry) }
        build_header_cell(title_lambda.call(entry), top, height, part_columns)
      end
    end

    # Builds the year row header cells for the given columns
    # @param [Float] top
    # @param [Float] height
    # @param [Array<GanttDataColumn>] columns
    # @return [Array<GanttDataHeaderCell>]
    def build_header_cells_years(top, height, columns)
      build_header_cells_parts(columns, top, height,
                               ->(date) { date.year },
                               ->(date, year) { date.year == year },
                               ->(year) { year.to_s })
    end

    # Builds the quarter row header cells for the given columns
    # @param [Float] top
    # @param [Float] height
    # @param [Array<GanttDataColumn>] columns
    # @return [Array<GanttDataHeaderCell>]
    def build_header_cells_quarters(top, height, columns)
      build_header_cells_parts(columns, top, height,
                               ->(date) { [date.year, date.quarter] },
                               ->(date, quarter_tuple) {
                                 date.year == quarter_tuple[0] && date.quarter == quarter_tuple[1]
                               },
                               ->(quarter_tuple) { "Q#{quarter_tuple[1]}" })
    end

    # Builds the month row header cells for the given columns
    # @param [Float] top
    # @param [Float] height
    # @param [Array<GanttDataColumn>] columns
    # @return [Array<GanttDataHeaderCell>]
    def build_header_cells_months(top, height, columns)
      build_header_cells_parts(columns, top, height,
                               ->(date) { [date.year, date.month] },
                               ->(date, month_tuple) { date.year == month_tuple[0] && date.month == month_tuple[1] },
                               ->(month_tuple) { Date.new(month_tuple[0], month_tuple[1], 1).strftime("%b") })
    end

    # Builds the day row header cells for the given columns
    # @param [Float] top
    # @param [Float] height
    # @param [Array<GanttDataColumn>] columns
    # @return [Array<GanttDataHeaderCell>]
    def build_header_cells_days(top, height, columns)
      columns.map { |column| build_header_cell(column.date.day.to_s, top, height, [column]) }
    end

    # Builds dependency lines between the work packages
    # @param [Array<GanttDataPageGroup>] page_groups
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

    # Builds a dependency line between the work packages
    # @param [WorkPackage] work_package
    # @param [WorkPackage] target_work_package
    # @param [Array<GanttDataPageGroup>] page_groups
    # @return [Array<Array<Float>>]
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

    # Builds the dependency line between two work packages on the same page
    # @param [GanttDataLineInfo] source
    # @param [GanttDataLineInfo] target
    def build_same_page_dep_lines(source, target)
      lines = if target.start_left - LINE_STEP <= source.finish_left
                build_same_page_dep_lines_backward(source, target)
              else
                build_same_page_dep_lines_forward(source, target)
              end
      source.start_row.page.add_lines lines
    end

    # Builds the dependency line between two work packages on the same page
    # where the source work package is after or a the same x as the target work package
    # @param [GanttDataLineInfo] source
    # @param [GanttDataLineInfo] target
    def build_same_page_dep_lines_backward(source, target)
      source_row_bottom = source.finish_row.bottom
      source_left = source.finish_left
      source_top = source.finish_top
      target_left = target.start_left
      target_top = target.start_top
      [
        [source_left, source_left + LINE_STEP, source_top, source_top],
        [source_left + LINE_STEP, source_left + LINE_STEP, source_top, source_row_bottom],
        [target_left - LINE_STEP, source_left + LINE_STEP, source_row_bottom, source_row_bottom],
        [target_left - LINE_STEP, target_left - LINE_STEP, source_row_bottom, target_top],
        [target_left - LINE_STEP, target_left, target_top, target_top]
      ]
    end

    # Builds the dependency line between two work packages on the same page
    # where the source work package is before the target work package
    def build_same_page_dep_lines_forward(source, target)
      source_left = source.finish_left
      source_top = source.finish_top
      target_left = target.start_left
      target_top = target.start_top
      [
        [source_left, target_left - LINE_STEP, source_top, source_top],
        [target_left - LINE_STEP, target_left - LINE_STEP, source_top, target_top],
        [target_left - LINE_STEP, target_left, target_top, target_top]
      ]
    end

    # Builds the dependency line between two work packages on different horizontal pages
    # @param [GanttDataLineInfo] source
    # @param [GanttDataLineInfo] target
    def build_multi_page_dep_line(source, target)
      i = source.page_group.pages.index(source.finish_row.page)
      j = source.page_group.pages.index(target.start_row.page)
      if i > j
        build_multi_page_dep_line_backward(source, target, i, j)
      else
        build_multi_page_dep_line_forward(source, target, i, j)
      end
    end

    # Builds the dependency line between two work packages on different horizontal pages
    # where the source work package page is after the target work package page
    # @param [GanttDataLineInfo] source
    # @param [GanttDataLineInfo] target
    # @param [Integer] start_page_index
    # @param [Integer] finish_page_index
    def build_multi_page_dep_line_backward(source, target, start_page_index, finish_page_index)
      y = source.finish_row.bottom
      build_multi_page_dep_line_backward_start(source, y)
      build_multi_page_dep_line_middle(source, finish_page_index, start_page_index, y)
      build_multi_page_dep_line_backward_end(target, y)
    end

    # Builds the dependency line between two work packages on different horizontal pages
    # draw line on the source work package page
    # @param [GanttDataLineInfo] source
    # @param [Float] top
    def build_multi_page_dep_line_backward_start(source, top)
      source.finish_row.page.add_lines(
        [
          [source.finish_left, source.finish_left + LINE_STEP, source.finish_top, source.finish_top],
          [source.finish_left + LINE_STEP, source.finish_left + LINE_STEP5, source.finish_top, top],
          [source.finish_row.left, source.finish_left + LINE_STEP, top, top]
        ]
      )
    end

    # Builds the dependency line between two work packages on different horizontal pages
    # draw line on all pages between the source work package page and the target work package page
    # @param [GanttDataLineInfo] source
    # @param [Integer] start_page_index
    # @param [Integer] finish_page_index
    # @param [Float] top
    def build_multi_page_dep_line_middle(source, start_page_index, finish_page_index, top)
      ((start_page_index + 1)..(finish_page_index - 1)).each do |index|
        page = source.page_group.pages[index]
        page.add_line(page.columns.first.left, page.columns.last.right, top, top)
      end
    end

    # Builds the dependency line between two work packages on different horizontal pages
    # draw line to the the target work package page
    # @param [GanttDataLineInfo] target
    # @param [Float] top
    def build_multi_page_dep_line_backward_end(target, top)
      left = target.start_left - LINE_STEP
      target.start_row.page.add_lines(
        [
          [left, target.start_row.page.columns.last.right, top, top],
          [left, left, top, target.start_top],
          [left, target.start_left, target.start_top, target.start_top]
        ]
      )
    end

    # Builds the dependency line between two work packages on different horizontal pages
    # where the source work package page is before the target work package page
    # @param [GanttDataLineInfo] source
    # @param [GanttDataLineInfo] target
    # @param [Integer] start_page_index
    # @param [Integer] finish_page_index
    def build_multi_page_dep_line_forward(source, target, start_page_index, finish_page_index)
      build_multi_page_dep_line_forward_start(source)
      build_multi_page_dep_line_middle(source, start_page_index, finish_page_index, source.finish_top)
      build_multi_page_dep_line_forward_end(source, target)
    end

    # Builds the dependency line between two work packages on different horizontal pages
    # draw line on the source work package page
    # @param [GanttDataLineInfo] source
    def build_multi_page_dep_line_forward_start(source)
      source.finish_row.page.add_line(source.finish_left, source.finish_row.page.columns.last.right,
                                      source.finish_top, source.finish_top)
    end

    # Builds the dependency line between two work packages on different horizontal pages
    # draw line on the target work package page
    # @param [GanttDataLineInfo] source
    # @param [GanttDataLineInfo] target
    def build_multi_page_dep_line_forward_end(source, target)
      source_left = target.start_row.page.columns.first.left - 10
      source_top = source.finish_top
      target_left = target.start_left
      target_top = target.start_top
      target.start_row.page.add_lines(
        [
          [source_left, target_left - LINE_STEP, source_top, source_top],
          [target_left - LINE_STEP, target_left - LINE_STEP, source_top, target_top],
          [target_left - LINE_STEP, target_left, target_top, target_top]
        ]
      )
    end

    # Builds the dependency line between two work packages on different horizontal and vertical pages
    # @param [GanttDataLineInfo] source
    # @param [GanttDataLineInfo] target
    # @param [Array<GanttDataPageGroup>] page_groups
    def build_multi_group_page_dep_line(source, target, page_groups) end

    # Builds the text column data object if the page is first page of horizontal page group
    # @param [Integer] page_index
    def build_text_column(page_index)
      if page_index == 0
        GanttDataTextColumn.new(@title, 0, @text_column_width, 0, GANTT_ROW_HEIGHT,
                                TEXT_CELL_PADDING * 2, TEXT_CELL_PADDING)
      end
    end

    # Builds the gantt rows for the given columns and work packages
    # @param [Array<GanttDataColumn>] columns
    # @param [Array<WorkPackage>] work_packages
    def build_rows(columns, work_packages)
      work_packages.each_with_index.map { |work_package, row_index| build_row(work_package, row_index, columns) }
    end

    # Builds the gantt row for the given work package and columns
    # @param [WorkPackage] work_package
    # @param [Integer] row_index
    # @param [Array<GanttDataColumn>] columns
    # @return [GanttDataRow]
    def build_row(work_package, row_index, columns)
      paint_columns = columns.filter { |column| column.work_packages.include?(work_package) }
      top = @header_row_height + (row_index * GANTT_ROW_HEIGHT)
      shape = build_shape(top, paint_columns, work_package) unless paint_columns.empty?
      GanttDataRow.new(row_index, work_package, shape, 0, top, GANTT_ROW_HEIGHT)
    end

    # Builds the shape for the given work package
    # @param [Float] top
    # @param [Array<GanttDataColumn>] paint_columns
    # @param [WorkPackage] work_package
    # @return [GanttDataShape]
    def build_shape(top, paint_columns, work_package)
      if work_package.milestone?
        build_shape_milestone(top, paint_columns, work_package)
      else
        build_shape_bar(top, paint_columns, work_package)
      end
    end

    # Builds the bar shape for the given work package
    # @param [Float] top
    # @param [Array<GanttDataColumn>] paint_columns
    # @param [WorkPackage] work_package
    # @return [GanttDataShape]
    def build_shape_bar(top, paint_columns, work_package)
      left = paint_columns.first.left
      x1, x2, y1, y2 = bar_layout(paint_columns, work_package)
      GanttDataShape.new(:bar, left + x1, [x2 - x1, 0.1].max, top + y1, y2 - y1,
                         work_package, paint_columns, wp_type_color(work_package))
    end

    # Returns bounds for the bar shape
    # @param [Array<GanttDataColumn>] paint_columns
    # @param [WorkPackage] work_package
    # @return [Array<Float>] x1, x2, y1, y2
    def bar_layout(paint_columns, work_package)
      x1 = calc_start_offset(work_package, paint_columns.first.date)
      x2 = paint_columns.last.right - paint_columns.first.left -
        calc_end_offset(work_package, paint_columns.last.date)
      [x1, x2, BAR_CELL_PADDING, GANTT_ROW_HEIGHT - BAR_CELL_PADDING]
    end

    # Builds the milestone shape for the given work package
    # @param [Float] top
    # @param [Array<GanttDataColumn>] paint_columns
    # @param [WorkPackage] work_package
    # @return [GanttDataShape]
    def build_shape_milestone(top, paint_columns, work_package)
      left = paint_columns.first.left
      x1, y1, diamond_size = milestone_layout(top, paint_columns, work_package)
      GanttDataShape.new(:milestone, left + x1, diamond_size, y1, diamond_size,
                         work_package, paint_columns, wp_type_color(work_package))
    end

    # Returns bounds for the milestone shape
    # @param [Float] top
    # @param [Array<GanttDataColumn>] paint_columns
    # @param [WorkPackage] work_package
    # @return [Array<Float>] x1, y1, diamond_size
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

    # Returns the start and finish rows of the given work package rows group (rows with shapes)
    # @param [Array<GanttDataRow>] rows
    def collect_start_and_finish_rows(rows)
      draw_rows = rows.reject { |row| row.shape.nil? }
      start = draw_rows.max_by { |row| row.page.index }
      finish = draw_rows.max_by { |row| row.page.index }
      [start, finish]
    end

    # Returns a helper object containing information about the line to be drawn
    # @param [WorkPackage] work_package
    # @param [Array<GanttDataPageGroup>] page_groups
    def collect_line_infos(work_package, page_groups)
      rows = collect_rows_by_work_package(work_package, page_groups)
      start, finish = collect_start_and_finish_rows(rows)
      GanttDataLineInfo.new(rows[0].page.group, rows, start, finish)
    end

    # Builds the dates range for the given work packages
    # @param [Array<WorkPackage>] work_packages
    # @return [Array<Date>]
    def collect_column_dates(work_packages)
      wp_dates = collect_work_packages_dates(work_packages)
      build_column_dates_range(wp_dates.first..wp_dates.last)
    end

    # Collects the unique dates of the given work packages (start and/or due date)
    # @param [Array<WorkPackage>] work_packages
    # @return [Array<Date>]
    def collect_work_packages_dates(work_packages)
      work_packages.map do |work_package|
        [work_package.start_date || work_package.due_date, work_package.due_date || Time.zone.today]
      end.flatten.uniq.sort
    end

    # Collects all rows for the given work package
    # @param [WorkPackage] work_package
    # @param [Array<GanttDataPageGroup>] page_groups
    # @return [Array<GanttDataRow>]
    def collect_rows_by_work_package(work_package, page_groups)
      page_groups.map do |page_group|
        page_group.pages.map do |page|
          page.rows.find { |r| r.work_package == work_package }
        end
      end.flatten.compact
    end

    # Get the shape color by work package type
    # @param [WorkPackage] work_package
    # @return [String] hexcode_in_prawn_format
    def wp_type_color(work_package)
      work_package.type.color.hexcode.sub("#", "")
    end

    # translates the work package dates to column dates
    # will be overwritten by subclasses
    # @param [Array<Date>] _range
    # @return [Array<Date>]
    def build_column_dates_range(_range)
      [] # to be overwritten
    end

    # defines which header row to be shown (years, quarters, months, days)
    # will be overwritten by subclasses
    def header_row_parts
      [] # to be overwritten
    end

    # for a column, get all work packages that are active on that date
    # will be overwritten by subclasses
    # @param [Date] _date
    # @param [Array<WorkPackage>] _work_packages
    # @return [Array<WorkPackage>]
    def work_packages_on_date(_date, _work_packages)
      [] # to be overwritten
    end

    # milestones are centered in the cell only for day view
    # will be overwritten by subclasses
    def milestone_position_centered?
      false # to be overwritten
    end

    # Calculates the start offset of the work package in date column
    # will be overwritten by subclasses
    # @param [WorkPackage] _work_package
    # @param [Date] _date
    # @return [Float]
    def calc_start_offset(_work_package, _date)
      0 # to be overwritten
    end

    # Calculates the end offset of the work package in date column
    # will be overwritten by subclasses
    # @param [WorkPackage] _work_package
    # @param [Date] _date
    # @return [Float]
    def calc_end_offset(_work_package, _date)
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
      (1..3).sum { |q| Date.new(date.year, (date.quarter * 3) - 3 + q, -1).day }
    end

    def wp_on_quarter?(work_package, date)
      start_date = work_package.start_date || work_package.due_date
      end_date = work_package.due_date || Time.zone.today
      Range.new(start_date.beginning_of_quarter, end_date.end_of_quarter).include?(date)
    end
  end


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
      unless row.page.text_column.nil?
        paint_work_package_title(row, row.left, row.top, row.page.text_column.width, row.page.text_column.height)
      end
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
      paint_text_box(page.text_column.title, 0, 0, page.text_column.width, page.header_row_height,
                     page.text_column.padding_h, 0, { size: 10, style: :bold })
    end

    def paint_header_column_cell(cell)
      paint_text_box(cell.text, cell.left, cell.top, cell.width, cell.height,
                     0, 0,
                     { size: 10, style: :bold, align: :center })
    end

    def paint_work_package_title(row, left, top, width, height)
      paint_text_box("#{row.work_package.type} ##{row.work_package.id} - #{row.work_package.subject}",
                     left, top, width, height,
                     row.page.text_column.padding_h, row.page.text_column.padding_v)
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


  class GanttDataPageGroup
    attr_accessor :index, :pages

    def initialize(index, work_packages, pages)
      @index = index
      @pages = pages
      @work_packages = work_packages
      @pages.each { |page| page.group = self }
    end
  end

  class GanttDataPage
    attr_accessor :index, :rows, :columns, :lines, :text_column, :width, :height, :header_cells, :header_row_height, :group

    def initialize(index, work_packages, header_cells, rows, columns, text_column, width, height, header_row_height)
      @index = index
      @rows = rows
      @columns = columns
      @work_packages = work_packages
      @text_column = text_column
      @width = width
      @height = height
      @header_cells = header_cells
      @header_row_height = header_row_height
      @lines = []
      @group = nil
      rows.each { |row| row.page = self }
      columns.each { |column| column.page = self }
    end

    def add_line(left, right, top, bottom)
      @lines.push({ left:, right:, top:, bottom: })
    end

    def add_lines(lines)
      lines.each { |line| add_line(line[0], line[1], line[2], line[3]) }
    end
  end

  class GanttDataRow
    attr_accessor :index, :page, :work_package, :shape, :top, :left, :height, :bottom

    def initialize(index, work_package, shape, left, top, height)
      @index = index
      @work_package = work_package
      @shape = shape
      @top = top
      @left = left
      @height = height
      @bottom = top + height
      @page = nil
    end
  end

  class GanttDataColumn
    attr_accessor :date, :left, :right, :width, :work_packages, :page

    def initialize(date, left, width, work_packages)
      @date = date
      @left = left
      @right = left + width
      @width = width
      @work_packages = work_packages
      @page = nil
    end
  end

  class GanttDataLineInfo
    attr_accessor :page_group, :rows, :start_row, :start_left, :start_top, :finish_row, :finish_left, :finish_top

    def initialize(page_group, rows, start_row, finish_row)
      @page_group = page_group
      @rows = rows
      @start_row = start_row
      @finish_row = finish_row
      init_positions
    end

    def init_positions
      @start_left = @start_row.shape.left
      @start_top = @start_row.shape.top + (@start_row.shape.height / 2)
      @finish_left = @finish_row.shape.right
      @finish_top = @finish_row.shape.top + (@finish_row.shape.height / 2)
    end
  end

  class GanttDataHeaderCell
    attr_accessor :text, :left, :right, :top, :bottom, :height, :width

    def initialize(text, left, right, top, bottom)
      @text = text
      @left = left
      @right = right
      @top = top
      @bottom = bottom
      @height = bottom - top
      @width = right - left
    end
  end

  class GanttDataTextColumn
    attr_accessor :title, :width, :left, :right, :top, :height, :bottom, :padding_h, :padding_v

    def initialize(title, left, width, top, height, padding_h, padding_v)
      @title = title
      @width = width
      @left = left
      @right = left + width
      @padding_h = padding_h
      @padding_v = padding_v
      @top = top
      @height = height
      @bottom = top + height
    end
  end

  class GanttDataShape
    attr_accessor :type, :left, :right, :top, :bottom, :width, :height, :work_package, :columns, :color

    def initialize(type, left, width, top, height, work_package, columns, color)
      @type = type
      @left = left
      @right = left + width
      @top = top
      @bottom = top + height
      @width = width
      @height = height
      @work_package = work_package
      @columns = columns
      @color = color
    end
  end

  class GantDataLineFragment
    attr_accessor :left, :right, :top, :bottom

    def initialize(left, right, top, bottom)
      @left = left
      @right = right
      @top = top
      @bottom = bottom
    end
  end
end

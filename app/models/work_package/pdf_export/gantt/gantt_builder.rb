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
  class GanttBuilder
    include Redmine::I18n
    BAR_CELL_PADDING = 5.to_f
    TEXT_CELL_PADDING_H = 3.to_f
    TEXT_CELL_PADDING_V = 1.to_f
    GANTT_ROW_HEIGHT = 20.to_f
    DEFAULT_HEADER_ROW_HEIGHT = 30.to_f
    DEFAULT_TEXT_COLUMN_DIVIDER = 4
    TEXT_COLUMN_MAX_WIDTH = 250.to_f
    LINE_STEP = 5.to_f

    def initialize(pdf, title, column_width)
      @pdf = pdf
      @title = title
      @column_width = column_width
      @draw_gantt_lines = true
      init_defaults
    end

    def build(work_packages, id_wp_meta_map, query)
      @all_work_packages = work_packages
      @id_wp_meta_map = id_wp_meta_map
      @query = query
      dates = collect_column_dates(work_packages)
      entries = build_gantt_entries(work_packages)
      adjust_to_pages
      page_groups = build_page_groups(entries, dates)
      build_dep_lines(page_groups) if @draw_gantt_lines
      page_groups.flat_map(&:pages)
    end

    private

    # Builds the page groups
    # @param [Array<WorkPackage>] entries
    # @param [Array<Date>] dates
    # @return [Array<GanttDataPageGroup>]
    def build_page_groups(entries, dates)
      page_groups = build_pages(entries, dates)
      if page_groups[0].pages.length == 1
        # if there are not enough columns for even the first page of horizontal pages => distribute space to all columns
        distribute_to_first_page(page_groups[0].pages.first.columns.length)
        page_groups = build_pages(entries, dates)
      end
      page_groups
    end

    # Create list of row entries for the gantt chart, including group placeholders
    # @param [Array<WorkPackage>] work_packages
    # @return [Array<GanttDataEntry>]
    def build_gantt_entries(work_packages)
      entries = work_packages.map { |work_package| GanttDataEntry.new(work_package.id, work_package.subject, work_package) }
      entries = insert_work_package_group_placeholders(entries) if @query.grouped?
      entries
    end

    # Initializes the default values
    def init_defaults
      @header_row_height = DEFAULT_HEADER_ROW_HEIGHT.to_f
      @text_column_width = [@pdf.bounds.width / DEFAULT_TEXT_COLUMN_DIVIDER, TEXT_COLUMN_MAX_WIDTH].min
      @nr_columns = (@pdf.bounds.width / @column_width).floor
    end

    # distribute empty spaces
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

    # if the query is grouped, insert placeholders "rows" for the group headers
    # @param [Array<GanttDataEntry>] entries
    # @return [Array<GanttDataEntry>]
    def insert_work_package_group_placeholders(entries)
      last_group = nil
      result = []
      entries.each do |entry|
        wp_group = @query.group_by_column.value(entry.work_package)
        if last_group != wp_group
          last_group = wp_group
          result << GanttDataEntry.new("group_#{wp_group}", wp_group.to_s, nil)
        end
        result << entry
      end
      result
    end

    # Builds all page groups for the given work packages
    # @param [Array<GanttDataEntry>] entries
    # @return [Array<GanttDataPageGroup>]
    def build_pages(entries, dates)
      vertical_pages_needed = (entries.size / @rows_per_page.to_f).ceil
      horizontal_pages_needed = [((dates.size - @nr_columns_first_page) / @nr_columns.to_f).ceil, 0].max + 1
      build_vertical_pages(entries, dates, vertical_pages_needed, horizontal_pages_needed)
    end

    # Builds all page groups for the given work packages and dates
    # @param [Array<GanttDataEntry>] entries
    # @param [Array<Date>] dates
    # @param [Integer] vertical_pages_needed
    # @param [Integer] horizontal_pages_needed
    # @return [Array<GanttDataPageGroup>]
    def build_vertical_pages(entries, dates, vertical_pages_needed, horizontal_pages_needed)
      (0..vertical_pages_needed - 1).map do |v_index|
        group_entries = entries.slice(v_index * @rows_per_page, @rows_per_page)
        GanttDataPageGroup.new(v_index, group_entries.map(&:id),
                               build_horizontal_pages(group_entries, dates, horizontal_pages_needed))
      end
    end

    # Builds pages for the given work packages and dates
    # @param [Array<GanttDataEntry>] entries
    # @param [Array<Date>] dates
    # @param [Integer] horizontal_pages_needed
    # @return [Array<GanttDataPage>]
    def build_horizontal_pages(entries, dates, horizontal_pages_needed)
      result = [build_page(dates.slice(0, @nr_columns_first_page), 0, entries)]
      (0..horizontal_pages_needed - 2).each do |index|
        result << build_page(
          dates.slice(@nr_columns_first_page + (index * @nr_columns), @nr_columns),
          index + 1, entries
        )
      end
      result
    end

    # Builds a page for the given dates and work packages
    # @param [Array<Date>] dates
    # @param [Integer] page_index
    # @param [Array<GanttDataEntry>] entries
    # @return [GanttDataPage]
    def build_page(dates, page_index, entries)
      left = (page_index == 0 ? @text_column_width : 0)
      columns = build_columns(left, dates, entries)
      GanttDataPage.new(
        page_index,
        entries.map(&:id),
        build_header_cells(columns),
        build_rows(columns, entries, page_index == 0),
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
    # @param [Array<GanttDataEntry>] entries
    # @return [Array<GanttDataColumn>]
    def build_columns(left, dates, entries)
      dates.each_with_index.map { |date, col_index| build_column(date, left + (col_index * @column_width), entries) }
    end

    # Builds the gantt column for the given date
    # @param [Date] date
    # @param [Float] left
    # @param [Array<GanttDataEntry>] entries
    # @return [GanttDataColumn]
    def build_column(date, left, entries)
      work_packages = entries.reject(&:group?).map(&:work_package)
      GanttDataColumn.new(date, left, @column_width, work_packages_on_date(date, work_packages).map(&:id))
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
        when :weeks
          build_header_cells_weeks(top, height, columns)
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

    def build_header_cells_weeks(top, height, columns)
      build_header_cells_parts(columns, top, height,
                               ->(date) { [date.year, date.cweek] },
                               ->(date, week_tuple) { date.year == week_tuple[0] && date.cweek == week_tuple[1] },
                               ->(week_tuple) { "W#{week_tuple[1]}" })
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
        build_multi_group_dep_line(line_source, line_target, page_groups)
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
      start_page_index = source.page_group.pages.index(source.finish_row.page)
      finish_page_index = source.page_group.pages.index(target.start_row.page)
      if start_page_index > finish_page_index
        build_multi_page_dep_line_backward(source, target, start_page_index, finish_page_index)
      else
        build_multi_page_dep_line_forward(source, target, start_page_index, finish_page_index)
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
          [source.finish_left + LINE_STEP, source.finish_left + LINE_STEP, source.finish_top, top],
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
    # and the source work package page is before the target work package page
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
      source_left = target.start_row.page.columns.first.left - LINE_STEP
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

    # Builds the dependency line between two work packages on different vertical (and maybe horizontal) pages
    # @param [GanttDataLineInfo] source
    # @param [GanttDataLineInfo] target
    # @param [Array<GanttDataPageGroup>] page_groups
    def build_multi_group_dep_line(source, target, page_groups)
      start_page_index = source.page_group.pages.index(source.finish_row.page)
      finish_page_index = target.page_group.pages.index(target.start_row.page)
      if start_page_index == finish_page_index
        build_multi_group_same_page_dep_line(source, target, start_page_index, page_groups)
      elsif start_page_index > finish_page_index
        build_multi_group_dep_line_backward(source, target, start_page_index, finish_page_index, page_groups)
      else
        build_multi_group_dep_line_forward(source, target, start_page_index, finish_page_index, page_groups)
      end
    end

    # Builds the dependency line between two work packages on different vertical but not horizontal pages
    # @param [GanttDataLineInfo] source
    # @param [GanttDataLineInfo] target
    # @param [Integer] page_index
    # @param [Array<GanttDataPageGroup>] page_groups
    def build_multi_group_same_page_dep_line(source, target, page_index, page_groups)
      build_multi_group_same_page_dep_lines_forward_start(source, target)
      build_multi_group_dep_line_middle(source, target, page_index, page_groups)
      build_multi_group_dep_line_group_end_end(target, target.start_left - LINE_STEP)
    end

    # Builds the dependency line between two work packages on different vertical but not horizontal pages (start)
    # @param [GanttDataLineInfo] source
    # @param [GanttDataLineInfo] target
    def build_multi_group_same_page_dep_lines_forward_start(source, target)
      source_top = source.finish_top
      target_left = target.start_left - LINE_STEP
      source.finish_row.page.add_lines([
                                         [source.finish_left, target_left, source_top, source_top],
                                         [target_left, target_left, source_top, source.finish_row.page.height]
                                       ])
    end

    # Builds the dependency line between two work packages on different horizontal and vertical pages
    # and the source work package page is before the target work package page
    # @param [GanttDataLineInfo] source
    # @param [GanttDataLineInfo] target
    # @param [Integer] start_page_index
    # @param [Integer] finish_page_index
    # @param [Array<GanttDataPageGroup>] page_groups
    def build_multi_group_dep_line_forward(source, target,
                                           start_page_index, finish_page_index, page_groups)
      build_multi_page_dep_line_forward_start(source)
      build_multi_page_dep_line_middle(source, start_page_index, finish_page_index, source.finish_top)
      build_multi_group_dep_line_group_end(source, target, finish_page_index, page_groups)
    end

    # Builds the dependency line between two work packages on different horizontal and vertical pages
    # and the source work package page is after the target work package page
    # @param [GanttDataLineInfo] source
    # @param [GanttDataLineInfo] target
    # @param [Integer] start_page_index
    # @param [Integer] finish_page_index
    # @param [Array<GanttDataPageGroup>] page_groups
    def build_multi_group_dep_line_backward(source, target,
                                            start_page_index, finish_page_index, page_groups)
      build_multi_page_dep_line_backward_start(source, source.finish_row.bottom)
      build_multi_page_dep_line_middle(source, start_page_index, finish_page_index, source.finish_top)
      build_multi_group_dep_line_group_end(source, target, finish_page_index, page_groups)
    end

    # Builds the dependency line between two work packages on different vertical pages
    # draw line on the target work package page
    # @param [GanttDataLineInfo] source
    # @param [GanttDataLineInfo] target
    def build_multi_group_dep_line_group_end(source, target, finish_page_index, page_groups)
      target_left = target.start_left - LINE_STEP
      build_multi_group_dep_line_group_end_start(source, target_left, finish_page_index)
      build_multi_group_dep_line_middle(source, target, finish_page_index, page_groups)
      build_multi_group_dep_line_group_end_end(target, target_left)
    end

    # Builds the dependency line between two work packages on different vertical pages
    # draw line on the source work package page position
    # @param [GanttDataLineInfo] source
    # @param [Float] target_left
    # @param [Integer] finish_page_index
    def build_multi_group_dep_line_group_end_start(source, target_left, finish_page_index)
      page = source.finish_row.page.group.pages[finish_page_index]
      page.add_lines(
        [
          [0, target_left, source.finish_top, source.finish_top],
          [target_left, target_left, source.finish_top, page.height]
        ]
      )
    end

    # Builds the dependency line between two work packages on different vertical pages
    # draw line on the target work package page position
    # @param [GanttDataLineInfo] target
    # @param [Float] target_left
    def build_multi_group_dep_line_group_end_end(target, target_left)
      target.start_row.page.add_lines(
        [
          [target_left, target_left, target.finish_row.page.header_row_height, target.finish_top],
          [target_left, target.start_left, target.finish_top, target.finish_top]
        ]
      )
    end

    # Builds the dependency line between two work packages on different vertical pages
    # draw line between the source and target work package pages
    # @param [GanttDataLineInfo] source
    # @param [GanttDataLineInfo] target
    def build_multi_group_dep_line_middle(source, target, page_index, page_groups)
      start_group_index = page_groups.index(source.finish_row.page.group)
      finish_group_index = page_groups.index(target.start_row.page.group)
      start = [start_group_index, finish_group_index].min
      finish = [start_group_index, finish_group_index].max
      ((start + 1)..(finish - 1)).each do |index|
        build_multi_group_dep_line_middle_for_group(page_groups[index], target, page_index)
      end
    end

    # Builds the dependency line between two work packages on different vertical pages
    # draw line on groups between the source and target work package page groups
    # @param [GanttDataPageGroup] group
    # @param [GanttDataLineInfo] target
    # @param [Integer] finish_page_index
    def build_multi_group_dep_line_middle_for_group(group, target, finish_page_index)
      page = group.pages[finish_page_index]
      page.add_line(target.start_left - LINE_STEP, target.start_left - LINE_STEP, page.header_row_height, page.height)
    end

    # Builds the text column data object if the page is first page of horizontal page group
    # @param [Integer] page_index
    def build_text_column(page_index)
      if page_index == 0
        GanttDataTextColumn.new(@title, 0, @text_column_width, 0, GANTT_ROW_HEIGHT,
                                TEXT_CELL_PADDING_H, TEXT_CELL_PADDING_V)
      end
    end

    # Builds the gantt rows for the given columns and work packages
    # @param [Array<GanttDataColumn>] columns
    # @param [Array<GantDataEntry>] entries
    # @param [Boolean] with_text_column
    # @return [Array<GanttDataRow>]
    def build_rows(columns, entries, with_text_column)
      entries.each_with_index.map do |entry, row_index|
        build_row(entry, row_index, columns, with_text_column)
      end
    end

    # Builds the gantt row for the given work package and columns
    # @param [GanttDataEntry] entry
    # @param [Integer] row_index
    # @param [Array<GanttDataColumn>] columns
    # @return [GanttDataRow]
    def build_row(entry, row_index, columns, with_text_column)
      paint_columns = columns.filter { |column| column.entry_ids.include?(entry.id) }
      top = @header_row_height + (row_index * GANTT_ROW_HEIGHT)
      shape = build_shape(top, paint_columns, entry.work_package) unless entry.group? || paint_columns.empty?
      text_lines = with_text_column ? build_row_text_lines(entry, top) : []
      GanttDataRow.new(row_index, entry.id, shape, text_lines, 0, top, GANTT_ROW_HEIGHT)
    end

    # Builds the text lines for the given work package
    # @param [GanttDataEntry] entry
    # @param [Float] top
    # @return [Array<GanttDataText>]
    def build_row_text_lines(entry, top)
      left = TEXT_CELL_PADDING_H
      right = left + @text_column_width - (TEXT_CELL_PADDING_H * 2)
      return build_row_text_lines_group_row(entry, left, right, top) if entry.group?

      [build_row_text_lines_wp_info(entry, left, right, top),
       build_row_text_lines_wp_title(entry, left, right, top)]
    end

    # Builds the title line for the given work package entry
    # @param [GanttDataEntry] entry
    # @param [Float] left
    # @param [Float] right
    # @param [Float] top
    # @return [GanttDataText]
    def build_row_text_lines_wp_title(entry, left, right, top)
      text_top = top + TEXT_CELL_PADDING_V + 4
      text_bottom = text_top + 16
      GanttDataText.new(entry.work_package.subject, left, right, text_top, text_bottom, 8)
    end

    # Builds the group row text lines for the given group entry
    # @param [GanttDataEntry] entry
    # @param [Float] left
    # @param [Float] right
    # @param [Float] top
    # @return [Array<GanttDataText>]
    def build_row_text_lines_group_row(entry, left, right, top)
      text_top = top + TEXT_CELL_PADDING_V
      text_bottom = text_top + GANTT_ROW_HEIGHT - (TEXT_CELL_PADDING_V * 2)
      [GanttDataText.new(entry.subject, left, right, text_top, text_bottom, 8)]
    end

    # Builds the title line for the given work package entry
    # @param [GanttDataEntry] entry
    # @param [Float] left
    # @param [Float] right
    # @param [Float] top
    # @return [GanttDataText]
    def build_row_text_lines_wp_info(entry, left, right, top)
      text_top = top + TEXT_CELL_PADDING_V
      text_bottom = text_top + 8
      GanttDataText.new(work_package_info_line(entry.work_package), left, right, text_top, text_bottom, 6)
    end

    # Returns the info text line for the given work package
    # @param [WorkPackage] work_package
    # @return [String]
    def work_package_info_line(work_package)
      "#{work_package.type} ##{work_package.id} • #{work_package.status} • #{work_package_info_line_date work_package}"
    end

    def work_package_info_line_date(work_package)
      if work_package.start_date == work_package.due_date
        format_pdf_date(work_package, :start_date)
      else
        "#{format_pdf_date(work_package, :start_date)} - #{format_pdf_date(work_package, :due_date)}"
      end
    end

    def format_pdf_date(work_package, date_field)
      date = work_package.send(date_field)
      date.nil? ? I18n.t("label_no_#{date_field}") : format_date(date)
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
                         work_package.id, paint_columns, wp_type_color(work_package))
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
                         work_package.id, paint_columns, wp_type_color(work_package))
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
        [work_package.start_date || work_package.due_date, work_package.due_date || work_package.start_date]
      end.flatten.uniq.sort
    end

    # Collects all rows for the given work package
    # @param [WorkPackage] work_package
    # @param [Array<GanttDataPageGroup>] page_groups
    # @return [Array<GanttDataRow>]
    def collect_rows_by_work_package(work_package, page_groups)
      page_groups.map do |page_group|
        page_group.pages.map do |page|
          page.rows.find { |r| r.entry_id == work_package.id }
        end
      end.flatten.compact
    end

    # Get the shape color by work package type
    # @param [WorkPackage] work_package
    # @return [String] hexcode_in_prawn_format
    def wp_type_color(work_package)
      work_package.type&.color&.hexcode&.sub("#", "") || "000000"
    end

    # get the dates of the work package with safety checks
    def wp_dates(work_package)
      start_date = work_package.start_date || work_package.due_date
      end_date = work_package.due_date || work_package.start_date || Time.zone.today
      [start_date, end_date].minmax
    end

    # translates the work package dates to column dates
    # will be overwritten by subclasses
    # @param [Range<Date>] _range
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
      0.0 # to be overwritten
    end

    # Calculates the end offset of the work package in date column
    # will be overwritten by subclasses
    # @param [WorkPackage] _work_package
    # @param [Date] _date
    # @return [Float]
    def calc_end_offset(_work_package, _date)
      0.0 # to be overwritten
    end
  end
end

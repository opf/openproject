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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class CostQuery::PDF::TimesheetGenerator
  include Exports::PDF::Common::Common
  include Exports::PDF::Common::Attachments
  include Exports::PDF::Common::Logo
  include Exports::PDF::Components::Cover
  include Exports::PDF::Components::Page
  include CostQuery::PDF::Styles
  include ReportingHelper

  H1_FONT_SIZE = 26
  H1_MARGIN_BOTTOM = 2
  HR_MARGIN_BOTTOM = 16
  PARAGRAPH_MARGIN_BOTTOM = 8
  TABLE_MARGIN_BOTTOM = 28
  TABLE_CELL_FONT_SIZE = 10
  TABLE_CELL_BORDER_COLOR = "BBBBBB"
  TABLE_CELL_PADDING = 4
  TABLE_CELL_PADDING_RIGHT = 8
  TABLE_CELL_PADDING_BOTTOM = 6
  COMMENT_FONT_COLOR = "636C76"
  H2_FONT_SIZE = 20
  H2_MARGIN_BOTTOM = 10
  SUM_TABLE_FIRST_COLUMN_WIDTH = 90
  SUM_TABLE_MAX_USER_COLUMNS = 6
  OVERVIEW_HEADER_FONT_SIZE = 16

  COLUMN_DATE_WIDTH = 90
  COLUMN_ACTIVITY_WIDTH = 100
  COLUMN_HOURS_WIDTH = 60
  COLUMN_TIME_WIDTH = 108
  COLUMN_WP_WIDTH = 166

  attr_accessor :pdf

  def initialize(query, project)
    @query = query
    @project = project
    @total_page_nr = nil
    @page_count = 1
    setup_page!
  end

  def heading
    query.name || I18n.t(:"export.timesheet.timesheet")
  end

  def footer_title
    heading
  end

  def cover_page_title
    @cover_page_title ||= Setting.app_title
  end

  def cover_page_heading
    heading
  end

  def cover_page_dates
    start_date, end_date = all_entries.map(&:spent_on).minmax
    "#{format_date(start_date)} - #{format_date(end_date)}" if start_date && end_date
  end

  def cover_page_subheading
    User.current&.name
  end

  def project
    @project
  end

  def query
    @query
  end

  def options
    {}
  end

  def setup_page!
    self.pdf = get_pdf
    configure_page_size!(:portrait)
    pdf.title = heading
  end

  def generate!
    render_doc
    render_doc_again_with_total_page_nrs! if wants_total_page_nrs?
    pdf.render
  rescue StandardError => e
    error(e)
  end

  def render_doc
    write_cover_page! if with_cover?
    write_overview!
    write_heading!
    write_hr!
    write_entries!
    write_headers!
    write_footers!
  end

  def render_doc_again_with_total_page_nrs!
    @total_page_nr = pdf.page_count + @page_count
    @page_count = 1
    setup_page! # clear current pdf
    render_doc
  end

  def write_entries!
    grouped_by_user_entries.each do |user, result|
      write_table(user, result)
    end
  end

  def grouped_by_user_entries
    all_entries
      .group_by(&:user)
      .sort_by { |user, _entries| user.name }
  end

  def all_users
    all_entries
      .uniq { |entry| entry.user.id }
      .map(&:user)
      .sort_by(&:name)
  end

  def all_entries
    @all_entries ||= begin
      ids = query
              .each_direct_result
              .filter { |r| r.fields["type"] == "TimeEntry" }
              .flat_map { |r| r.fields["id"] }

      TimeEntry.where(id: ids).includes(%i[user activity project])
    end
  end

  def build_table_rows(entries, wants_sum_row)
    rows = [table_header_columns]
    entries
      .group_by(&:spent_on)
      .sort
      .each do |spent_on, lines|
      rows.concat(build_table_day_rows(spent_on, lines))
    end
    rows.push(build_table_row_sum(entries)) if wants_sum_row
    rows
  end

  def build_table_day_rows(spent_on, entries)
    day_rows = []
    entries.each do |entry|
      day_rows.push(build_table_row(spent_on, entry))
      day_rows.push(build_table_row_comment(entry)) if entry.comments.present?
    end
    day_rows.push(build_table_row_day_sum(spent_on, entries)) if entries.length > 1
    day_rows
  end

  def build_table_row(spent_on, entry)
    [
      {
        content: format_date_with_weekday(spent_on),
        rowspan: (entry.comments.present? ? 2 : 1),
        cell_id: spent_on_day_id(entry.user, spent_on)
      },
      build_table_subject_cell(entry),
      with_times_column? ? format_spent_on_time(entry) : nil,
      { content: format_hours(entry.hours || 0), align: :right },
      entry.activity&.name || ""
    ].compact
  end

  def build_table_row_day_sum(spent_on, entries)
    [
      { content: format_date_with_weekday(spent_on), rowspan: 1 },
      "",
      with_times_column? ? "" : nil,
      { content: format_sum_time_entries(entries), font_style: :bold, align: :right },
      ""
    ].compact
  end

  def spent_on_day_id(user, spent_on)
    "entry_#{user.id}_#{spent_on}"
  end

  def build_table_subject_cell(entry)
    return "" if entry.entity.nil?
    return "" unless entry.entity.is_a?(WorkPackage)

    href = url_helpers.work_package_url(entry.entity)
    {
      content: "#{make_link_href(href, entry.entity.formatted_id)} #{entry.entity.subject || ''}",
      inline_format: true
    }
  end

  def build_table_row_sum(entries)
    [
      { content: "", rowspan: 1 },
      "",
      with_times_column? ? "" : nil,
      { content: format_sum_time_entries(entries), font_style: :bold, align: :right },
      ""
    ].compact
  end

  def format_sum_time_entries(entries)
    format_hours(sum_time_entries(entries))
  end

  def sum_time_entries(entries)
    entries.filter_map(&:hours).sum
  end

  def build_table_row_comment(entry)
    [{
      content: entry.comments,
      text_color: COMMENT_FONT_COLOR,
      font_style: :italic,
      colspan: table_columns_widths.size
    }]
  end

  def table_header_columns
    [
      { content: TimeEntry.human_attribute_name(:spent_on), rowspan: 1 },
      I18n.t(:"activerecord.models.work_package"),
      with_times_column? ? I18n.t(:"export.timesheet.time") : nil,
      { content: TimeEntry.human_attribute_name(:hours), align: :right },
      TimeEntry.human_attribute_name(:activity)
    ].compact
  end

  def table_columns_widths
    @table_columns_widths ||= if with_times_column?
                                [COLUMN_DATE_WIDTH, COLUMN_WP_WIDTH, COLUMN_TIME_WIDTH, COLUMN_HOURS_WIDTH,
                                 COLUMN_ACTIVITY_WIDTH]
                              else
                                [COLUMN_DATE_WIDTH, COLUMN_WP_WIDTH + COLUMN_TIME_WIDTH, COLUMN_HOURS_WIDTH,
                                 COLUMN_ACTIVITY_WIDTH]
                              end
  end

  def build_table(rows, has_sum_row, with_anchors)
    pdf.make_table(
      rows,
      header: true,
      width: table_columns_widths.sum,
      column_widths: table_columns_widths,
      cell_style: {
        size: TABLE_CELL_FONT_SIZE,
        border_color: TABLE_CELL_BORDER_COLOR,
        border_width: 0.5,
        borders: %i[top bottom],
        padding: [TABLE_CELL_PADDING, TABLE_CELL_PADDING_RIGHT, TABLE_CELL_PADDING_BOTTOM, TABLE_CELL_PADDING]
      }
    ) do |table|
      adjust_borders_first_column(table)
      adjust_borders_last_column(table)
      adjust_borders_spanned_column(table)
      adjust_border_header_row(table)
      adjust_border_sum_row(table) if has_sum_row
      add_pdf_table_anchors(table) if with_anchors
    end
  end

  def adjust_borders_first_column(table)
    table.columns(0).style do |c|
      c.borders = %i[top bottom left right]
      c.padding = [TABLE_CELL_PADDING, TABLE_CELL_PADDING, TABLE_CELL_PADDING_BOTTOM, TABLE_CELL_PADDING]
    end
  end

  def adjust_borders_last_column(table)
    table.columns(table_columns_widths.length - 1).style do |c|
      c.borders = c.borders + [:right]
    end
  end

  def adjust_borders_spanned_column(table)
    table.columns(1).style do |c|
      if c.colspan > 1
        c.borders = %i[left right bottom]
        c.padding = [0, TABLE_CELL_PADDING_RIGHT, TABLE_CELL_PADDING_BOTTOM, TABLE_CELL_PADDING]
        row_nr = c.row - 1
        values = table.columns(1..-1).rows(row_nr..row_nr)
        values.each do |cell|
          cell.borders = cell.borders - [:bottom]
        end
      end
    end
  end

  def adjust_border_header_row(table)
    table.rows(0).style do |c|
      c.borders = c.borders + [:top]
      c.font_style = :bold
    end
  end

  def adjust_border_sum_row(table)
    table.rows(-1).columns(0).style do |c|
      c.borders = c.borders - [:right]
    end
  end

  def split_group_rows(table_rows, has_sum_row)
    measure_table = build_table(table_rows, has_sum_row, false)
    groups = []
    index = 0
    while index < table_rows.length
      row = table_rows[index]
      rows = [row]
      height = measure_table.row(index).height
      index += 1
      if (row[0][:rowspan] || 1) > 1
        rows.push(table_rows[index])
        height += measure_table.row(index).height
        index += 1
      end
      groups.push({ rows:, height: })
    end
    groups
  end

  def write_table(user, entries)
    wants_sum_row = more_than_one_day?(entries)
    rows = build_table_rows(entries, wants_sum_row)
    # prawn-table does not support splitting a rowspan cell on page break, so we have to merge the first column manually
    # for easier handling existing rowspan cells are grouped as one row
    grouped_rows = split_group_rows(rows, wants_sum_row)
    # start a new page if the username would be printed alone at the end of the page
    pdf.start_new_page if available_space_from_bottom < grouped_table_height(grouped_rows)
    write_username(user)
    write_grouped_tables(grouped_rows, wants_sum_row)
  end

  def grouped_table_height(grouped_rows)
    grouped_rows[0][:height] + grouped_rows[1][:height] + username_height
  end

  def more_than_one_day?(entries)
    entries.map(&:spent_on).uniq.length > 1
  end

  def available_space_from_bottom
    margin_bottom = pdf.options[:bottom_margin] + 20 # 20 is the safety margin
    pdf.y - margin_bottom
  end

  def write_grouped_tables(grouped_rows, has_sum_row)
    header_row = grouped_rows[0]
    current_table = []
    current_table_height = 0
    grouped_rows.each do |grouped_row|
      grouped_row_height = grouped_row[:height]
      if current_table_height + grouped_row_height >= available_space_from_bottom
        write_grouped_row_table(current_table, false)
        pdf.start_new_page
        current_table = [header_row]
        current_table_height = header_row[:height]
      end
      current_table.push(grouped_row)
      current_table_height += grouped_row_height
    end
    write_grouped_row_table(current_table, has_sum_row)
    pdf.move_down(TABLE_MARGIN_BOTTOM)
  end

  def write_grouped_row_table(grouped_rows, has_sum_row)
    current_table = []
    merge_first_columns(grouped_rows)
    grouped_rows.map! { |row| current_table.concat(row[:rows]) }
    build_table(current_table, has_sum_row, true).draw
  end

  def merge_first_columns(grouped_rows)
    last_row = grouped_rows[1]
    index = 2
    while index < grouped_rows.length
      grouped_row = grouped_rows[index]
      last_row = merge_first_rows(grouped_row, last_row)
      index += 1
    end
  end

  def merge_first_rows(grouped_row, last_row)
    grouped_cell = grouped_row[:rows][0][0]
    last_cell = last_row[:rows][0][0]
    if grouped_cell[:content] == last_cell[:content]
      last_cell[:rowspan] += grouped_cell[:rowspan]
      grouped_row[:rows][0].shift
      last_row
    else
      grouped_row
    end
  end

  def sorted_results
    query.each_direct_result.map(&:itself)
  end

  def write_hr!
    hr_style = styles.cover_header_border
    write_horizontal_line(pdf.cursor, hr_style[:height], hr_style[:color])
    pdf.move_down(HR_MARGIN_BOTTOM)
  end

  def write_overview!
    users = all_users
    return if users.size <= 1

    write_heading!
    write_hr!
    write_overview_table!(users)
    write_sums_tables!(users)
    start_new_page_if_needed
  end

  def write_overview_table!(users)
    pdf.formatted_text([{ text: I18n.t("export.timesheet.overview_per_user_total"), size: OVERVIEW_HEADER_FONT_SIZE,
                          style: :bold }])
    pdf.move_down(PARAGRAPH_MARGIN_BOTTOM)
    pdf.make_table(
      overview_table_rows(users),
      header: true,
      width: pdf.bounds.width,
      cell_style: {
        size: TABLE_CELL_FONT_SIZE,
        border_color: TABLE_CELL_BORDER_COLOR,
        border_width: 0.5,
        borders: %i[top bottom left right],
        padding: [TABLE_CELL_PADDING, TABLE_CELL_PADDING, TABLE_CELL_PADDING_BOTTOM, TABLE_CELL_PADDING]
      }
    ) do |table|
      adjust_overview_border_sum_row(table)
    end.draw
    pdf.move_down(TABLE_MARGIN_BOTTOM)
  end

  def overview_table_rows(users)
    rows = [
      [
        { content: TimeEntry.human_attribute_name(:user), font_style: :bold },
        { content: I18n.t("export.timesheet.sums_hours"), font_style: :bold, align: :right }
      ]
    ]
    users.each do |user|
      entries = all_entries.select { |entry| entry.user == user }
      rows.push(
        [
          { content: make_link_anchor("user_#{user.id}", user.name), inline_format: true },
          { content: format_sum_time_entries(entries), align: :right }
        ]
      )
    end
    rows.push(["", { content: format_sum_time_entries(all_entries), font_style: :bold, align: :right }])
    rows
  end

  def adjust_overview_border_sum_row(table)
    row = table.rows(-1)
    row.columns(0).style { |c| c.borders = c.borders - [:right] }
    row.columns(-1).style { |c| c.borders = c.borders - [:left] }
  end

  def write_sums_tables!(users)
    sum_user_tables = build_sum_table_groups(users)
    sum_user_tables.each_with_index do |user_rows_group, index|
      write_sum_table!(user_rows_group[0], user_rows_group[1], index, sum_user_tables.length)
      pdf.move_down(TABLE_MARGIN_BOTTOM)
    end
  end

  def build_sum_table_groups(users)
    start_date, end_date = all_entries.map(&:spent_on).minmax
    num_groups = (users.length / SUM_TABLE_MAX_USER_COLUMNS.to_f).ceil
    grouped_user_rows = []
    users
      .in_groups(num_groups, false) do |users_chunk|
      group_users = users_chunk.compact
      rows = build_sum_table_rows(group_users, start_date, end_date)
      grouped_user_rows.push([group_users, rows]) unless rows.empty?
    end
    grouped_user_rows
  end

  def build_sum_table_footer_rows(users, users_sums)
    [
      [{ content: I18n.t("export.timesheet.sums_hours"), font_style: :bold }] + users.map do |user|
        { content: format_hours(users_sums[user.id]), align: :right, font_style: :bold }
      end
    ]
  end

  def build_sum_table_row(date, users, users_sums)
    row = []
    users.each do |user|
      sum = calc_sum_for_user_on_day(user, date)
      users_sums[user.id] = (users_sums[user.id] || 0) + sum
      row.push(sum > 0 ? build_sum_table_sum_cell(sum, user, date) : "")
    end
    return nil unless row.any? { |column| !column.empty? }

    [format_date_with_weekday(date)] + row
  end

  def build_sum_table_sum_cell(sum, user, date)
    {
      content: make_link_anchor(spent_on_day_id(user, date), format_hours(sum)),
      align: :right, inline_format: true
    }
  end

  def format_date_with_weekday(date)
    "#{format_date(date)}, #{I18n.l(date.to_date, format: '%a')}"
  end

  def calc_sum_for_user_on_day(user, date)
    sum_time_entries(all_entries.select { |entry| entry.user == user && entry.spent_on == date })
  end

  def build_sum_table_rows(users, start_date, end_date)
    rows = []
    users_sums = {}
    (start_date..end_date).each do |date|
      row = build_sum_table_row(date, users, users_sums)
      rows.push(row) unless row.nil?
    end
    rows = rows + build_sum_table_footer_rows(users, users_sums) unless rows.empty?
    rows
  end

  def build_sum_table_header_row(users)
    [{ content: TimeEntry.human_attribute_name(:spent_on), font_style: :bold }] +
      users.map do |user|
        {
          content: make_link_anchor("user_#{user.id}", user.name),
          inline_format: true, font_style: :bold
        }
      end
  end

  def write_sum_table_headline(index, total_groups)
    styling = { size: OVERVIEW_HEADER_FONT_SIZE, style: :bold }
    headline = [styling.merge({ text: I18n.t("export.timesheet.overview_per_user_day") })]
    headline += [styling.merge({ text: " (#{index + 1}/#{total_groups})" })] if total_groups > 1
    pdf.formatted_text(headline)
    pdf.move_down(PARAGRAPH_MARGIN_BOTTOM)
  end

  def write_sum_table!(users, rows, index, total_groups)
    write_sum_table_headline(index, total_groups)
    rows.unshift(build_sum_table_header_row(users))
    pdf.table(
      rows,
      header: true,
      width: pdf.bounds.width,
      column_widths: sum_table_column_widths(users),
      cell_style: {
        size: TABLE_CELL_FONT_SIZE,
        border_color: TABLE_CELL_BORDER_COLOR,
        border_width: 0.5,
        borders: %i[top bottom left right],
        padding: [TABLE_CELL_PADDING, TABLE_CELL_PADDING, TABLE_CELL_PADDING_BOTTOM, TABLE_CELL_PADDING]
      }
    )
  end

  def sum_table_column_widths(users)
    [SUM_TABLE_FIRST_COLUMN_WIDTH].concat(
      [(pdf.bounds.width - SUM_TABLE_FIRST_COLUMN_WIDTH) / users.length] * users.length
    )
  end

  def write_heading!
    pdf.formatted_text([{ text: heading, size: H1_FONT_SIZE, style: :bold }])
    pdf.move_down(H1_MARGIN_BOTTOM)
  end

  def username_height
    20 + 10
  end

  def write_username(user)
    link_target_at_current_y("user_#{user.id}")
    pdf.formatted_text([{ text: user.name, size: H2_FONT_SIZE }])
    pdf.move_down(H2_MARGIN_BOTTOM)
  end

  def footer_date
    if pdf.page_number == 1
      format_time(Time.zone.now)
    else
      format_date(Time.zone.now)
    end
  end

  def format_hours(hours)
    return "" if hours.nil? || hours < 0

    DurationConverter.output(hours, format: :hours_colon_minutes)
  end

  def format_spent_on_time(entry)
    spent_on_time_representation(entry.start_timestamp, entry.hours)
  end

  def with_times_column?
    Setting.allow_tracking_start_and_end_times
  end

  def with_cover?
    true
  end

  def wants_total_page_nrs?
    true
  end
end

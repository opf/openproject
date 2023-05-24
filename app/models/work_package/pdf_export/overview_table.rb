#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module WorkPackage::PDFExport::OverviewTable
  def write_work_packages_overview!(work_packages, id_wp_meta_map)
    if query.grouped?
      write_grouped!(work_packages, id_wp_meta_map)
    else
      with_margin(overview_table_margins_style) do
        write_table!(work_packages, id_wp_meta_map, get_total_sums)
      end
    end
  end

  private

  def write_grouped!(work_packages, id_wp_meta_map)
    groups = work_packages.group_by do |work_package|
      query.group_by_column.value(work_package)
    end
    groups.each do |group, grouped_work_packages|
      write_group!(group, grouped_work_packages, id_wp_meta_map, get_group_sums(group))
    end
  end

  def table_columns_objects
    @table_columns_objects ||= limit_table_columns_objects
  end

  def limit_table_columns_objects
    list = column_objects
    list = list.reject { |c| c == query.group_by_column } if query.grouped?
    list
  end

  def table_column_widths
    widths = table_columns_objects.map do |col|
      col.name == :subject || text_column?(col) ? 4.0 : 1.0
    end
    widths.unshift 1.0 if with_descriptions?
    ratio = pdf.bounds.width / widths.sum
    widths.map { |w| w * ratio }
  end

  def write_group!(group, work_packages, id_wp_meta_map, sums)
    write_optional_page_break(page_break_space_left_threshold)
    with_margin(overview_table_margins_style) do
      label = make_group_label(group)
      with_margin(overview_group_header_margins_style) do
        pdf.formatted_text([overview_group_header_style.merge({ text: label })])
      end
      write_table!(work_packages, id_wp_meta_map, sums)
    end
  end

  def write_table!(work_packages, id_wp_meta_map, sums)
    rows = build_table_rows(work_packages, id_wp_meta_map, sums)
    pdf_table_auto_widths(rows, table_column_widths, table_options) do |table|
      format_sum_cells table.cells.columns(0..-1).rows(-1) if query.display_sums?
    end
  end

  def table_options
    { header: true, cell_style: overview_table_cell_style.merge({ inline_format: true }) }
  end

  def format_sum_cells(sums_cells)
    sums_style = overview_table_sums_cell_style
    sums_cells.each do |cell|
      apply_cell_style cell, sums_style
    end
  end

  def apply_cell_style(cell, style)
    cell.background_color = style[:background_color]
    cell.font_style = style[:font_style]
    cell.text_color = style[:text_color]
    cell.size = style[:size]
  end

  def get_total_sums
    query.results.all_total_sums if query.display_sums?
  end

  def get_group_sums(group)
    return nil unless query.display_sums?

    @group_sums ||= query.results.all_group_sums
    @group_sums[group]
  end

  def build_table_rows(work_packages, id_wp_meta_map, sums)
    rows = work_packages.map do |work_package|
      build_table_row(work_package, id_wp_meta_map)
    end
    rows.unshift build_header_row
    rows.push build_sum_row(sums) unless sums.nil?
    rows
  end

  def build_table_row(work_package, id_wp_meta_map)
    row = table_columns_objects.map do |col|
      content = get_column_value_cell work_package, col.name
      col.name == :subject ? build_subject_cell(content, work_package, id_wp_meta_map) : build_column_cell(content)
    end
    row.unshift build_nr_cell(work_package, id_wp_meta_map) if with_descriptions?
    row
  end

  def build_column_cell(content)
    pdf.make_cell(content, overview_table_cell_padding_style)
  end

  def build_nr_cell(work_package, id_wp_meta_map)
    content = "#{id_wp_meta_map[work_package.id][:level_path].join('.')}."
    content = make_link_anchor(work_package.id, content)
    build_column_cell(content)
  end

  def build_subject_cell(content, work_package, id_wp_meta_map)
    opts = overview_table_cell_padding_style
    padding_left = opts[:padding_left]
    if query.show_hierarchies
      level = id_wp_meta_map[work_package.id][:level_path].length
      padding_left = (overview_table_subject_indent_style * level) if level > 1
    end
    pdf.make_cell(content, opts.merge({ padding_left: }))
  end

  def build_header_row
    header_style = overview_table_header_cell_style
    row = table_columns_objects.map do |col|
      content = (col.caption || '').upcase
      build_header_cell(content, header_style)
    end
    row.unshift build_header_cell('#', header_style) if with_descriptions?
    row
  end

  def build_header_cell(content, opts)
    pdf.make_cell(content, opts)
  end

  def build_sum_row(sums)
    sum_row = table_columns_objects.map { |col| sums[col].to_s }
    sum_row[0] = this.I18n.t('js.label_sum')
    sum_row
  end
end

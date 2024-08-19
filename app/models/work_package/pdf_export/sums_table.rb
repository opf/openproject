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

module WorkPackage::PDFExport::SumsTable
  def write_work_packages_sums!(_work_packages)
    return unless has_summable_column?

    write_optional_page_break
    write_sums_title
    with_margin(styles.overview_table_margins) do
      write_sums_table
    end
  end

  private

  def has_summable_column?
    !sums_columns_objects.empty?
  end

  def write_sums_title
    with_margin(styles.page_heading_margins) do
      pdf.formatted_text([styles.page_heading.merge({ text: I18n.t("js.work_packages.tabs.overview") })])
    end
  end

  def sums_columns_objects
    @sums_columns_objects ||= column_objects.select(&:summable?)
  end

  def sums_table_column_widths
    widths = sums_columns_objects.map do |col|
      col.name == :subject || text_column?(col) ? 4.0 : 1.0
    end
    widths.unshift 1.0
    ratio = pdf.bounds.width / widths.sum
    widths.map { |w| w * ratio }
  end

  def write_sums_table
    rows = [build_sums_header_row]
    if query.grouped?
      get_groups.each do |group|
        rows.push build_sums_group_row(group)
      end
    end
    rows.push build_sums_total_row
    pdf_table_auto_widths(rows, sums_table_column_widths, sums_table_options)
  end

  def sums_table_options
    { header: true, cell_style: styles.overview_table_cell.merge({ inline_format: true }) }
  end

  def build_sums_header_row
    header_style = styles.overview_table_header_cell
    row = sums_columns_objects.map do |col|
      pdf.make_cell(sums_column_name(col), header_style)
    end
    content = query.grouped? ? sums_column_name(query.group_by_column) : ""
    row.unshift pdf.make_cell(content, header_style)
    row
  end

  def sums_column_name(col)
    (col.caption || "").upcase
  end

  def build_sums_group_row(group)
    build_sums_row(get_group_sums(group), make_group_label(group), styles.overview_table_cell)
  end

  def build_sums_total_row
    build_sums_row(get_total_sums || {}, I18n.t("js.label_sum"), styles.overview_table_sums_cell)
  end

  def build_sums_row(sums, label, sums_style)
    sum_row = sums_columns_objects.map do |col|
      content = get_formatted_value(sums[col], col.name)
      pdf.make_cell(content, sums_style)
    end
    sum_row.unshift pdf.make_cell(label, sums_style)
    sum_row
  end
end

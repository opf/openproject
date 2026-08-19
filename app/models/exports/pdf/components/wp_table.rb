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

module Exports::PDF::Components::WpTable
  def write_work_packages_table!(work_packages, query)
    columns = limit_table_columns_objects(query)
    if query.grouped?
      write_grouped!(work_packages, query, columns)
    else
      with_margin(styles.wp_table_margins) do
        write_table!(work_packages, query, columns, get_sums(query))
      end
    end
  end

  private

  def get_sums(query)
    query.display_sums? ? (query.results.all_total_sums || {}) : {}
  end

  def write_grouped!(work_packages, query, columns)
    groups_with_work_packages = work_packages.group_by do |work_package|
      query.group_by_column.value(work_package)
    end
    sums = transformed_sum_group(query)
    groups_with_work_packages.each do |group, grouped_work_packages|
      write_group!(group, grouped_work_packages, query, columns, sums[group] || {})
    end
  end

  # -- start workaround
  #
  # This code is a workaround for currently getting "which group a WP belongs to" is not implemented
  # see an equal situation for the frontend
  # this is problematic with custom fields:
  #
  # /frontend/src/app/features/work-packages/components/wp-fast-table/builders/modes/grouped/grouped-render-pass.ts#L72
  #
  # a) query.group_by_column.value(work_package) returns the _value_ of a group
  # => so a resulting hash has group values as keys e.g.
  # { nil: …,
  #   "Foo": …,
  #   "Bar": …,
  #   ["Foo","Bar"]: …
  # }
  #
  # b) query.results.all_group_sums returns a hash with the group as key - not the value, e.g.
  # {
  # { []: …,
  #   [#<CustomOption … value: "Foo">]: …,
  #   [#<CustomOption … value: "Bar">]: …,
  #   [#<CustomOption … value: "Bar">, #<CustomOption value: "Foo"">] …,
  # }
  #
  #  we therefor transform the keys of sums from b) to a)

  def transformed_sum_group(query)
    sums = query.results.all_group_sums
    if query.group_by_column.is_a?(Queries::WorkPackages::Selects::CustomFieldSelect)
      transform_custom_field_keys(sums, query)
    else
      sums
    end
  end

  def transform_custom_field_keys(groups, query)
    custom_field = query.group_by_column.custom_field
    if custom_field.list?
      transform_list_custom_field_keys(custom_field, groups)
    else
      transform_single_custom_field_keys(custom_field, groups)
    end
  end

  def transform_single_custom_field_keys(custom_field, groups)
    groups.transform_keys { |key| custom_field.cast_value(key) }
  end

  def transform_list_custom_field_keys(custom_field, groups)
    groups.transform_keys do |key|
      if custom_field.multi_value?
        transform_multi_list_custom_field_key(key)
      else
        key&.value
      end
    end
  end

  def transform_multi_list_custom_field_key(key)
    list = key.map { |v| v&.value }
    if list.empty?
      nil
    else
      list
    end
  end

  # -- end workaround

  def limit_table_columns_objects(query)
    list = query
             .columns
             .reject { |c| c.is_a?(Queries::WorkPackages::Selects::RelationSelect) }
    list = list.reject { |c| c == query.group_by_column } if query.grouped?
    list
  end

  def table_column_widths(columns)
    widths = columns.map do |col|
      col.name == :subject || text_column?(col) ? 4.0 : 1.0
    end
    ratio = pdf.bounds.width / widths.sum
    widths.map { |w| w * ratio }
  end

  def write_group!(group, work_packages, query, columns, sums)
    write_optional_page_break
    with_margin(styles.wp_table_margins) do
      with_margin(styles.wp_table_group_header_margins) do
        style = styles.wp_table_group_header
        pdf.formatted_text([style.merge({ text: make_group_label(group) })], style)
      end
      write_table!(work_packages, query, columns, sums)
    end
  end

  def write_table!(work_packages, query, columns, sums)
    rows = build_table_rows(work_packages, query, columns, sums)
    pdf_table_auto_widths(rows, table_column_widths(columns), wp_table_options)
  end

  def wp_table_options
    { header: true, cell_style: styles.wp_table_cell.merge({ inline_format: true }) }
  end

  def build_table_rows(work_packages, query, columns, sums)
    rows = work_packages.map do |work_package|
      build_table_row(work_package, columns)
    end
    rows.unshift build_header_row(columns)
    rows.push build_sum_row(columns, sums) if query.display_sums?
    rows
  end

  def build_table_row(work_package, columns)
    cell_style = styles.wp_table_cell
    columns.map do |col|
      content = get_column_value_cell work_package, col.name
      if col.name == :subject
        build_subject_cell(content)
      else
        pdf.make_cell(content, cell_style)
      end
    end
  end

  def build_subject_cell(content)
    cell_style = styles.wp_table_cell
    padding_left = cell_style.fetch(:padding_left, 0)
    pdf.make_cell(content, cell_style.merge({ padding_left: }))
  end

  def build_header_row(columns)
    header_style = styles.wp_table_header_cell
    columns.map do |col|
      content = col.caption || ""
      pdf.make_cell(content, header_style)
    end
  end

  def build_sum_row(columns, sums)
    sums_style = styles.wp_table_sums_cell
    sum_row = columns.map do |col|
      content = get_formatted_value(sums[col], col.name)
      pdf.make_cell(content, sums_style)
    end
    sum_row[0] = pdf.make_cell(I18n.t("js.label_sum"), sums_style)
    sum_row
  end
end

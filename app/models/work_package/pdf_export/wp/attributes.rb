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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackage::PDFExport::Wp::Attributes
  def write_attributes!(work_package)
    form_configuration(work_package).groups.each do |group|
      case group
      when WorkPackage::Exports::FormConfiguration::AttributeGroup
        write_attributes_group(group, work_package)
      when WorkPackage::Exports::FormConfiguration::QueryGroup
        write_query_group(group)
      end
    end
  end

  private

  def form_configuration(work_package)
    @form_configuration ||= WorkPackage::Exports::FormConfiguration.new(work_package)
  end

  def write_long_text_custom_field!(work_package, markdown, label)
    write_optional_page_break
    write_long_text_custom_field_label(label)
    write_markdown_field_value(work_package, markdown)
  end

  def write_long_text_custom_field_label(label)
    style = styles.wp_attributes_table_label
    with_margin(styles.markdown_field_label_margins) do
      pdf.formatted_text([style.merge({ text: label })], style)
    end
  end

  def write_query_group(group)
    return write_query_group_as_table(group) if query_group_as_table?(group)

    write_query_group_as_attributes(group)
  end

  # to be overridden in subclasses
  def query_group_as_table?(_group)
    true
  end

  def write_query_group_as_attributes(group)
    write_group_title(group)
    if group.work_packages.empty?
      write_inline_hint("[No work packages]")
      return
    end

    column_entries = query_group_column_entries(group.query)
    group.work_packages.each do |related_work_package|
      write_related_work_package_attributes(related_work_package, column_entries)
    end
  end

  def query_group_column_entries(query)
    limit_table_columns_objects(query)
      .reject { |column| column.name == :subject }
      .map { |column| { label: column.caption || "", name: column.name } }
  end

  def write_related_work_package_attributes(work_package, column_entries)
    write_optional_page_break
    write_related_work_package_subject(work_package)
    list = column_entries.map do |entry|
      entry.merge({ value: get_column_value_cell(work_package, entry[:name]) })
    end
    write_attributes_table(form_config_group_to_column_entries_rows(list))
  end

  def write_related_work_package_subject(work_package)
    style = styles.wp_attributes_subject
    with_margin(styles.wp_attributes_subject_margins) do
      pdf.formatted_text([style.merge({ text: get_column_value(work_package, :subject) })], style)
    end
  end

  def write_query_group_as_table(group)
    write_group_title(group)
    if group.work_packages.empty?
      write_inline_hint("[No work packages]")
    else
      write_work_packages_table!(group.work_packages, group.query)
    end
  rescue Prawn::Errors::CannotFit
    write_inline_error("[#{I18n.t('export.errors.embedded_table_with_too_many_columns')}]")
  end

  def write_inline_hint(text)
    style = styles.inline_hint
    with_margin(styles.wp_table_margins) do
      pdf.formatted_text([style.merge({ text: })], style)
    end
  end

  def write_inline_error(text)
    style = styles.inline_error
    with_margin(styles.markdown_field_label_margins) do
      pdf.formatted_text([style.merge({ text: })], style)
    end
  end

  def write_attributes_group(group, work_package)
    write_group_title(group)
    group.parts.each do |part|
      case part
      when WorkPackage::Exports::FormConfiguration::AttributesPart
        write_attributes_table(form_config_group_to_column_entries_rows(attribute_entries_with_values(part, work_package)))
      when WorkPackage::Exports::FormConfiguration::LongTextPart
        write_long_text_custom_field!(work_package, part.markdown, part.label)
      end
    end
  end

  def attribute_entries_with_values(part, work_package)
    part.entries.map do |entry|
      { label: entry.label, name: entry.name, value: get_column_value_cell(work_package, entry.name) }
    end
  end

  def write_attributes_table(rows)
    return if rows.empty?

    with_margin(styles.wp_attributes_table_margins) do
      pdf.table(
        rows,
        column_widths: attributes_table_column_widths,
        cell_style: styles.wp_attributes_table_cell.merge({ inline_format: true })
      )
    end
  end

  def write_group_title(group, with_hr: true)
    write_optional_page_break
    with_margin(styles.wp_attributes_group_label_margins) do
      style = styles.wp_attributes_group_label
      pdf.formatted_text([style.merge({ text: group.title })], style)
      write_group_title_hr if with_hr
    end
  end

  def write_group_title_hr
    hr_style = styles.wp_attributes_group_label_hr
    write_horizontal_line(pdf.cursor, hr_style[:height], hr_style[:color])
  end

  def form_config_group_to_column_entries_rows(list)
    nr = page_orientation_landscape? ? 4 : 2
    0.step(list.length - 1, nr).map do |i|
      Array.new(nr).each_with_index.map do |_, j|
        build_columns_table_cells(list[i + j])
      end.flatten
    end
  end

  def attributes_table_column_widths
    # calculate fixed work package attribute table columns width
    widths = [1.5, 2.0] # label | value
    widths = widths * (page_orientation_landscape? ? 4 : 2)
    ratio = pdf.bounds.width / widths.sum
    widths.map { |w| w * ratio }
  end

  def build_columns_table_cells(attribute_data)
    return ["", ""] if attribute_data.nil?

    # get work package attribute table cell data: [label, value]
    [
      pdf.make_cell(attribute_data[:label], styles.wp_attributes_table_label_cell),
      attribute_data[:value]
    ]
  end

  def get_column_value_cell(work_package, column_name)
    get_value_cell_by_column(work_package, column_name, true)
  end
end

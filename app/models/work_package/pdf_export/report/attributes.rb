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

module WorkPackage::PDFExport::Report::Attributes
  RELATION_COLUMN_TABLE_COLUMN_NAMES = %i[id type subject status start_date due_date].freeze

  AttributeField = Data.define(:label, :name, :value)
  RelationField = Data.define(:label, :name, :value)
  FormattableField = Data.define(:label, :name, :value)

  def write_attributes_tables!(work_package)
    field_groups = collect_field_groups(work_package)
    return if field_groups.empty?

    field_groups.each do |non_formattable_fields, special_field|
      write_attributes_table(non_formattable_fields)
      case special_field
      when RelationField
        write_relation_field(work_package, special_field)
      when FormattableField
        write_markdown_field!(work_package, special_field.value, special_field.label)
      end
    end
  end

  private

  def collect_field_groups(work_package)
    field_groups = []
    non_formattable_fields_at_end = process_columns(work_package).inject([]) do |non_formattable_field_stack, field|
      if field.is_a?(RelationField) || field.is_a?(FormattableField)
        field_groups.push([non_formattable_field_stack, field])
        []
      else
        non_formattable_field_stack + [field]
      end
    end
    field_groups << [non_formattable_fields_at_end, nil]
    field_groups
  end

  def process_columns(work_package)
    query
      .columns
      .reject { |column| column.name == :subject }
      .map { |column| process_column(work_package, column) }
  end

  def process_column(work_package, column)
    return formattable_column(work_package, column) if formattable_column?(column)
    return relation_column(work_package, column) if relationship_column?(column)

    attribute_column(work_package, column)
  end

  def formattable_column?(column)
    column.is_a?(Queries::WorkPackages::Selects::CustomFieldSelect) && column.custom_field&.formattable?
  end

  def relationship_column?(column)
    column.is_a?(Queries::WorkPackages::Selects::RelationSelect)
  end

  def attribute_column(work_package, column)
    AttributeField.new(
      label: column.caption || "",
      name: column.name,
      value: get_column_value_cell(work_package, column.name)
    )
  end

  def relation_column(_work_package, column)
    RelationField.new(
      label: column.caption || "",
      name: column.name,
      value: column
    )
  end

  def formattable_column(work_package, column)
    FormattableField.new(
      label: column.caption || "",
      name: column.name,
      value: formattable_column_value(work_package, column)
    )
  end

  def formattable_column_value(work_package, column)
    custom_value = work_package.custom_value_for(column.custom_field)
    custom_value&.value
  end

  def write_attributes_table(fields)
    return if fields.empty?

    rows = attribute_table_rows(fields)
    return if rows.empty?

    with_margin(styles.wp_attributes_table_margins) do
      pdf.table(
        rows,
        column_widths: attributes_table_column_widths,
        cell_style: styles.wp_attributes_table_cell.merge({ inline_format: true })
      )
    end
  end

  def attributes_table_column_widths
    # calculate fixed work package attribute table columns width
    widths = [1.5, 2.0, 1.5, 2.0] # label | value | label | value
    ratio = pdf.bounds.width / widths.sum
    widths.map { |w| w * ratio }
  end

  def attribute_table_rows(fields)
    0.step(fields.length - 1, 2).map do |i|
      build_columns_table_cells(fields[i]) +
        build_columns_table_cells(fields[i + 1])
    end
  end

  def build_columns_table_cells(attribute_data)
    return ["", ""] if attribute_data.nil?

    # get work package attribute table cell data: [label, value]
    [
      pdf.make_cell(attribute_data.label, styles.wp_attributes_table_label_cell),
      attribute_data.value
    ]
  end

  def get_column_value_cell(work_package, column_name)
    get_value_cell_by_column(work_package, column_name, wants_report?)
  end

  def relation_query
    @relation_query ||= Query.new(name: "relations", column_names: RELATION_COLUMN_TABLE_COLUMN_NAMES)
  end

  def related_work_packages_for(work_package, column)
    case column
    when Queries::WorkPackages::Selects::RelationChildSelect
      work_package.children.visible
    when Queries::WorkPackages::Selects::RelationOfTypeSelect
      relation_of_type_work_packages(work_package, column.relation_type)
    when Queries::WorkPackages::Selects::RelationToTypeSelect
      relation_to_type_work_packages(work_package, column.type)
    else
      []
    end
  end

  def relation_of_type_work_packages(work_package, relation_type)
    work_package.relations.visible.filter_map do |relation|
      relation.other_work_package(work_package) if relation.relation_type_for(work_package) == relation_type
    end
  end

  def relation_to_type_work_packages(work_package, type)
    work_package.relations.visible.filter_map do |relation|
      other = relation.other_work_package(work_package)
      other if other.type_id == type.id
    end
  end

  def write_relation_field(work_package, field)
    related_wps = related_work_packages_for(work_package, field.value)
    return if related_wps.empty?

    write_optional_page_break
    write_attribute_group_label(field.label)
    write_work_packages_table!(related_wps, relation_query)
  end

  def write_attribute_group_label(text)
    style = styles.wp_attributes_group_label
    with_margin(styles.wp_attributes_group_label_margins) do
      pdf.formatted_text([style.merge({ text: })], style)
    end
  end
end

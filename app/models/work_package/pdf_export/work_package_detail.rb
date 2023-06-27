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

module WorkPackage::PDFExport::WorkPackageDetail
  include WorkPackage::PDFExport::MarkdownField

  def write_work_packages_details!(work_packages, id_wp_meta_map)
    work_packages.each do |work_package|
      write_work_package_detail!(work_package, id_wp_meta_map[work_package.id])
    end
  end

  def write_work_package_detail!(work_package, id_wp_meta_map_entry)
    write_optional_page_break
    id_wp_meta_map_entry[:page_number] = current_page_nr
    with_margin(styles.wp_margins) do
      write_work_package_subject! work_package, id_wp_meta_map_entry[:level_path]
      write_work_package_detail_content! work_package
    end
  end

  def write_work_package_detail_content!(work_package)
    write_attributes_table! work_package
    write_description! work_package
    write_custom_fields! work_package
  end

  private

  def write_work_package_subject!(work_package, level_path)
    with_margin(styles.wp_detail_subject_margins) do
      link_target_at_current_y(work_package.id)
      level_string_width = write_work_package_level!(level_path)
      title = get_column_value work_package, :subject
      @pdf.indent(level_string_width) do
        pdf.formatted_text([styles.wp_subject.merge({ text: title })])
      end
    end
  end

  def write_work_package_level!(level_path)
    return 0 if level_path.empty?

    level_string = "#{level_path.join('.')}. "
    level_string_width = measure_text_width(level_string, styles.wp_subject)
    @pdf.float { @pdf.formatted_text([styles.wp_subject.merge({ text: level_string })]) }
    level_string_width
  end

  def write_attributes_table!(work_package)
    rows = if respond_to?(:column_objects)
             build_columns_table_rows(work_package)
           else
             build_attributes_table_rows(work_package)
           end
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

  def build_columns_table_rows(work_package)
    list = column_objects.reject { |column| column.name == :subject }
    0.step(list.length - 1, 2).map do |i|
      build_columns_table_cells(list[i], work_package) +
        build_columns_table_cells(list[i + 1], work_package)
    end
  end

  def build_attributes_table_rows(work_package)
    # get work package attribute table rows data [[label, value, label, value]]
    attrs = %i[
      id
      updated_at
      type
      created_at
      status
      due_date
      version
      priority
      duration
      work
      category
      assigned_to
    ]
    0.step(attrs.length - 1, 2).map do |i|
      build_attributes_table_cells(attrs[i], work_package) +
        build_attributes_table_cells(attrs[i + 1], work_package)
    end
  end

  def build_attributes_table_cells(attribute, work_package)
    # get work package attribute table cell data: [label, value]
    return ['', ''] if attribute.nil?

    build_attributes_row(WorkPackage.human_attribute_name(attribute) || '', attribute.to_sym, work_package)
  end

  def build_columns_table_cells(column, work_package)
    return ['', ''] if column.nil?

    build_attributes_row(column.caption || '', column.name, work_package)
  end

  def build_attributes_row(label, col_name, work_package)
    # get work package attribute table cell data: [label, value]
    [
      pdf.make_cell(label.upcase, styles.wp_attributes_table_label_cell),
      get_column_value_cell(work_package, col_name)
    ]
  end

  def write_description!(work_package)
    write_markdown_field!(work_package, work_package.description, WorkPackage.human_attribute_name(:description))
  end

  def write_custom_fields!(work_package)
    work_package.custom_field_values
                .select { |cv| cv.custom_field.formattable? }
                .each do |custom_value|
      write_markdown_field!(work_package, custom_value.value, custom_value.custom_field.name)
    end
  end
end

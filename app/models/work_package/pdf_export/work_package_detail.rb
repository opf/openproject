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
      write_work_package_detail!(work_package, id_wp_meta_map[work_package.id][:level_path])
    end
  end

  def write_work_package_detail!(work_package, level_path)
    # TODO: move page break threshold const to style settings and implement conditional break with height measuring
    write_optional_page_break(200)
    with_margin(detail_margins_style) do
      write_work_package_subject! work_package, level_path
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
    with_margin(subject_margins_style) do
      link_target_at_current_y(work_package.id)
      level_string_width = write_work_package_level!(level_path)
      title = get_column_value work_package, :subject
      @pdf.indent(level_string_width) { pdf.formatted_text([subject_font_style.merge({ text: title })]) }
    end
  end

  def write_work_package_level!(level_path)
    return 0 if level_path.empty?

    level_string = "#{level_path.join('.')}. "
    level_string_width = measure_text_width(level_string, subject_font_style)
    @pdf.float { @pdf.formatted_text([subject_font_style.merge({ text: level_string })]) }
    level_string_width
  end

  def write_attributes_table!(work_package)
    rows = build_attributes_table_rows work_package
    with_margin(attributes_table_margins_style) do
      pdf.table(
        rows,
        column_widths: attributes_table_column_widths,
        cell_style: attributes_table_cell_style.merge({ inline_format: true })
      )
    end
  end

  def attributes_table_column_widths
    # calculate fixed work package attribute table columns width
    widths = [1.5, 2.0, 1.5, 2.0] # label | value | label | value
    ratio = pdf.bounds.width / widths.sum
    widths.map { |w| w * ratio }
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

    label = (WorkPackage.human_attribute_name(attribute) || '').upcase
    [
      pdf.make_cell(label, attributes_table_label_font_style),
      get_column_value_cell(work_package, attribute.to_sym)
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

  def detail_margins_style
    { margin_top: 20 }
  end

  def subject_margins_style
    { margin_bottom: 4 }
  end

  def subject_font_style
    { size: 14, styles: [:bold] }
  end

  def attributes_table_margins_style
    { margin_top: 4, margin_bottom: 2 }
  end

  def attributes_table_label_font_style
    { font_style: :bold }
  end

  def attributes_table_cell_style
    { size: 9,
      text_color: "000000",
      border_widths: [0.25, 0.25, 0.25, 0.25],
      padding_left: 5,
      padding_right: 5,
      padding_top: 0,
      padding_bottom: 4 }
  end
end

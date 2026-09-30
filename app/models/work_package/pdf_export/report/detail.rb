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

module WorkPackage::PDFExport::Report::Detail
  def write_work_packages_details!(work_packages, id_wp_meta_map)
    work_packages.each do |work_package|
      write_work_package_detail!(work_package, id_wp_meta_map[work_package.id])
    end
  end

  private

  def write_work_package_detail!(work_package, id_wp_meta_map_entry)
    write_optional_page_break
    id_wp_meta_map_entry[:page_number] = current_page_nr
    with_margin(styles.wp_margins) do
      write_work_package_subject! work_package, id_wp_meta_map_entry[:level_path]
      write_work_package_detail_content! work_package
    end
  end

  def write_work_package_detail_content!(work_package)
    write_attributes_tables! work_package
    if options[:long_text_fields].nil?
      write_description! work_package
      write_custom_fields! work_package
    else
      write_long_text_fields! work_package
    end
  end

  def write_work_package_subject!(work_package, level_path)
    text_style = styles.wp_subject(level_path.length)
    with_margin(styles.wp_detail_subject_margins) do
      link_target_at_current_y(work_package.id)
      level_string_width = write_work_package_level!(level_path, text_style)
      title = get_column_value work_package, :subject
      pdf.indent(level_string_width) do
        pdf.formatted_text([text_style.merge({ text: title })], text_style)
      end
    end
  end

  def write_work_package_level!(level_path, text_style)
    return 0 if level_path.empty?

    level_string = "#{level_path.join('.')}. "
    level_string_width = measure_text_width(level_string, text_style)
    pdf.float { pdf.formatted_text([text_style.merge({ text: level_string })], text_style) }
    level_string_width
  end

  def write_long_text_fields!(work_package)
    selected_long_text_fields.each do |field_id_or_desc|
      if field_id_or_desc == "description"
        write_description!(work_package)
      else
        write_long_text_field!(work_package, field_id_or_desc.to_i)
      end
    end
  end

  def selected_long_text_fields
    @selected_long_text_fields ||= (options[:long_text_fields] || "").split
  end

  def write_description!(work_package)
    write_markdown_field!(work_package, work_package.description, WorkPackage.human_attribute_name(:description))
  end

  def write_long_text_field!(work_package, field_id)
    custom_value = work_package.custom_field_values
                .find { |cv| cv.custom_field.id == field_id && cv.custom_field.formattable? }
    if custom_value&.value
      write_markdown_field!(work_package, custom_value.value, custom_value.custom_field.name)
    end
  end

  def write_custom_fields!(work_package)
    work_package.custom_field_values
                .select { |cv| cv.custom_field.formattable? }
                .each do |custom_value|
      write_markdown_field!(work_package, custom_value.value, custom_value.custom_field.name)
    end
  end
end

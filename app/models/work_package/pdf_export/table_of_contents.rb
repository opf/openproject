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

module WorkPackage::PDFExport::TableOfContents
  def write_work_packages_toc!(work_packages, id_wp_meta_map)
    toc_list = build_toc_data_list work_packages, id_wp_meta_map
    with_margin(styles.toc_margins) do
      write_toc! toc_list
    end
    pdf.start_new_page
  end

  private

  def build_toc_data_list(work_packages, id_wp_meta_map)
    work_packages.map do |work_package|
      build_toc_data_list_entry work_package, id_wp_meta_map
    end
  end

  def build_toc_data_list_entry(work_package, id_wp_meta_map)
    level_path = id_wp_meta_map[work_package.id][:level_path]
    level = level_path.length
    level_style = styles.toc_item(level)
    level_string = "#{level_path.join('.')}. "
    page_nr_string = (id_wp_meta_map[work_package.id][:page_number] || '000').to_s
    { id: work_package.id,
      level_string:,
      level_string_width: measure_part_width(level_string, level_style),
      title: get_column_value(work_package, :subject),
      page_nr_string:,
      page_nr_string_width: measure_part_width(page_nr_string, level_style),
      level: }
  end

  def measure_part_width(part, part_style)
    measure_text_width(part, part_style) + styles.toc_item_subject_indent
  end

  def write_part_float(part, part_style)
    pdf.float do
      pdf.text(part, part_style)
    end
  end

  def write_toc!(toc_list)
    max_level_string_width = toc_list.pluck(:level_string_width).max
    toc_list.each do |toc_item|
      with_margin(styles.toc_item_margins(toc_item[:level])) do
        write_toc_item! toc_item, max_level_string_width
      end
    end
  end

  def write_toc_item_subject!(toc_item, max_level_width, subject_style)
    pdf.indent(max_level_width, toc_item[:page_nr_string_width]) do
      pdf.formatted_text([subject_style.merge({ text: toc_item[:title] })])
    end
  end

  def write_toc_item!(toc_item, max_level_width)
    y = pdf.y
    toc_item_style = styles.toc_item(toc_item[:level])
    part_style = toc_item_style.clone
    font_styles = part_style.delete(:styles) || []
    part_style[:style] = font_styles[0] unless font_styles.empty?
    write_part_float(toc_item[:level_string], part_style)
    write_part_float(toc_item[:page_nr_string], part_style.merge({ align: :right }))
    write_toc_item_subject!(toc_item, max_level_width, toc_item_style)

    rect = [pdf.bounds.absolute_right, pdf.y, pdf.bounds.absolute_left, y]
    pdf.link_annotation(rect, Border: [0, 0, 0], Dest: toc_item[:id].to_s)
  end
end

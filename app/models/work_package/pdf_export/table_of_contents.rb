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
    with_margin(toc_margins_style) do
      write_toc! toc_list
    end
    pdf.start_new_page
  end

  private

  def build_toc_data_list(work_packages, id_wp_meta_map)
    work_packages.map do |work_package|
      level_path = id_wp_meta_map[work_package.id][:level_path]
      level_string = "#{level_path.join('.')}. "
      level_string_width = measure_text_width(level_string, toc_item_index_style)
      title = get_column_value work_package, :subject
      page_nr_string = (id_wp_meta_map[work_package.id][:page_number] || '000').to_s
      page_nr_string_width = measure_text_width(page_nr_string, toc_item_page_nr_font_style)
      { id: work_package.id, level_string:, level_string_width:, title:, page_nr_string:, page_nr_string_width: }
    end
  end

  def write_part_float(part, indent_left, indent_right, style)
    height = 0
    pdf.float do
      pdf.indent(indent_left, indent_right) do
        pdf.text(part, style.merge({ inline_format: true }))
      end
    end
    height
  end

  def write_toc!(toc_list)
    max_level_string_width = toc_list.pluck(:level_string_width).max
    toc_list.each do |toc_item|
      with_margin(toc_item_margins_style) do
        write_toc_item! toc_item, max_level_string_width
      end
    end
  end

  def write_toc_item!(toc_item, max_level_string_width)
    write_part_float(
      make_link_anchor(toc_item[:id], toc_item[:level_string]),
      0, 0, toc_item_index_style)
    write_part_float(
      make_link_anchor(toc_item[:id], toc_item[:page_nr_string]),
      0, 0, toc_item_page_nr_font_style.merge({ align: :right }))
    pdf.indent(
      max_level_string_width + toc_item_subject_indent_style,
      toc_item[:page_nr_string_width] + toc_item_subject_indent_style
    ) do
      pdf.formatted_text([toc_item_subject_font_style.merge({ text: toc_item[:title] })])
    end
  end

end

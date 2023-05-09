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
      build_toc_data_list_entry work_package, id_wp_meta_map
    end
  end

  def build_toc_data_list_entry(work_package, id_wp_meta_map)
    level_path = id_wp_meta_map[work_package.id][:level_path]
    level = level_path.length
    style = toc_item_style(level)
    level_string = "#{level_path.join('.')}. "
    level_string_width = measure_part_width(level_string, style)
    title = get_column_value work_package, :subject
    page_nr_string = (id_wp_meta_map[work_package.id][:page_number] || '000').to_s
    page_nr_string_width = measure_part_width(page_nr_string, style)
    { id: work_package.id, level_string:, level_string_width:, title:, page_nr_string:, page_nr_string_width:, level: }
  end

  def measure_part_width(part, style)
    measure_text_width(part, style) + toc_item_subject_indent_style
  end

  def write_part_float(id, part, style)
    text = make_link_anchor(id, part)
    pdf.float do
      pdf.text(text, style.merge({ inline_format: true }))
    end
  end

  def write_toc!(toc_list)
    max_level_string_width = toc_list.pluck(:level_string_width).max
    toc_list.each do |toc_item|
      with_margin(toc_item_margins_style(toc_item[:level])) do
        write_toc_item! toc_item, max_level_string_width
      end
    end
  end

  def write_toc_item!(toc_item, max_level_width)
    style = toc_item_style(toc_item[:level])
    write_part_float(toc_item[:id], toc_item[:level_string], style)
    write_part_float(toc_item[:id], toc_item[:page_nr_string], style.merge({ align: :right }))
    style[:styles] = [style[:style]] if style[:style]
    pdf.indent(max_level_width, toc_item[:page_nr_string_width]) do
      pdf.formatted_text([style.merge({ text: toc_item[:title] })])
    end
  end
end

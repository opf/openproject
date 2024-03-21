#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
    level = [level_path.length, styles.toc_max_depth].min
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

  def write_part_float(indent, part, part_style)
    pdf.float do
      pdf.indent(indent) do
        pdf.text(part, part_style)
      end
    end
  end

  def write_toc!(toc_list)
    levels_indent_list = toc_indent_list(toc_list)
    toc_list.each do |toc_item|
      with_margin(styles.toc_item_margins(toc_item[:level])) do
        write_toc_item! toc_item, levels_indent_list
      end
    end
  end

  def write_toc_item_subject!(toc_item, indent, subject_style)
    pdf.indent(indent, toc_item[:page_nr_string_width]) do
      pdf.formatted_text([subject_style.merge({ text: toc_item[:title] })])
    end
  end

  def toc_indent_list_flat(levels, level_max_widths)
    levels_max_width = level_max_widths.max
    levels.map do |_|
      { level_indent: 0, subject_index: levels_max_width }
    end
  end

  def toc_indent_list_stairs(levels, level_max_widths)
    indent_list = []
    levels.each do |level|
      level_indent = level <= 1 ? 0 : indent_list.last[:subject_index]
      subject_index = level_indent + level_max_widths[level - 1]
      indent_list.push({ level_indent:, subject_index: })
    end
    indent_list
  end

  def toc_indent_list_third_level(levels, level_max_widths)
    indent_list = []
    first_section = level_max_widths[0..1].max || 0
    second_section = level_max_widths[2..].max || 0
    levels.each do |level|
      if level < 3
        indent_list.push({ level_indent: 0, subject_index: first_section })
      else
        indent_list.push({ level_indent: first_section, subject_index: first_section + second_section })
      end
    end
    indent_list
  end

  def toc_indent_list(toc_list)
    levels = toc_list.pluck(:level).uniq.sort
    level_max_widths = levels.map do |level|
      toc_list.select { |item| item[:level] == level }.pluck(:level_string_width).max
    end
    mode = (styles.toc_indent_mode || :flat).to_sym
    case mode
    when :stairs
      toc_indent_list_stairs(levels, level_max_widths)
    when :third_level
      toc_indent_list_third_level(levels, level_max_widths)
    else
      toc_indent_list_flat(levels, level_max_widths)
    end
  end

  def build_toc_item_styles(toc_item)
    toc_item_style = styles.toc_item(toc_item[:level])
    part_style = toc_item_style.clone
    font_styles = part_style.delete(:styles) || []
    part_style[:style] = font_styles[0] unless font_styles.empty?
    [part_style, toc_item_style]
  end

  def write_toc_item!(toc_item, levels_indent_list)
    y_start_position = pdf.y
    part_style, toc_item_style = build_toc_item_styles(toc_item)
    indent = levels_indent_list[toc_item[:level] - 1]

    write_part_float(indent[:level_indent], toc_item[:level_string], part_style)
    write_part_float(0, toc_item[:page_nr_string], part_style.merge({ align: :right }))
    write_toc_item_subject!(toc_item, indent[:subject_index], toc_item_style)
    write_toc_item_link(toc_item, y_start_position)
  end

  def write_toc_item_link(toc_item, y_start_position)
    rect = [pdf.bounds.absolute_right, pdf.y, pdf.bounds.absolute_left, y_start_position]
    pdf.link_annotation(rect, Border: [0, 0, 0], Dest: toc_item[:id].to_s)
  end
end

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

module WorkPackage::PDFExport::Cover
  def write_cover_page!
    write_cover_logo
    write_cover_hr
    write_cover_hero
    write_cover_footer
    pdf.start_new_page
  end

  def write_cover_hero
    max_width = pdf.bounds.width - styles.cover_hero_padding[:right_padding]
    float_top = write_background_image
    float_top -= write_hero_title(float_top, max_width) if project
    float_top -= write_hero_heading(float_top, max_width)
    write_hero_subheading(float_top, max_width) unless User.current.nil?
  end

  def available_title_height(current_y)
    current_y -
      styles.cover_hero_title_max_height -
      styles.cover_hero_title_spacing -
      styles.cover_hero_heading_spacing -
      styles.cover_hero_subheading_max_height
  end

  def write_cover_hr
    hr_style = styles.cover_header_border
    draw_horizontal_line(
      pdf.bounds.height - hr_style[:offset],
      pdf.bounds.left, pdf.bounds.right,
      hr_style[:height], hr_style[:color]
    )
  end

  def write_hero_title(top, width)
    text_style = styles.cover_hero_title
    formatted_text_box_measured(
      [text_style.merge({ text: project.name, size: nil, leading: nil })],
      size: text_style[:size], leading: text_style[:leading],
      at: [0, top], width:, height: styles.cover_hero_title_max_height, overflow: :shrink_to_fit
    ) + styles.cover_hero_title_spacing
  end

  def write_hero_heading(top, width)
    max_title_height = available_title_height(top)
    text_style = styles.cover_hero_heading
    formatted_text_box_measured(
      [text_style.merge({ text: heading, size: nil, leading: nil })],
      size: text_style[:size], leading: text_style[:leading],
      at: [0, top], width:, height: max_title_height, overflow: :shrink_to_fit
    ) + styles.cover_hero_heading_spacing
  end

  def write_hero_subheading(top, width)
    text_style = styles.cover_hero_subheading
    pdf.formatted_text_box(
      [text_style.merge({ text: User.current.name, size: nil, leading: nil })],
      size: text_style[:size], leading: text_style[:leading],
      at: [0, top], width:, height: styles.cover_hero_subheading_max_height, overflow: :shrink_to_fit
    )
  end

  def write_cover_footer
    draw_text_multiline_left(
      text: footer_date,
      max_left: pdf.bounds.width / 2,
      max_lines: 1,
      top: pdf.bounds.bottom - styles.cover_footer_offset,
      text_style: styles.cover_footer
    )
  end

  def write_cover_logo
    image_obj, image_info = logo_image
    height = styles.cover_header_logo_height
    scale = [height / image_info.height.to_f, 1].min
    pdf.embed_image image_obj, image_info, { at: [0, pdf.bounds.top + height], scale: }
    image_info.width.to_f * scale
  end

  def cover_background_image
    image_file = Rails.root.join("app/assets/images/pdf/cover.png")
    image_obj, image_info = pdf.build_image_object(image_file)
    scale = pdf.bounds.width / image_info.width.to_f
    height = image_info.height.to_f * scale
    image_opts = { at: [0, height], scale: }
    [image_obj, image_info, image_opts, height]
  end

  def write_background_image
    height = pdf.bounds.height / 2
    pdf.canvas do
      image_obj, image_info, image_opts, height = cover_background_image
      pdf.embed_image image_obj, image_info, image_opts
    end
    height - styles.cover_hero_padding[:top_padding]
  end
end

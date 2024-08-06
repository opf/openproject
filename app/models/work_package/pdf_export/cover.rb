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

  def cover_text_color
    @cover_text_color ||= validate_cover_text_color
  end

  def validate_cover_text_color
    return nil if CustomStyle.current.blank?

    hexcode = CustomStyle.current.export_cover_text_color
    return nil if hexcode.blank?

    color = Color.new({ hexcode: })
    color.normalize_hexcode
    return nil if color.hexcode.blank?

    # pdf hex colors are defined without leading hash
    color.hexcode.sub("#", "")
  end

  def write_hero_title(top, width)
    write_hero_text(
      top:, width:,
      text: project.name,
      text_style: styles.cover_hero_title,
      height: styles.cover_hero_title_max_height
    ) + styles.cover_hero_title_spacing
  end

  def write_hero_heading(top, width)
    write_hero_text(
      top:, width:,
      text: heading,
      text_style: styles.cover_hero_heading,
      height: available_title_height(top)
    ) + styles.cover_hero_heading_spacing
  end

  def write_hero_subheading(top, width)
    write_hero_text(
      top:, width:,
      text: User.current.name,
      text_style: styles.cover_hero_subheading,
      height: styles.cover_hero_subheading_max_height
    )
  end

  def write_hero_text(top:, width:, text:, text_style:, height:)
    formatted_text = text_style.merge({ text:, size: nil, leading: nil })
    formatted_text[:color] = cover_text_color if cover_text_color.present?
    formatted_text_box_measured(
      [formatted_text],
      size: text_style[:size], leading: text_style[:leading],
      at: [0, top], width:, height:, overflow: :shrink_to_fit
    )
  end

  def write_cover_footer
    text_style = styles.cover_footer
    text_style[:color] = cover_text_color if cover_text_color.present?
    draw_text_multiline_left(
      text: footer_date,
      max_left: pdf.bounds.width / 2,
      max_lines: 1,
      top: pdf.bounds.bottom - styles.cover_footer_offset,
      text_style:
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
    image_file = custom_cover_image
    image_file = Rails.root.join("app/assets/images/pdf/cover.png") if image_file.nil?
    image_obj, image_info = pdf.build_image_object(image_file)
    scale = pdf.bounds.width / image_info.width.to_f
    height = image_info.height.to_f * scale
    image_opts = { at: [0, height], scale: }
    [image_obj, image_info, image_opts, height]
  end

  def custom_cover_image
    return unless CustomStyle.current.present? &&
      CustomStyle.current.export_cover.present? && CustomStyle.current.export_cover.local_file.present?

    image_file = CustomStyle.current.export_cover.local_file.path
    content_type = OpenProject::ContentTypeDetector.new(image_file).detect
    return unless pdf_embeddable?(content_type)

    image_file
  end

  def write_background_image
    half = pdf.bounds.height / 2
    height = half
    pdf.canvas do
      image_obj, image_info, image_opts, height = cover_background_image
      pdf.embed_image image_obj, image_info, image_opts
    end
    height.clamp(half, pdf.bounds.height) - styles.cover_hero_padding[:top_padding]
  end
end

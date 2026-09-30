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

module Exports::PDF::Components::Page
  MAX_NR_OF_PDF_HEADER_LINES = 3
  MAX_NR_OF_PDF_FOOTER_LINES = 3

  def configure_page_size!(layout)
    pdf.options[:page_layout] = layout
    pdf.options[:page_size] = options[:paper_size] || styles.page_size
    pdf.options[:top_margin] = styles.page_margin_top
    pdf.options[:left_margin] = styles.page_margin_left
    pdf.options[:bottom_margin] = styles.page_margin_bottom
    pdf.options[:right_margin] = styles.page_margin_right
  end

  def write_logo!
    image_obj, image_info, scale = logo_pdf_image
    top = logo_pdf_top
    left = logo_pdf_left(image_info.width.to_f * scale)
    pdf.repeat lambda { |pg| header_footer_filter_pages.exclude?(pg) } do
      pdf.embed_image image_obj, image_info, { at: [left, top], scale: }
    end
  end

  def logo_pdf_left(logo_width)
    case styles.page_logo_align.to_sym
    when :center
      (pdf.bounds.right - pdf.bounds.left - logo_width) / 2
    when :right
      pdf.bounds.right - logo_width
    else
      0 # :left
    end
  end

  def logo_pdf_top
    pdf.bounds.top + styles.page_header_offset + styles.page_logo_offset + (styles.page_logo_height / 2)
  end

  def logo_pdf_image
    image_obj, image_info = logo_image
    scale = [styles.page_logo_height / image_info.height.to_f, 1].min
    [image_obj, image_info, scale]
  end

  def write_title!
    pdf.title = heading
    with_margin(styles.page_heading_margins) do
      style = styles.page_heading
      pdf.formatted_text([style.merge({ text: heading })], style)
    end
  end

  def write_headers!
    write_logo!
  end

  def header_footer_filter_pages
    with_cover? ? [1] : []
  end

  def write_footers!
    pdf.repeat lambda { |pg| header_footer_filter_pages.exclude?(pg) }, dynamic: true do
      draw_footer_on_page
      draw_footer_image
    end
  end

  def custom_footer_image
    return unless CustomStyle.current.present? &&
                  CustomStyle.current.export_footer.present? && CustomStyle.current.export_footer.local_file.present?

    image_file = CustomStyle.current.export_footer.local_file.path
    content_type = OpenProject::ContentTypeDetector.detect(image_file)
    return unless pdf_embeddable?(content_type)

    image_file
  end

  def draw_footer_image
    footer_image = custom_footer_image
    height = styles.page_footer[:size] || 0
    return if footer_image.nil? || height <= 0

    image_obj, image_info = pdf.build_image_object(footer_image)
    pdf.embed_image(image_obj, image_info, footer_image_embed_options(image_info, height))
  end

  def footer_image_embed_options(image_info, height)
    scale = height / image_info.height.to_f
    width = image_info.width.to_f * scale
    {
      at: [pdf.bounds.left - width - height, styles.page_footer_offset + height - 1],
      height:,
      scale:,
      position: :right,
      vposition: :bottom
    }
  end

  def draw_footer_on_page
    top = styles.page_footer_offset
    text_style = styles.page_footer
    right_width = footer_page_nr.present? ? draw_text_right(footer_page_nr, text_style, top) : 0
    left_width = footer_date.present? ? draw_text_left(footer_date, text_style, top) : 0
    draw_footer_title(left_width, right_width, text_style, top) if footer_title.present?
  end

  def draw_footer_title(left_width, right_width, text_style, top)
    spacing = styles.page_footer_horizontal_spacing
    footer_sides = [left_width, right_width].max + spacing
    available_width = pdf.bounds.width - (2 * footer_sides)
    draw_text_multiline_center(
      text: footer_title,
      text_style:,
      left: footer_sides,
      available_width:,
      top:,
      max_lines: MAX_NR_OF_PDF_FOOTER_LINES
    )
  end

  def footer_page_nr
    current_page_nr.to_s + total_page_nr_text
  end

  def total_page_nr_text
    if @total_page_nr
      "/#{@total_page_nr - (with_cover? ? 1 : 0)}"
    else
      ""
    end
  end
end

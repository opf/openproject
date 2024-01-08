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

module WorkPackage::PDFExport::Page
  MAX_NR_OF_PDF_FOOTER_LINES = 3

  def configure_page_size!(layout)
    pdf.options[:page_layout] = layout
    pdf.options[:page_size] = styles.page_size
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
    pdf.bounds.top + styles.page_header_offset + (styles.page_logo_height / 2)
  end

  def logo_pdf_image
    image_obj, image_info = logo_image
    scale = [styles.page_logo_height / image_info.height.to_f, 1].min
    [image_obj, image_info, scale]
  end

  def logo_image
    image_file = custom_logo_image
    image_file = Rails.root.join("app/assets/images/logo_openproject.png") if image_file.nil?
    image_obj, image_info = pdf.build_image_object(image_file)
    [image_obj, image_info]
  end

  def custom_logo_image
    return unless CustomStyle.current.present? &&
      CustomStyle.current.export_logo.present? && CustomStyle.current.export_logo.local_file.present?

    image_file = CustomStyle.current.export_logo.local_file.path
    content_type = OpenProject::ContentTypeDetector.new(image_file).detect
    return unless pdf_embeddable?(content_type)

    image_file
  end

  def write_title!
    pdf.title = heading
    with_margin(styles.page_heading_margins) do
      pdf.formatted_text([styles.page_heading.merge({ text: heading })])
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
    end
  end

  def draw_footer_on_page
    top = styles.page_footer_offset
    text_style = styles.page_footer
    spacing = styles.page_footer_horizontal_spacing
    page_nr_x, page_nr_width = draw_text_centered(footer_page_nr, text_style, top)
    draw_text_multiline_left(
      text: footer_date, max_left: page_nr_x - spacing,
      text_style:, top:, max_lines: MAX_NR_OF_PDF_FOOTER_LINES
    )
    draw_text_multiline_right(
      text: footer_title, max_left: page_nr_x + page_nr_width + spacing,
      text_style:, top:, max_lines: MAX_NR_OF_PDF_FOOTER_LINES
    )
  end

  def footer_page_nr
    current_page_nr.to_s + total_page_nr_text
  end

  def footer_date
    format_time(Time.zone.now, true)
  end

  def total_page_nr_text
    if @total_page_nr
      "/#{@total_page_nr - (with_cover? ? 1 : 0)}"
    else
      ''
    end
  end
end

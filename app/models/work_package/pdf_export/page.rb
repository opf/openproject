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

module WorkPackage::PDFExport::Page
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
    pdf.repeat :all do
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
    image_file = custom_logo_image
    image_file = Rails.root.join("app/assets/images/logo_openproject.png") if image_file.nil?
    image_obj, image_info = pdf.build_image_object(image_file)
    scale = [styles.page_logo_height / image_info.height.to_f, 1].min
    [image_obj, image_info, scale]
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

  def write_footers!
    write_footer_date!
    write_footer_page_nr!
    write_footer_title!
  end

  def write_footer_page_nr!
    draw_repeating_dynamic_text(:center, styles.page_footer_offset, styles.page_footer) do
      current_page_nr.to_s + total_page_nr_text
    end
  end

  def total_page_nr_text
    @total_page_nr ? "/#{@total_page_nr}" : ''
  end

  def write_footer_title!
    draw_repeating_text(
      text: heading,
      align: :right,
      top: styles.page_footer_offset,
      text_style: styles.page_footer
    )
  end

  def write_footer_date!
    draw_repeating_text(
      text: format_time(Time.zone.now, true),
      align: :left,
      top: styles.page_footer_offset,
      text_style: styles.page_footer
    )
  end
end

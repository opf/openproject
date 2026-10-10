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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class WorkPackage::PDFExport::ZendisArtefact < WorkPackage::PDFExport::Artefact
  include Exports::PDF::Components::Cover

  def self.key
    :zendis_artefact_export_pdf
  end

  def styles
    @styles ||= Exports::PDF::ZendisArtefact::Styles::PDFStyles.new
  end

  def render_artefact
    write_cover_page!
    write_toc! if with_toc?
    write_artefact
    write_contact_page
    write_headers_footers
  end

  def write_cover_page!
    write_zendis_cover_image
    write_zendis_cover_logo
    write_zendis_cover_heading
    write_zendis_cover_subtitle
    pdf.formatted_text_box([cover_text_style(styles.cover_footer).merge(text: document_date)],
                           at: [0, 0], height: styles.layout[:cover_date_height])
    pdf.start_new_page
  end

  def heading
    @heading ||= "#{work_package.type} #{work_package.display_id}"
  end

  def document_date
    I18n.t("pdf_generator.template_zendis_artefact.document_date", date: format_date(work_package.updated_at))
  end

  def footer_date
    document_date
  end

  def footer_title
    nil
  end

  def current_page_nr
    pdf.page_number + @page_count
  end

  def total_page_nr_text
    @total_page_nr ? " / #{@total_page_nr}" : ""
  end

  def write_headers_footers
    write_running_headers if pdf.page_count > 1
    write_footers!
  end

  def write_section_title(text)
    with_margin(styles.section_title_margins) do
      pdf.table([[text]], cell_style: styles.section_title_cell)
    end
  end

  def build_toc_entries
    entries = super
    entries << toc_entry("contact", address_custom_value.custom_field.name) if address_custom_value&.value.present?
    entries
  end

  def show_attribute?(form_key, package)
    return false if package == work_package &&
      form_key.to_s == "custom_field_#{address_field_id}"

    super
  end

  private

  def write_zendis_cover_heading
    pdf.move_cursor_to(pdf.bounds.height * styles.layout[:cover_heading_position])
    pdf.formatted_text([cover_text_style(styles.cover_heading).merge(text: heading)])
    write_zendis_cover_heading_rule
  end

  def write_zendis_cover_heading_rule
    pdf.move_down(styles.cover_heading_margin[:bottom_margin])
    rule = styles.section_title_hr
    write_horizontal_line(pdf.cursor, rule[:height], rule[:color])
  end

  def write_zendis_cover_subtitle
    pdf.move_down(styles.cover_title_margin[:top_margin])
    pdf.formatted_text([cover_text_style(styles.cover_title).merge(text: work_package.subject)])
  end

  def write_running_headers
    pdf.repeat(2..pdf.page_count) { draw_zendis_header }
  end

  def draw_zendis_header
    write_zendis_header_text(heading, styles.page_header, styles.layout[:header_heading_offset])
    write_zendis_header_text(work_package.subject, styles.page_subheading, styles.layout[:header_subject_offset])
  end

  def write_zendis_header_text(text, text_style, offset)
    text_options = { height: styles.layout[:header_height], overflow: :shrink_to_fit }
    pdf.formatted_text_box([text_style.merge(text:)], **text_options, at: [0, pdf.bounds.top + offset])
  end

  def write_toc_item_title!(title, page_nr_width, style)
    available_width = pdf.bounds.width - page_nr_width - styles.layout[:toc_page_number_spacing]
    dots = [(available_width - measure_text_width(title, style)) / measure_text_width(".", style), 0].max.floor
    super("#{title}#{'.' * dots}", page_nr_width, style)
  end

  def address_field_id
    options[:address_custom_field_id].to_i
  end

  def address_custom_value
    work_package.custom_field_values.find do |custom_value|
      custom_value.custom_field.id == address_field_id &&
        %w[text string].include?(custom_value.custom_field.field_format)
    end
  end

  def write_contact_page
    custom_value = address_custom_value
    return if custom_value.nil? || custom_value.value.blank?

    pdf.start_new_page
    record_toc_page!("contact")
    write_section_title(custom_value.custom_field.name)
    write_markdown_field_value(work_package, custom_value.value)
  end

  def write_zendis_cover_logo
    image_obj, image_info = logo_image
    scale = zendis_logo_scale(image_info)
    pdf.embed_image(image_obj, image_info, at: zendis_logo_position(image_info, scale), scale:)
  end

  def zendis_logo_position(image_info, scale)
    [pdf.bounds.right - (image_info.width * scale), pdf.bounds.top - styles.layout[:logo_offset]]
  end

  def zendis_logo_scale(image_info)
    [styles.cover_header_logo_height / image_info.height.to_f,
     styles.layout[:logo_width] / image_info.width.to_f, 1].min
  end

  def cover_text_style(text_style)
    text_style[:color] = cover_text_color if cover_text_color.present?
    text_style
  end

  def write_zendis_cover_image
    image = custom_cover_image
    return if image.nil?

    layout = styles.layout
    pdf.image(image, at: [pdf.bounds.right - layout[:cover_image_width], layout[:cover_image_top]],
                     fit: [layout[:cover_image_width], layout[:cover_image_height]])
  end
end

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
  class PDFStyles < Exports::PDF::Artefact::Styles::PDFStyles
    def initialize(path)
      super
      @styles.deep_merge!(
        page: { margin_left: 57, margin_right: 57 },
        page_heading: { size: 24, color: "000000" },
        section: { title: { color: "00D7C3", size: 13 } },
        toc: { heading: { color: "000000" } }
      )
    end
  end

  def self.key
    :zendis_artefact_export_pdf
  end

  def styles
    @styles ||= PDFStyles.new(styles_asset_path)
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
    pdf.move_cursor_to(pdf.bounds.height * 0.60)
    pdf.formatted_text([{ text: heading, styles: [:bold] }], size: 24)
    pdf.move_down(6)
    write_horizontal_line(pdf.cursor, 1, "00D7C3")
    pdf.move_down(24)
    pdf.text(work_package.subject, size: 10)
    pdf.text_box(document_date, at: [0, 0], size: 8, height: 20)
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
    pdf.repeat(2..pdf.page_count) do
      pdf.text_box(heading, at: [0, pdf.bounds.top + 24], size: 8, style: :bold, height: 14, overflow: :shrink_to_fit)
      pdf.text_box(work_package.subject, at: [0, pdf.bounds.top + 12], size: 8, style: :italic, height: 14, overflow: :shrink_to_fit)
    end if pdf.page_count > 1
    write_footers!
  end

  def write_section_title(text)
    with_margin(styles.section_title_margins) do
      pdf.table([[text]], cell_style: {
        background_color: "000000", text_color: "00D7C3", font_style: :bold,
        size: styles.section_title[:size], padding: [1, 2], borders: []
      })
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

  def write_toc_item_title!(title, page_nr_width, style)
    available_width = pdf.bounds.width - page_nr_width - 8
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
    scale = [70 / image_info.height.to_f, 140 / image_info.width.to_f, 1].min
    pdf.embed_image(image_obj, image_info, at: [pdf.bounds.right - image_info.width * scale, pdf.bounds.top - 30], scale:)
  end

  def zendis_cover_image
    style = CustomStyle.current
    return unless style&.export_cover&.local_file.present?

    image = style.export_cover.local_file.path
    image if pdf_embeddable?(OpenProject::ContentTypeDetector.new(image).detect)
  rescue StandardError => e
    Rails.logger.error "Failed to access custom PDF cover file: #{e}"
    nil
  end

  def write_zendis_cover_image
    image = zendis_cover_image
    return if image.nil?

    pdf.image(image, at: [pdf.bounds.right - 300, 300], fit: [300, 260])
  end
end

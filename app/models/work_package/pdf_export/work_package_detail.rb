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

module WorkPackage::PDFExport::WorkPackageDetail
  def write_work_packages_details!(work_packages, id_wp_meta_map)
    work_packages.each do |work_package|
      write_detail!(work_package, id_wp_meta_map[work_package.id][:level_path])
    end
  end

  private

  def write_detail!(work_package, level_path)
    # TODO: move page break threshold const to style settings and implement conditional break with height measuring
    write_optional_page_break(200)
    with_margin(work_package_detail_margins_style) do
      write_work_package_subject! work_package, level_path
      write_attributes_table! work_package
      write_description! work_package
    end
  end

  def write_work_package_subject!(work_package, level_path)
    with_margin(work_package_subject_margins_style) do
      pdf_dest = pdf.dest_xyz(0, pdf.y)
      pdf.add_dest(work_package.id.to_s, pdf_dest)
      title = get_column_value work_package, :subject
      opts = { text: "#{level_path.join('.')}.  #{title}" }
      pdf.formatted_text([work_package_subject_style.merge(opts)])
    end
  end

  def write_attributes_table!(work_package)
    rows = build_attributes_table_rows work_package
    with_margin(attributes_table_margins_style) do
      pdf.table(
        rows, column_widths: attributes_table_column_widths,
              cell_style: attributes_table_cell_style.merge({ inline_format: true })
      )
    end
  end

  def attributes_table_column_widths
    # calculate fixed work package attribute table columns width
    widths = [1.5, 2.0, 1.5, 2.0] # label | value | label | value
    ratio = pdf.bounds.width / widths.sum
    widths.map { |w| w * ratio }
  end

  def build_attributes_table_rows(work_package)
    # get work package attribute table rows data [[label, value, label, value]]
    attrs = %i[
      id
      updated_at
      type
      created_at
      status
      due_date
      version
      priority
      duration
      work
      category
      assigned_to
    ]
    0.step(attrs.length - 1, 2).map do |i|
      build_attributes_table_cells(attrs[i], work_package) +
        build_attributes_table_cells(attrs[i + 1], work_package)
    end
  end

  def build_attributes_table_cells(attribute, work_package)
    # get work package attribute table cell data: [label, value]
    return ['', ''] if attribute.nil?

    label = (WorkPackage.human_attribute_name(attribute) || '').upcase
    [
      pdf.make_cell(label, attributes_table_label_font_style),
      get_column_value_cell(work_package, attribute.to_sym)
    ]
  end

  def write_description!(work_package)
    return if work_package.description.blank?

    # TODO: move page break threshold const to style settings and implement conditional break with height measuring
    write_optional_page_break(100)
    write_description_label!
    write_description_content! work_package
  end

  def write_description_label!
    label = WorkPackage.human_attribute_name(:description)
    with_margin(description_header_margins_style) do
      pdf.formatted_text([description_header_style.merge({ text: label })])
    end
  end

  def write_description_content!(work_package)
    configure_markup work_package
    markup = format_text(work_package.description, object: work_package, format: :html)
               .gsub('class="op-uc-image"', 'style="width:100"') # TODO: this is a workaround image formatting
    pdf.markup markup
  end

  def configure_markup(work_package)
    # configure prawn markup gem in context of our work package
    images_enabled = options[:show_attachments] && work_package.attachments.exists?
    pdf.markup_options = work_package_detail_markup_options_style.merge(
      {
        image: {
          loader: ->(src) {
            images_enabled ? attachment_image_filepath(work_package, src) : nil
          },
          placeholder: "<i>[#{I18n.t('export.image.omitted')}]</i>"
        }
      }
    )
  end

  def attachment_image_filepath(work_package, src)
    # images are embedded into markup with the api-path as img.src
    attachment = attachment_by_api_content_src(work_package, src)
    return nil if attachment.nil? || !pdf_embeddable?(attachment)

    resize_image(attachment.file.local_file.path)
  end

  def attachment_by_api_content_src(work_package, src)
    # find attachment by api-path
    work_package.attachments.detect { |a| api_url_helpers.attachment_content(a.id) == src }
  end

  def work_package_detail_markup_options_style
    { text: work_package_detail_font_style,
      heading1: work_package_detail_h1_style,
      heading2: work_package_detail_h2_style,
      heading3: work_package_detail_h3_style,
      heading4: work_package_detail_h4_style,
      heading5: work_package_detail_h5_style,
      heading6: work_package_detail_h6_style }
  end

  def work_package_detail_h1_style
    { size: 10, styles: [:bold] }
  end

  def work_package_detail_h2_style
    { size: 10, styles: [:bold] }
  end

  def work_package_detail_h3_style
    { size: 9, styles: [:bold] }
  end

  def work_package_detail_h4_style
    { size: 8, styles: [:bold] }
  end

  def work_package_detail_h5_style
    { size: 8, styles: [:bold] }
  end

  def work_package_detail_h6_style
    { size: 10, styles: [:bold] }
  end

  def work_package_detail_margins_style
    { margin_top: 20 }
  end

  def work_package_detail_font_style
    { style: :normal, size: 9 }
  end

  def work_package_subject_margins_style
    {}
  end

  def work_package_subject_style
    { size: 14, styles: [:bold] }
  end

  def attributes_table_margins_style
    { margin_top: 4, margin_bottom: 2 }
  end

  def attributes_table_label_font_style
    { font_style: :bold }
  end

  def attributes_table_cell_style
    { size: 9,
      text_color: "000000",
      border_widths: [0.25, 0.25, 0.25, 0.25],
      padding_left: 5,
      padding_right: 5,
      padding_top: 0,
      padding_bottom: 4 }
  end

  def description_header_margins_style
    { margin_top: 8, margin_bottom: 4 }
  end

  def description_header_style
    { size: 11, styles: [:bold] }
  end
end

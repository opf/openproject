#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

# Exporter for work package table.
#
# It can optionally export a work package with
# - description, or with
# - attached images, or with
# - description and attached images.
#
# When exporting with attached images then the memory consumption can quickly
# grow beyond limits. Therefore we create multiple smaller PDFs that we finally
# merge do one file.

require 'mini_magick'
require 'open3'

class WorkPackage::PDFExport::WorkPackageListToPdf < WorkPackage::Exporter::Base
  include WorkPackage::PDFExport::Common
  include WorkPackage::PDFExport::Attachments

  attr_accessor :pdf,
                :options

  WORK_PACKAGES_PER_BATCH = 100

  def initialize(object, options = {})
    super

    @cell_padding = options.delete(:cell_padding)

    @total_wp_count = query.results.work_package_count
    @batches_count = @total_wp_count.fdiv(WORK_PACKAGES_PER_BATCH).ceil
    @batch_files = []
    @page_count = -1
  end

  def render!
    (1..@batches_count).each do |batch_index|
      run_batch!(batch_index)
    end

    @merged_pdf_file = merge_pdfs

    delete_tmp_files

    success(@merged_pdf_file)
  rescue Prawn::Errors::CannotFit
    error(I18n.t(:error_pdf_export_too_many_columns))
  rescue StandardError => e
    Rails.logger.error { "Failed to generated PDF export: #{e} #{e.message}." }
    error(I18n.t(:error_pdf_failed_to_export, error: e.message))
  end

  private

  def on_first_batch(batch_index)
    return unless batch_index == 1

    write_title!
    write_headers!
  end

  def delete_tmp_files
    @batch_files.each(&:delete)
  end

  def configure_page_size
    pdf.options[:page_size] = 'EXECUTIVE'
    pdf.options[:page_layout] = :landscape
  end

  def merge_pdfs
    merged_pdf = Tempfile.new
    # We use the command line tool "pdfunite" for concatenating the PDFs.
    # That tool comes with the system package "poppler-utils" which we
    # fortunately already have installed for text extraction purposes.
    Open3.capture2e("pdfunite", *@batch_files.map(&:path), merged_pdf.path)

    merged_pdf
  end

  def run_batch!(batch_index)
    initialize_batch_page

    batch_file = render_batch!(batch_index)

    @page_count += pdf.page_count
    batch_file.close
    @batch_files << batch_file
  end

  def render_batch!(batch_index)
    @resized_image_paths = []

    on_first_batch(batch_index)
    write_work_packages!(batch_index)
    write_footers!

    batch_file = Tempfile.new("pdf_batch_#{batch_index}")
    pdf.render_file(batch_file.path)

    delete_all_resized_images

    batch_file
  end

  def project
    query.project
  end

  def write_title!
    pdf.title = heading
    pdf.font style: :bold, size: 11
    pdf.text heading
    pdf.move_down 20
  end

  def title
    "#{heading}.pdf"
  end

  def heading
    title = query.new_record? ? I18n.t(:label_work_package_plural) : query.name

    if project
      "#{project} - #{title}"
    else
      title
    end
  end

  def write_footers!
    @page_count += 1
    pdf.number_pages format_date(Date.today),
                     at: [pdf.bounds.left, 0],
                     style: :italic

    pdf.number_pages "<page>",
                     start_count_at: @page_count,
                     at: [pdf.bounds.right - 25, 0],
                     style: :italic
  end

  def column_widths
    widths = valid_export_columns.map do |col|
      if col.name == :subject || text_column?(col)
        4.0
      else
        1.0
      end
    end
    ratio = pdf.bounds.width / widths.sum

    widths.map { |w| w * ratio }
  end

  def description_colspan
    valid_export_columns.size
  end

  def text_column?(column)
    column.is_a?(Queries::WorkPackages::Columns::CustomFieldColumn) &&
      %w(string text).include?(column.custom_field.field_format)
  end

  def write_headers!
    pdf.font style: :normal, size: 8
    pdf.table([data_headers], column_widths: column_widths)
  end

  def data_headers
    valid_export_columns.map(&:caption).map do |caption|
      pdf.make_cell caption, font_style: :bold, background_color: 'CCCCCC'
    end
  end

  def write_work_packages!(batch_index)
    pdf.font style: :normal, size: 8
    previous_group = nil

    work_packages_batch(batch_index).each do |work_package|
      previous_group = write_group_header!(work_package, previous_group)

      write_attributes!(work_package)

      if options[:show_descriptions]
        write_description!(work_package, false)
      end

      if options[:show_attachments] && work_package.attachments.exists?
        write_attachments!(work_package)
      end
    end
  end

  def work_packages_batch(batch_index)
    query
        .results
        .work_packages
        .page(batch_index)
        .per_page(WORK_PACKAGES_PER_BATCH)
  end

  def write_attributes!(work_package)
    values = valid_export_columns.map do |column|
      make_column_value work_package, column
    end

    pdf.table([values], column_widths: column_widths)
  end

  def write_attachments!(work_package)
    attachments = make_attachments_cells(work_package.attachments)

    pdf.table([attachments], width: pdf.bounds.width) if attachments.any?
  end

  def write_group_header!(work_package, previous_group)
    if query.grouped? && (group = query.group_by_column.value(work_package)) != previous_group
      label = make_group_label(group)
      group_cell = pdf.make_cell(label,
                                 font_style: :bold,
                                 colspan: valid_export_columns.size,
                                 background_color: 'DDDDDD')

      pdf.table([[group_cell]], column_widths: column_widths)

      group
    else
      previous_group
    end
  end

  def make_column_value(work_package, column)
    if column.is_a?(Queries::WorkPackages::Columns::CustomFieldColumn)
      make_custom_field_value work_package, column
    else
      make_field_value work_package, column.name
    end
  end

  def make_field_value(work_package, column_name)
    pdf.make_cell field_value(work_package, column_name),
                  padding: cell_padding
  end

  def make_group_label(group)
    if group.blank?
      I18n.t(:label_none_parentheses)
    elsif group.is_a? Array
      group.join(', ')
    else
      group.to_s
    end
  end

  def make_custom_field_value(work_package, column)
    values = work_package
             .custom_values
             .select { |v| v.custom_field_id == column.custom_field.id }

    pdf.make_cell values.map(&:formatted_value).join(', '),
                  padding: cell_padding
  end

  def initialize_batch_page
    self.pdf = get_pdf(current_language)

    configure_page_size
    configure_markup
  end
end

#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class WorkPackage::PdfExport::WorkPackageListToPdf < WorkPackage::Exporter::Base
  include WorkPackage::PdfExport::Common
  include WorkPackage::PdfExport::Attachments

  attr_accessor :pdf,
                :options

  def initialize(object, options = {})
    super

    @cell_padding = options.delete(:cell_padding)

    self.pdf = get_pdf(current_language)

    pdf.options[:page_size] = 'EXECUTIVE'
    pdf.options[:page_layout] = :landscape
  end

  def render!
    write_title!
    write_work_packages!

    write_footers!

    success(pdf.render)
  rescue Prawn::Errors::CannotFit
    error(I18n.t(:error_pdf_export_too_many_columns))
  rescue StandardError => e
    Rails.logger.error { "Failed to generated PDF export: #{e} #{e.message}." }
    error(I18n.t(:error_pdf_failed_to_export, error: e.message))
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
    pdf.number_pages format_date(Date.today),
                     at: [pdf.bounds.left, 0],
                     style: :italic

    pdf.number_pages "<page>/<total>",
                     at: [pdf.bounds.right - 25, 0],
                     style: :italic
  end

  def write_work_packages!
    pdf.font style: :normal, size: 8
    pdf.table(data, column_widths: column_widths)
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
      ['string', 'text'].include?(column.custom_field.field_format)
  end

  def data
    [data_headers] + data_rows
  end

  def data_headers
    valid_export_columns.map(&:caption).map do |caption|
      pdf.make_cell caption, font_style: :bold, background_color: 'CCCCCC'
    end
  end

  def data_rows
    previous_group = nil

    work_packages.flat_map do |work_package|
      values = valid_export_columns.map do |column|
        make_column_value work_package, column
      end

      result = [values]

      if options[:show_descriptions]
        make_description(work_package.description.to_s).each do |segment|
          result << [segment]
        end
      end

      if options[:show_attachments] && work_package.attachments.exists?
        attachments = make_attachments_cells(work_package.attachments)

        result << [
          { content: pdf.make_table([attachments]), colspan: description_colspan }
        ]
      end

      if query.grouped? && (group = query.group_by_column.value(work_package)) != previous_group
        label = make_group_label(group)
        previous_group = group

        result.insert 0, [
          pdf.make_cell(label, font_style: :bold,
                               colspan: valid_export_columns.size,
                               background_color: 'DDDDDD')
        ]
      end

      result
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
end

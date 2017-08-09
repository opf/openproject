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

class WorkPackage::Exporter::CSV < WorkPackage::Exporter::Base
  include Redmine::I18n
  include CustomFieldsHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper

  def list
    serialized = CSV.generate(col_sep: l(:general_csv_separator)) do |csv|
      headers = csv_headers
      csv << self.class.encode_csv_columns(headers)

      work_packages.each do |work_package|
        row = csv_row(work_package)
        csv << self.class.encode_csv_columns(row)
      end
    end

    success(serialized)
  end

  def self.encode_csv_columns(columns, encoding = l(:general_csv_encoding))
    columns.map do |cell|
      Redmine::CodesetUtil.from_utf8(cell.to_s, encoding)
    end
  end

  private

  def success(serialized)
    WorkPackage::Exporter::Success
      .new format: :csv,
           title: title,
           content: serialized,
           mime_type: 'text/csv'
  end

  def title
    title = query.new_record? ? l(:label_work_package_plural) : query.name

    "#{title}.csv"
  end

  # fetch all headers
  def csv_headers
    headers = []

    valid_export_columns.each_with_index do |column, _|
      headers << column.caption
    end

    headers << CustomField.human_attribute_name(:description)

    # because of
    # https://support.microsoft.com/en-us/help/323626/-sylk-file-format-is-not-valid-error-message-when-you-open-file
    if headers[0].start_with?('ID')
      headers[0] = headers[0].downcase
    end

    headers
  end

  # fetch all row values
  def csv_row(work_package)
    row = valid_export_columns.collect do |column|
      csv_format_value(work_package, column)
    end

    if !row.empty?

      row << if work_package.description
               work_package.description.squish
             else
               ''
             end
    end

    row
  end

  def csv_format_value(work_package, column)
    if column.is_a?(Queries::WorkPackages::Columns::CustomFieldColumn)
      csv_format_custom_value(work_package, column)
    else
      value = work_package.send(column.name)

      case value
      when Date
        format_date(value)
      when Time
        format_time(value)
      else
        value
      end
    end.to_s
  end

  def csv_format_custom_value(work_package, column)
    cv = work_package
         .custom_values
         .select { |v| v.custom_field_id == column.custom_field.id }

    cv
      .map { |v| show_value(v) }
      .join('; ')
  end
end

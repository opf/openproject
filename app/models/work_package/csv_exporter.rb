#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module WorkPackage::CsvExporter
  include Redmine::I18n
  include CustomFieldsHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper

  def csv(work_packages, query)
    export = CSV.generate(col_sep: l(:general_csv_separator)) do |csv|
      headers = csv_headers(query)
      csv << encode_csv_columns(headers)

      work_packages.each do |work_package|
        row = csv_row(work_package, query)
        csv << encode_csv_columns(row)
      end
    end

    export
  end

  def encode_csv_columns(columns, encoding = l(:general_csv_encoding))
    columns.map do |cell|
      Redmine::CodesetUtil.from_utf8(cell.to_s, encoding)
    end
  end

  private

  # fetch all headers
  def csv_headers(query)
    headers = []

    query.columns.each_with_index do |column, _|
      headers << column.caption
    end

    headers << CustomField.human_attribute_name(:description)

    headers
  end

  # fetch all row values
  def csv_row(work_package, query)
    row = query.columns.collect do |column|
      csv_format_value(work_package, column)
    end

    if row.size > 0

      if work_package.description
        row << work_package.description.gsub(/\r/, '').gsub(/\n/, ' ')
      else
        row << ''
      end
    end

    row
  end

  def csv_format_value(work_package, column)
    if column.is_a?(QueryCustomFieldColumn)
      cv = work_package.custom_values.detect { |v| v.custom_field_id == column.custom_field.id }
      show_value(cv)
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
end

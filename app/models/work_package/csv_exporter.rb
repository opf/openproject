#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

  def csv(work_packages, project = nil, query)
    decimal_separator = l(:general_csv_decimal_separator)
    title = query.new_record? ? l(:label_work_package_plural) : query.name
    export = CSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      headers = []
      # csv header fields
      headers << '#'

      query.columns.each_with_index do |column, _|
        headers << column.caption
      end

      headers << CustomField.human_attribute_name(:description)
      csv << encode_csv_columns(headers)
      # csv lines

      # fetch all the row values
      work_packages.each do |work_package|
        col_values = query.columns.collect do |column|
          s = if column.is_a?(QueryCustomFieldColumn)
                cv = work_package.custom_values.detect { |v| v.custom_field_id == column.custom_field.id }
                show_value(cv)
              else
                value = work_package.send(column.name)

                if value.is_a?(Date)
                  format_date(value)
                elsif value.is_a?(Time)
                  format_time(value)
                else
                  value
                end
              end
          s.to_s
        end

        if col_values.size > 0
          col_values.unshift(work_package.id.to_s)
          col_values << work_package.description.gsub(/\r/, '').gsub(/\n/, ' ')
        end
        csv << encode_csv_columns(col_values)
      end
    end

    export
  end

  def encode_csv_columns(columns, encoding = l(:general_csv_encoding))
    columns.map do |cell|
      Redmine::CodesetUtil.from_utf8(cell.to_s, encoding)
    end
  end
end

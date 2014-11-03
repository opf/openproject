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

  def csv(work_packages, project = nil)
    decimal_separator = l(:general_csv_decimal_separator)

    export = CSV.generate(col_sep: l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [ "#",
                  WorkPackage.human_attribute_name(:status),
                  WorkPackage.human_attribute_name(:project),
                  WorkPackage.human_attribute_name(:type),
                  WorkPackage.human_attribute_name(:priority),
                  WorkPackage.human_attribute_name(:subject),
                  WorkPackage.human_attribute_name(:assigned_to),
                  WorkPackage.human_attribute_name(:category),
                  WorkPackage.human_attribute_name(:fixed_version),
                  WorkPackage.human_attribute_name(:author),
                  WorkPackage.human_attribute_name(:start_date),
                  WorkPackage.human_attribute_name(:due_date),
                  WorkPackage.human_attribute_name(:done_ratio),
                  WorkPackage.human_attribute_name(:estimated_hours),
                  WorkPackage.human_attribute_name(:parent_work_package),
                  WorkPackage.human_attribute_name(:created_at),
                  WorkPackage.human_attribute_name(:updated_at)
                  ]
      # Export project custom fields if project is given
      # otherwise export custom fields marked as "For all projects"
      custom_fields = project.nil? ? WorkPackageCustomField.for_all : project.all_work_package_custom_fields
      custom_fields.each {|f| headers << f.name}
      # Description in the last column
      headers << CustomField.human_attribute_name(:description)
      csv << encode_csv_columns(headers)
      # csv lines
      work_packages.each do |work_package|
        fields = [work_package.id,
                  work_package.status.name,
                  work_package.project.name,
                  work_package.type.name,
                  work_package.priority.name,
                  work_package.subject,
                  work_package.assigned_to,
                  work_package.category,
                  work_package.fixed_version,
                  work_package.author.name,
                  format_date(work_package.start_date),
                  format_date(work_package.due_date),
                  (Setting.work_package_done_ratio != 'disabled' ? work_package.done_ratio : ''),
                  work_package.estimated_hours.to_s.gsub('.', decimal_separator),
                  work_package.parent_id,
                  format_time(work_package.created_at),
                  format_time(work_package.updated_at)
                  ]
        custom_fields.each {|f| fields << show_value(work_package.custom_value_for(f)) }
        fields << work_package.description
        csv << encode_csv_columns(fields)
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

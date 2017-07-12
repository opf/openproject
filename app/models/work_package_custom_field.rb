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

class WorkPackageCustomField < CustomField
  has_and_belongs_to_many :projects,
                          join_table: "#{table_name_prefix}custom_fields_projects#{table_name_suffix}",
                          foreign_key: 'custom_field_id'
  has_and_belongs_to_many :types,
                          join_table: "#{table_name_prefix}custom_fields_types#{table_name_suffix}",
                          foreign_key: 'custom_field_id'
  has_many :work_packages,
           through: :work_package_custom_values

  scope :visible_by_user, ->(user) {
    if user.allowed_to_globally?(:edit_projects)
      all
    else
      where(projects: { id: Project.visible(user) })
        .where(types: { id: Type.enabled_in(Project.visible(user)) })
        .or(where(is_for_all: true).references(:projects, :types))
        .includes(:projects, :types)
    end
  }

  def self.summable
    ids = Setting.work_package_list_summable_columns.map do |column_name|
      if match = /cf_(\d+)/.match(column_name)
        match[1]
      end
    end.compact

    where(id: ids)
  end

  def type_name
    :label_work_package_plural
  end
end

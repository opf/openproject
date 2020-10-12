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

module Queries::WorkPackages::Filter::CustomFieldContext
  class << self
    def custom_field_class
      ::WorkPackageCustomField
    end

    def model
      ::WorkPackage
    end

    def custom_fields(context)
      if context&.project
        context.project.all_work_package_custom_fields
      else
        custom_field_class
          .filter
          .for_all
          .where
          .not(field_format: %w(user version))
      end
    end

    def where_subselect_joins(custom_field)
      cf_types_db_table = 'custom_fields_types'
      cf_projects_db_table = 'custom_fields_projects'
      cv_db_table = CustomValue.table_name
      work_package_db_table = WorkPackage.table_name

      joins = "LEFT OUTER JOIN #{cv_db_table}
                 ON #{cv_db_table}.customized_type='WorkPackage'
                 AND #{cv_db_table}.customized_id=#{work_package_db_table}.id
                 AND #{cv_db_table}.custom_field_id=#{custom_field.id}
               JOIN #{cf_types_db_table}
                 ON #{cf_types_db_table}.type_id =  #{work_package_db_table}.type_id
                 AND #{cf_types_db_table}.custom_field_id = #{custom_field.id}"

      unless custom_field.is_for_all
        joins += " JOIN #{cf_projects_db_table}
                     ON #{cf_projects_db_table}.project_id = #{work_package_db_table}.project_id
                     AND #{cf_projects_db_table}.custom_field_id = #{custom_field.id}"
      end

      joins
    end
  end
end

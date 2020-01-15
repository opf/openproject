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

module Queries::Projects::Filters::CustomFieldContext
  class << self
    def custom_field_class
      ::ProjectCustomField
    end

    def model
      ::Project
    end

    def custom_fields(_context)
      custom_field_class.visible
    end

    def where_subselect_joins(custom_field)
      cv_db_table = CustomValue.table_name
      project_db_table = Project.table_name

      "LEFT OUTER JOIN #{cv_db_table}
         ON #{cv_db_table}.customized_type='Project'
         AND #{cv_db_table}.customized_id=#{project_db_table}.id
         AND #{cv_db_table}.custom_field_id=#{custom_field.id}"
    end
  end
end

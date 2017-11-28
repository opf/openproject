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

class Queries::Projects::Filters::CustomFieldFilter <
  Queries::Projects::Filters::ProjectFilter

  include Queries::Filters::Shared::CustomFieldFilter

  self.custom_field_class = ProjectCustomField

  def allowed_values
    if custom_field.field_format == 'user'
      custom_field.possible_values_options(:of_all_projects)
    else
      super
    end
  end

  def type
    if custom_field && custom_field.field_format == 'float'
      :float
    else
      super
    end
  end

  def self.custom_fields(_context)
    custom_field_class
      .visible
  end

  private

  def strategies
    strategies = super
    strategies[:float] = Queries::Filters::Strategies::CfFloat

    strategies
  end

  def where_subselect_joins
    cv_db_table = CustomValue.table_name
    project_db_table = model.table_name

    "LEFT OUTER JOIN #{cv_db_table}
       ON #{cv_db_table}.customized_type='#{model.name}'
       AND #{cv_db_table}.customized_id=#{project_db_table}.id
       AND #{cv_db_table}.custom_field_id=#{custom_field.id}"
  end

  # compatibility only
  def project; end
end

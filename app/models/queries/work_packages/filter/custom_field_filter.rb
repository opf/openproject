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

class Queries::WorkPackages::Filter::CustomFieldFilter < Queries::WorkPackages::Filter::BaseFilter
  attr_accessor :field

  def initialize(field, project)
    self.field = field
    self.project = project
  end

  def values
    case field.field_format
    when 'list'
      field.possible_values
    when 'bool'
      [[I18n.t(:general_text_yes), ActiveRecord::Base.connection.unquoted_true],
       [I18n.t(:general_text_no), ActiveRecord::Base.connection.unquoted_false]]
    when 'user', 'version'
      field.possible_values_options(project)
    end
  end

  def type
    case field.field_format
    when 'int', 'float'
      :integer
    when 'text'
      :text
    when 'list', 'user', 'version'
      :list_optional
    when 'date'
      :date
    when 'bool'
      :list
    else
      :string
    end
  end

  def order
    20
  end

  def key
    "cf_#{field.id}".to_sym
  end

  def name
    field.name
  end

  def self.create(project)
    custom_fields = if project
                      project
                        .all_work_package_custom_fields(include: :translations)
                    else
                      WorkPackageCustomField.filter
                                            .for_all
                                            .where.not(field_format: ['user', 'version'])
                                            .includes(:translations)
                    end

    custom_fields.each_with_object({}.with_indifferent_access) do |cf, hash|
      filter = new(cf, project)

      hash[filter.key] = filter
    end
  end

  def self.key
    /cf_\d+/
  end
end

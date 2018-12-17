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

class Queries::WorkPackages::Filter::OrBaseFilter < Queries::WorkPackages::Filter::WorkPackageFilter
  def filters
    if @filters
      @filters.each do |filter|
        filter.operator = CONTAINS_OPERATOR
        filter.values = values
      end
    else
      @filter = create_instances
    end
  end

  def self.key
    raise NotImplementedError
  end

  def name
    raise NotImplementedError
  end

  def type
    raise NotImplementedError
  end

  def human_name
    raise NotImplementedError
  end

  def includes
    filters.map(&:includes).flatten.uniq.reject(&:blank?)
  end

  def where
    filters.map(&:where).join(' OR ')
  end

  def filter_configurations
    raise NotImplementedError
  end

  def create_instances
    filter_configurations.map do |filter_class, filter_name, operator|
      filter_class.create!(name: filter_name,
                           context: context,
                           operator: operator,
                           values: values)
    end
  end

  def update_instances
    configurations = filter_configurations

    @filters.each_with_index do |filter, index|
      operator_for_instance = configurations[index].third

      filter.operator = operator_for_instance
      filter.values = values
    end
  end

  def ar_object_filter?
    false
  end
end

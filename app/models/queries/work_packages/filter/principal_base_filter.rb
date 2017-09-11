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

class Queries::WorkPackages::Filter::PrincipalBaseFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  def available?
    User.current.logged? || allowed_values.any?
  end

  def value_objects_hash
    objects = super

    # Replace me value identifier
    if has_me_value?
      search = User.current.id
      objects.map! do |value_object|
        if value_object[:id] == search
          value_object[:id] = 'me'
          value_object[:name] = I18n.t(:label_me)
          break
        end
      end
    end

    objects
  end

  def value_objects
    prepared_values = values.map { |value| value == me_value ? User.current.id : value }
    Principal.where(id: prepared_values)
  end

  def ar_object_filter?
    true
  end

  def principal_resource?
    true
  end

  def has_me_value?
    values.include? me_value
  end

  def where
    operator_strategy.sql_for_field(values_replaced, self.class.model.table_name, self.class.key)
  end

  private

  def me_allowed_value
    values = []
    if User.current.logged?
      values << [I18n.t(:label_me), me_value]
    end
    values
  end

  def me_value
    'me'.freeze
  end

  def principal_loader
    @principal_loader ||= ::Queries::WorkPackages::Filter::PrincipalLoader.new(project)
  end

  def values_replaced
    vals = values.clone

    if vals.delete(me_value)
      if User.current.logged?
        vals.push(User.current.id.to_s)
      else
        vals.push('0')
      end
    end

    vals
  end
end

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

##
# Mixin to a filter or strategy
module Queries::WorkPackages::Filter::MeValueFilterMixin

  ##
  # Return whether the current values object has a me value
  def has_me_value?
    values.include? me_value
  end

  ##
  # Return the AR principal values with the me_value being replaced
  def value_objects
    prepared_values = values.map { |value| value == me_value ? User.current.id : value }
    Principal.where(id: prepared_values)
  end

  ##
  # Return the values object with the me value
  # mapped to the current user.
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

  protected

  def me_value
    'me'.freeze
  end

  def me_label
    I18n.t(:label_me)
  end

  ##
  # Returns the me value if the user is logged
  def me_allowed_value
    values = []
    if User.current.logged?
      values << [me_abel, me_value]
    end
    values
  end
end

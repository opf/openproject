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

class Queries::Principals::Filters::IdFilter < Queries::Principals::Filters::PrincipalFilter
  def allowed_values
    [["me", "me"]] # Not the whole truth but performes better than checking all IDs
  end

  def type
    :list
  end

  def self.key
    :id
  end

  def where
    operator_strategy.sql_for_field(values_replaced, self.class.model.table_name, self.class.key)
  end

  def values_replaced
    vals = values.clone

    if vals.delete('me')
      if User.current.logged?
        vals.push(User.current.id.to_s)
      else
        vals.push('0')
      end
    end

    vals
  end
end

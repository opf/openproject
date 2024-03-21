#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class Queries::Serialization::Filters
  include Queries::Filters::AvailableFilters
  include Queries::Filters::AvailableFilters::ClassMethods

  def load(serialized_filter_hash)
    return [] if serialized_filter_hash.nil?

    serialized_filter_hash.map do |serialized_filter|
      filter = filter_for(serialized_filter['attribute'], no_memoization: true)
      filter.operator = serialized_filter['operator']
      filter.values = serialized_filter['values']

      filter
    end
  end

  def dump(filters)
    self.class.dump(filters)
  end

  def self.dump(filters)
    (filters || []).map do |filter|
      {
        attribute: filter.field,
        operator: filter.operator,
        values: filter.values
      }
    end
  end

  def registered_filters
    Queries::Register.filters[klass]
  end

  def initialize(klass)
    @klass = klass
  end

  attr_reader :klass
end

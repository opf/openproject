# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

module Queries::Register
  class << self
    def filter(query, filter)
      filters[query] << filter
    end

    # Exclude filter from filters collection representer.
    def exclude(filter)
      excluded_filters << filter
    end

    def order(query, order)
      orders[query] << order
    end

    def group_by(query, group_by)
      group_bys[query] << group_by
    end

    def select(query, select)
      selects[query] << select
    end

    def register(query, &)
      Registration.new(query).instance_exec(&)
    end

    # A query class registering none of a given kind is normal - most notably
    # group_bys, which only a handful of queries declare - so these must return
    # an empty registry rather than nil.
    def filters = @filters ||= registry
    def orders = @orders ||= registry
    def selects = @selects ||= registry
    def group_bys = @group_bys ||= registry
    def excluded_filters = @excluded_filters ||= []

    attr_writer :filters,
                :excluded_filters,
                :orders,
                :selects,
                :group_bys

    private

    def registry
      Hash.new { |hash, key| hash[key] = [] }
    end
  end

  class Registration
    attr_reader :query

    def initialize(query)
      @query = query
    end

    def filter(filter)
      Queries::Register.filter(query, filter)
    end

    # Exclude filter from filters collection representer.
    def exclude(filter)
      Queries::Register.exclude(filter)
    end

    def order(order)
      Queries::Register.order(query, order)
    end

    def group_by(group_by)
      Queries::Register.group_by(query, group_by)
    end

    def select(select)
      Queries::Register.select(query, select)
    end
  end
end

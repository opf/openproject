#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
      @filters ||= Hash.new do |hash, filter_key|
        hash[filter_key] = []
      end

      @filters[query] << filter
    end

    # Exclude filter from filters collection representer.
    def exclude(filter)
      @excluded_filters ||= []
      @excluded_filters << filter
    end

    def order(query, order)
      @orders ||= Hash.new do |hash, order_key|
        hash[order_key] = []
      end

      @orders[query] << order
    end

    def group_by(query, group_by)
      @group_bys ||= Hash.new do |hash, group_key|
        hash[group_key] = []
      end

      @group_bys[query] << group_by
    end

    def select(query, select)
      @selects ||= Hash.new do |hash, select_key|
        hash[select_key] = []
      end

      @selects[query] << select
    end

    def register(query, &)
      Registration.new(query).instance_exec(&)
    end

    attr_accessor :filters,
                  :excluded_filters,
                  :orders,
                  :selects,
                  :group_bys
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

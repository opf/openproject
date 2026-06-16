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
# ++

module OpPrimer
  module QuickFilter
    class SegmentedControlComponent < ApplicationComponent
      include ApplicationHelper
      include OpTurbo::Streamable

      renders_many :items, OpPrimer::QuickFilter::Item

      def initialize(name:, query:, filter_key:, path_args:, orders: nil)
        super

        @name = name
        @query = query
        @filter_key = filter_key
        @path_args = path_args
        @orders = orders
      end

      def wrapper_key = "quick-filter-#{@filter_key}"

      def render? = items.any?

      private

      def current_value
        @query.find_active_filter(@filter_key)&.values&.first
      end

      def href_for(value)
        params = {}
        filters = filters_params(value)
        params[:filters] = filters.to_json if filters.any?

        sort = sort_params(value)
        params[:sortBy] = sort.to_json if sort.any?

        polymorphic_path(@path_args, params)
      end

      def sort_params(value)
        order_override = @orders && @orders[value]
        if order_override
          order_override.map { |attribute, direction| [attribute.to_s, direction.to_s] }
        else
          @query.orders.map { |order| [order.name, order.direction.to_s] }
        end
      end

      def filters_params(value)
        filters = @query.filters
          .reject { |f| f.name == @filter_key }
          .map { |f| { f.class.key.to_s => { "operator" => f.operator.to_s, "values" => f.values } } }

        filters << { @filter_key.to_s => { "operator" => "=", "values" => [value] } } if value

        filters
      end
    end
  end
end

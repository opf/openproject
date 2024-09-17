# frozen_string_literal: true

# -- copyright
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

class Queries::SortByComponent < ApplicationComponent
  options :query
  options :selectable_columns

  def current_orders
    JSON.dump(query.orders.map { |order| [order.attribute, order.direction] })
  end

  def order_limit
    3
  end

  def queried_model_name
    query.class.model.model_name
  end

  def available_orders
    @available_orders ||= begin
      all_order_keys = ::Queries::Register.orders[query.class]&.map(&:key)

      # Keys from the order can be symbols, strings or regexes
      selectable_columns.select do |column_option|
        all_order_keys.any? { |order_key| order_key === column_option[:id] }
      end
    end
  end
end

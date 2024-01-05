# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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

class Queries::Serialization::Orders
  include Queries::Orders::AvailableOrders

  def load(serialized_orders)
    return [] if serialized_orders.nil?

    serialized_orders.map do |o|
      order_for(o["attribute"].to_sym).tap do |order|
        order.direction = o["direction"].to_sym
      end
    end
  end

  def dump(orders)
    orders.map { |o| { attribute: o.attribute, direction: o.direction } }
  end

  def orders_register
    ::Queries::Register.orders[klass]
  end

  def initialize(klass)
    @klass = klass
  end

  attr_reader :klass
end

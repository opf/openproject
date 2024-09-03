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

class Authorization::QueryTransformationsOrder
  def initialize
    self.array = []
  end

  delegate :<<, :map, to: :array

  def full_order
    partial_orders = transformation_partial_orders

    merge_transformation_partial_orders(partial_orders)
  end

  private

  attr_accessor :array

  def transformation_partial_orders
    map do |transformation|
      transformation.after + [transformation.name] + transformation.before
    end
  end

  def merge_transformation_partial_orders(partial_orders)
    desired_order = []

    until partial_orders.empty?
      order = partial_orders.shift

      shift_first_if_its_turn(order, partial_orders) do |first|
        desired_order << first
      end

      partial_orders.push(order) unless order.empty?
    end

    desired_order
  end

  def shift_first_if_its_turn(order, partial_orders)
    @rejected ||= []

    if first_not_included_or_first_everywhere(order, partial_orders)
      partial_orders.select { |o| o[0] == order[0] }.each(&:shift)

      @rejected.clear
      yield order.shift
    else
      raise "Cannot sort #{order} into the list of transformations" if @rejected.include?(order)

      @rejected << order
    end
  end

  def first_not_included_or_first_everywhere(order, partial_orders)
    partial_orders.all? { |o| !o.include?(order[0]) || o[0] == order[0] }
  end
end

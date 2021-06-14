#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Queries::BaseQuery
  class << self
    def model
      @model ||= name.demodulize.gsub('Query', '').constantize
    end

    def i18n_scope
      :activerecord
    end
  end

  attr_accessor :filters, :orders

  include Queries::AvailableFilters
  include Queries::AvailableOrders
  include ActiveModel::Validations

  validate :filters_valid,
           :sortation_valid

  def initialize(user: nil)
    @filters = []
    @orders = []
    @user = user
  end

  def results
    if valid?
      apply_orders(apply_filters(default_scope))
    else
      empty_scope
    end
  end

  def where(attribute, operator, values)
    filter = filter_for(attribute)
    filter.operator = operator
    filter.values = values
    filter.context = context

    filters << filter

    self
  end

  def order(hash)
    hash.each do |attribute, direction|
      order = order_for(attribute)
      order.direction = direction
      orders << order
    end

    self
  end

  def default_scope
    self.class.model.all
  end

  def find_active_filter(name)
    filters.index_by(&:name)[name]
  end

  def find_available_filter(name)
    available_filters.detect { |f| f.name == name }
  end

  def ordered?
    orders.any?
  end

  protected

  attr_accessor :user

  def filters_valid
    filters.each do |filter|
      next if filter.valid?

      add_error(:filters, filter.human_name, filter)
    end
  end

  def sortation_valid
    orders.each do |order|
      next if order.valid?

      add_error(:orders, order.name, order)
    end
  end

  def add_error(local_attribute, attribute_name, object)
    messages = object
               .errors
               .messages
               .values
               .flatten
               .join(" #{I18n.t('support.array.sentence_connector')} ")

    errors.add local_attribute, errors.full_message(attribute_name, messages)
  end

  def empty_scope
    self.class.model.where(Arel::Nodes::Equality.new(1, 0))
  end

  def context
    nil
  end

  def apply_filters(scope)
    filters.each do |filter|
      scope = scope.merge(filter.scope)
    end

    scope
  end

  def apply_orders(scope)
    orders.each do |order|
      scope = scope.merge(order.scope)
    end

    # To get deterministic results, especially when paginating (limit + offset)
    # an order needs to be prepended that is ensured to be
    # different between all elements.
    # Without such a criteria, results can occur on multiple pages.
    already_ordered_by_id?(scope) ? scope : scope.order(id: :desc)
  end

  def already_ordered_by_id?(scope)
    scope.order_values.any? do |order|
      order.respond_to?(:value) && order.value.respond_to?(:relation) &&
        order.value.relation.name == self.class.model.table_name &&
        order.value.name == 'id'
    end
  end
end

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

module Queries::BaseQuery
  extend ActiveSupport::Concern

  included do
    include Queries::Filters::AvailableFilters
    include Queries::Selects::AvailableSelects
    include Queries::Orders::AvailableOrders
    include Queries::GroupBys::AvailableGroupBys
    include Queries::ValidSubset
    include ActiveModel::Validations

    validate :filters_valid,
             :sortation_valid
    validate :group_by_valid, if: -> { respond_to?(:group_by) }
  end

  class_methods do
    def model
      @model ||= name.demodulize.gsub("Query", "").constantize
    end

    def i18n_scope
      :activerecord
    end

    # Also use the Query class' as a lookup ancestor so that error messages, etc can be shared.
    # So if nothing is defined for the specific query class, we fall back to the generic query class.
    #
    # This is useful for error messages, because we can fall back to error messages, etc in
    # activerecord.errors.models.query
    def lookup_ancestors
      super + [Query]
    end
  end

  def results
    if valid?
      apply_orders(apply_filters(default_scope))
    else
      empty_scope
    end
  end

  def groups
    return nil if group_by.nil?
    return empty_scope unless valid?

    apply_group_by(apply_filters(default_scope))
      .select(group_by.name, Arel.sql("COUNT(*)"))
  end

  def group_values
    groups_hash = groups.pluck(group_by.name, Arel.sql("COUNT(*)")).to_h
    instantiate_group_keys groups_hash
  end

  def where(attribute, operator, values)
    filter = filter_for(attribute)
    filter.operator = operator
    filter.values = values
    filter.context = context

    # Remove any previous instances of the same filter
    remove_filter(filter.name)
    filters << filter

    self
  end

  def remove_filter(name)
    filters.delete(find_active_filter(name))
  end

  def select(*select_values, add_not_existing: true)
    select_values.each do |select_value|
      select_column = select_for(select_value)

      if !select_column.is_a?(::Queries::Selects::NotExistingSelect) || add_not_existing
        selects << select_column
      end
    end

    self
  end

  def order(hash)
    hash.each do |attribute, direction|
      order = order_for(attribute)
      order.direction = direction.to_sym
      orders << order
    end

    self
  end

  def group(attribute)
    self.group_by = group_by_for(attribute)

    self
  end

  def default_scope
    self.class.model.all
  end

  def find_active_filter(name)
    filters.detect { |f| f.name == name }
  end

  def find_available_filter(name)
    available_filters.detect { |f| f.name == name }
  end

  def ordered?
    orders.any?
  end

  protected

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

  def group_by_valid
    return if group_by.nil? || group_by.valid?

    add_error(:group_by, group_by.name, group_by)
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
    self
  end

  def apply_filters(query_scope)
    filters.inject(query_scope) do |scope, filter|
      filter.apply_to(scope)
    end
  end

  def apply_orders(query_scope)
    query_scope = build_orders.inject(query_scope) do |scope, order|
      order.apply_to(scope)
    end

    # To get deterministic results, especially when paginating (limit + offset)
    # an order needs to be prepended that is ensured to be
    # different between all elements.
    # Without such a criteria, results can occur on multiple pages.
    already_ordered_by_id?(query_scope) ? query_scope : query_scope.order(id: :desc)
  end

  def apply_group_by(query_scope)
    return query_scope if group_by.nil?

    group_by.apply_to(query_scope)
      .order(group_by.name)
  end

  def build_orders
    return orders if !respond_to?(:group_by) || group_by.nil? || has_group_by_order?

    [group_by_order] + orders
  end

  def has_group_by_order?
    !!group_by && orders.detect { |order| order.class.key == group_by.order_key }
  end

  def group_by_order
    order_for(group_by.order_key).tap do |order|
      order.direction = :asc
    end
  end

  def instantiate_group_keys(groups)
    return groups unless group_by&.association_class

    ar_keys = group_by.association_class.where(id: groups.keys.compact)

    groups.transform_keys do |key|
      ar_keys.detect { |ar_key| ar_key.id == key } || "#{key} #{I18n.t(:label_not_found)}"
    end
  end

  def already_ordered_by_id?(scope)
    scope.order_values.any? do |order|
      order.respond_to?(:value) && order.value.respond_to?(:relation) &&
        order.value.relation.name == self.class.model.table_name &&
        order.value.name == "id"
    end
  end
end

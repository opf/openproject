# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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

class Tables::ColumnHeaderComponent < ApplicationComponent
  attr_reader :query

  with_collection_parameter :column

  def initialize(column:, query:, **)
    super(column, **)
    @query = query
  end

  def column
    model
  end

  def column_header
    sort_header_tag(column)
  end

  # Returns a table header <th> tag with a sort link for the named column
  # attribute.
  def sort_header_tag(column)
    helpers.within_sort_header_tag_hierarchy(head_options: header_options(column),
                                             content_classes: sort_class(column),
                                             sort_header_outer_classes: sort_header_outer_classes(column)) do
      if sortable_column?(column)
        sort_link(column)
      else
        column_caption
      end
    end
  end

  def sort_link(column)
    link_to(current_sort_link_params.merge(sortBy: sort_by_param(column)),
            title: sort_link_title(column)) do
      column_caption
    end
  end

  delegate :caption, to: :column, prefix: true

  def sort_class(column)
    order = order_string(column)

    order.nil? ? nil : "sort #{order}"
  end

  def order_string(column, inverted: false)
    if column.attribute == first_order_by&.attribute
      if first_order_by.asc?
        inverted ? "desc" : "asc"
      else
        inverted ? "asc" : "desc"
      end
    end
  end

  def header_options(_column)
    {}
  end

  def sort_header_outer_classes(_column)
    ""
  end

  def sort_link_title(column)
    if column.attribute == first_order_by&.attribute
      order = first_order_by.asc? ? t(:label_ascending) : t(:label_descending)
      order + " #{t(:label_sorted_by, value: "\"#{column.caption}\"")}"
    else
      t(:label_sort_by, value: "\"#{column.caption}\"")
    end
  end

  def sortable_column?(_column)
    query.known_order?(column.attribute)
  end

  def ordered_by
    @ordered_by ||= query.orders.select(&:valid?)
  end

  def first_order_by
    ordered_by.first
  end

  def current_sort_link_params
    helpers.safe_query_params(Queries::BaseQuery::PARAM_NAMES - %i[sortBy page])
  end

  def sort_by_param(column)
    order = order_string(column, inverted: true) || "asc"

    orders = [[column.attribute, order]] + ordered_by
                                    .reject { |o| [column.attribute, :lft].include?(o.attribute) }
                                    .map { |o| [o.attribute, o.direction] }

    JSON::dump(orders[0..2])
  end
end

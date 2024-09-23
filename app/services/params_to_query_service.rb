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

class ParamsToQueryService
  attr_accessor :user,
                :query_class

  def initialize(model, user, query_class: nil)
    set_query_class(query_class, model)
    self.user = user
  end

  def call(params)
    query = new_query

    query = apply_filters(query, params)
    apply_order(query, params)
    apply_group_by(query, params)
  end

  private

  def new_query
    query_class.new(user:)
  end

  def apply_filters(query, params)
    return query unless params[:filters]

    filters = parse_filters_from_json(params[:filters])

    filters.each do |filter|
      query = query.where(filter[:attribute],
                          filter[:operator],
                          filter[:values])
    end

    query
  end

  def apply_order(query, params)
    return query unless params[:sortBy]

    sort = parse_sorting_from_json(params[:sortBy])

    hash_sort = sort.each_with_object({}) do |(attribute, direction), hash|
      hash[attribute.to_sym] = direction.downcase.to_sym
    end

    query.order(hash_sort)
  end

  def apply_group_by(query, params)
    return query unless params[:groupBy]

    group_by = convert_attribute(params[:groupBy])

    query.group(group_by)
  end

  # Expected format looks like:
  # [
  #   {
  #     "filtered_field_name": {
  #       "operator": "a name for a filter operation",
  #       "values": ["values", "for the", "operation"]
  #     }
  #   },
  #   { /* more filters if needed */}
  # ]
  def parse_filters_from_json(json)
    filters = Queries::ParamsParser::APIV3FiltersParser.parse(json)

    filters.each do |filter|
      filter[:attribute] = convert_attribute(filter[:attribute], append_id: true)
    end
  end

  def parse_sorting_from_json(json)
    JSON.parse(json).map do |(attribute, order)|
      [convert_attribute(attribute), order]
    end
  end

  def convert_attribute(attribute, append_id: false)
    ::API::Utilities::PropertyNameConverter.to_ar_name(attribute,
                                                       context: conversion_model,
                                                       refer_to_ids: append_id)
  end

  def conversion_model
    @conversion_model ||= ::API::Utilities::QueryFiltersNameConverterContext.new(query_class)
  end

  def set_query_class(query_class, model)
    self.query_class = if query_class
                         query_class
                       else
                         model_name = model.name

                         # Some queries exist as Queries::Models::ModelQuery others as ModelQuery
                         "::Queries::#{model_name.pluralize}::#{model_name.demodulize}Query".safe_constantize ||
                          "::#{model_name.demodulize}Query".constantize
                       end
  end
end

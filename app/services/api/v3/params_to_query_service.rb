#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    class ParamsToQueryService
      attr_accessor :model,
                    :user

      def initialize(model, user)
        self.model = model
        self.user = user
      end

      def call(params)
        query = new_query

        query = apply_filters(query, params)
        query = apply_order(query, params)

        query
      end

      private

      def new_query
        query_class.new(user: user)
      end

      def apply_filters(query, params)
        return query unless params[:filters]

        filters = parse_filters_from_json(params[:filters])

        filters[:attributes].each do |filter_name|
          query = query.where(filter_name,
                              filters[:operators][filter_name],
                              filters[:values][filter_name])
        end

        query
      end

      def apply_order(query, params)
        return query unless params[:sortBy]

        sort = parse_sorting_from_json(params[:sortBy])

        hash_sort = sort.each_with_object({}) do |(attribute, direction), hash|
          hash[attribute.to_sym] = direction.to_sym
        end

        query.order(hash_sort)
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
        filters = JSON.parse(json)
        operators = {}
        values = {}
        filters.each do |filter|
          attribute = filter.keys.first # there should only be one attribute per filter
          ar_attribute = convert_attribute attribute, append_id: true
          operators[ar_attribute] = filter[attribute]['operator']
          values[ar_attribute] = filter[attribute]['values']
        end

        {
          attributes: values.keys,
          operators: operators,
          values: values
        }
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

      def query_class
        model_name = model.name

        "::Queries::#{model_name.pluralize}::#{model_name}Query".constantize
      end
    end
  end
end

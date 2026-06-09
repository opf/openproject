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
    class SelectPanelComponent < ApplicationComponent
      include ApplicationHelper

      renders_many :items, OpPrimer::QuickFilter::Item

      def initialize(name:, query:, filter_key:, path_args:, operator: "=", src: nil, label_method: :name,
                     select_variant: :multiple)
        super

        @name = name
        @query = query
        @filter_key = filter_key
        @path_args = path_args
        @operator = operator
        @src = src
        @label_method = label_method
        @select_variant = select_variant
      end

      def before_render
        if async? && local?
          raise ArgumentError, "Use `src` for async loading or inline items for local rendering, not both."
        end

        if async? && @select_variant == :single
          raise ArgumentError, "Async mode is not supported with select_variant: :single."
        end

        if async? &&
           @query.filter_for(@filter_key).method(:value_objects).owner == Queries::Filters::Base
          raise ArgumentError,
                "#{@query.filter_for(@filter_key).class} does not implement #value_objects. " \
                "This is required when using the async version."
        end
      end

      def render?
        async? || local?
      end

      private

      def async?
        @src.present?
      end

      def local?
        items.any?
      end

      def active_filter
        @active_filter ||= @query.find_active_filter(@filter_key)
      end

      def current_values
        active_filter&.values&.map(&:to_s) || []
      end

      def button_label
        return render(Primer::Beta::Text.new(color: :muted)) { @name } if current_values.empty?

        @name
      end

      def panel_src
        return unless async?

        uri = URI.parse(@src)
        uri.query = panel_src_params(uri).to_query
        uri.to_s
      end

      def panel_src_params(uri)
        Rack::Utils.parse_nested_query(uri.query.to_s).tap do |params|
          # Pass other active filters (e.g. time=past) so the fragment endpoint builds
          # the same query scope as the current page, not its own default
          params["filters"] = other_filters.to_json if other_filters.any?
          # Pass currently selected ids so the right items can be marked in the response
          params["selected"] = current_values.join(",") if current_values.any?
        end
      end

      def fetch_strategy
        async? ? :eventually_local : :local
      end

      def base_url
        polymorphic_path(@path_args, base_url_params)
      end

      def base_url_params
        {}.tap do |params|
          params[:filters] = other_filters.to_json if other_filters.any?
          params[:sortBy] = sort.to_json if sort.any?
        end
      end

      def item_href(value)
        filters = other_filters + [{ @filter_key.to_s => { "operator" => @operator, "values" => [value.to_s] } }]
        params = { filters: filters.to_json }
        params[:sortBy] = sort.to_json if sort.any?
        polymorphic_path(@path_args, params)
      end

      def other_filters
        @query.filters
          .reject { |f| f.name == @filter_key }
          .map { |f| { f.class.key.to_s => { "operator" => f.operator.to_s, "values" => f.values } } }
      end

      def sort
        @query.orders.map { |order| [order.name, order.direction.to_s] }
      end
    end
  end
end

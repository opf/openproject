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
#++

module Workflows
  module Index
    class SubHeaderComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def initialize(query:)
        super()

        @query = query
      end

      def filters_form_attributes
        {
          controller: "filter--filters-form",
          "filter--filters-form-turbo-stream-request-value": true,
          "filter--filters-form-clear-button-id-value": clear_button_id,
          "filter--filters-form-current-filters-value": serialized_filters
        }
      end

      def name_filter_attributes
        {
          "filter-name": name_filter_key,
          "filter-type": "string",
          "filter-operator": "~",
          "filter--filters-form-target": "simpleFilter filterValueContainer simpleValue"
        }
      end

      def name_filter_key = ::Queries::Workflows::Filters::NameFilter.key.to_s

      def name_filter_value = query.find_active_filter(name_filter_key.to_sym)&.values&.first

      def serialized_filters = OpPrimer::QuickFilter.serialize(query.filters).to_json

      def clear_button_id = "workflows-filters-clear-button"

      def type_filter_component
        TypeFilterComponent.new(query:)
      end

      def projects_filter_component
        ProjectsFilterComponent.new(query:)
      end

      private

      attr_reader :query
    end
  end
end

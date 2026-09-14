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

module ResourceManagement
  module UserSelection
    extend ActiveSupport::Concern

    # `AnyNameAttributeFilter` is absent because it exists to back autocompleter
    # searches rather than human filtering; `NameFilter` covers that case in the
    # picker.
    CONFIGURATION_FILTERS = [
      ::Queries::Users::Filters::CustomFieldFilter,
      ::Queries::Users::Filters::GroupFilter,
      ::Queries::Users::Filters::LoginFilter,
      ::Queries::Users::Filters::MemberFilter,
      ::Queries::Users::Filters::NameFilter,
      ::Queries::Users::Filters::StatusFilter
    ].freeze

    # The custom field filter's key is a `cf_<id>` pattern rather than a single
    # name, hence the `===` match rather than a set lookup.
    CONFIGURATION_FILTER_KEYS = CONFIGURATION_FILTERS.map(&:key).freeze

    included do
      validate :query_must_be_user_query
    end

    def results
      query = effective_query
      return if query.nil?

      query.results.in_project(project)
    end

    def manually_picked?
      effective_query&.manual_elements? || false
    end

    # The user set is team-sized, so both manual and automatic views pin the
    # resolved ids: the principals autocompleter endpoint uses a different
    # filter registry than UserQuery, so forwarding the view's own filters is
    # not safe.
    def allocation_principal_filters
      [{ name: "id", operator: "=", values: (results&.ids || []).map(&:to_s) }]
    end

    def allocation_work_package_filters
      nil
    end

    # The filters offered when configuring the view, alphabetically as they
    # appear in the picker. The project scoping is applied outside the filter set
    # (`results.in_project`), so no filter can override it.
    def configuration_filters(query)
      return [] if query.nil?

      query.available_advanced_filters
           .select { |filter| configuration_filter?(filter.name) }
           .sort_by(&:human_name)
    end

    def configuration_filter?(name)
      CONFIGURATION_FILTER_KEYS.any? { |key| key === name.to_sym }
    end

    def build_default_query
      UserQuery.new(project:, principal:)
    end

    # The mutated query is persisted alongside the view via the `autosave`
    # association.
    def apply_query_configuration(filters_json:, filter_mode:)
      query = effective_query
      return if query.nil?

      query.filters.clear

      if manual_mode?(filter_mode)
        query.manual_elements = true
      else
        query.manual_elements = false

        query.ordered_entities.destroy_all
        configure_automatic(query, filters_json)
      end
    end

    private

    def manual_mode?(filter_mode)
      filter_mode.to_s == "manual"
    end

    def configure_automatic(query, filters_json)
      allowed_configuration_filters(parse_filters(filters_json)).each do |filter|
        query.where(filter[:attribute], filter[:operator], filter[:values])
      end
    end

    # Drops anything the configuration UI does not offer, so a hand-crafted
    # payload cannot smuggle in a withheld filter.
    def allowed_configuration_filters(filters)
      filters.select { |filter| configuration_filter?(filter[:attribute]) }
    end

    def parse_filters(filters_json)
      return [] if filters_json.blank?

      ::Queries::ParamsParser::APIV3FiltersParser.parse(filters_json)
    rescue JSON::ParserError
      []
    end

    def query_must_be_user_query
      resolved = effective_query
      return if resolved.nil? || resolved.is_a?(UserQuery)

      errors.add(:query, :invalid)
    end
  end
end

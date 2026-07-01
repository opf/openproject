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
  # Shared behaviour for planner views that select work packages through a
  # work-package `Query`, in manual (hand-picked) or automatic (filtered) mode.
  # The work-package-list and -timeline views differ only in how they render it.
  module WorkPackageSelection
    extend ActiveSupport::Concern

    # The "ow" (ordered work packages) filter restricts results to a hand-picked set.
    MANUAL_FILTER_NAME = "manual_sort"

    included do
      validate :query_must_be_work_package_query
    end

    # The `::` prefix disambiguates the top-level `Query` from
    # `ActiveRecord::AttributeMethods::Query`.
    def build_default_query
      ::Query.new_default(project:, user: principal)
    end

    # The mutated query is persisted alongside the view via the `autosave`
    # association.
    def apply_query_configuration(filters_json:, filter_mode:)
      query = effective_query
      return if query.nil?

      query.name = configured_query_name
      query.filters.clear

      if manual_mode?(filter_mode)
        configure_manual(query)
      else
        configure_automatic(query, filters_json)
      end
    end

    def manually_picked?
      effective_query&.manually_sorted? || false
    end

    def work_packages
      effective_query&.results&.work_packages || WorkPackage.none
    end

    private

    # Overridable so each view type labels its persisted query appropriately.
    def query_name_i18n_key
      "resource_management.work_package_list.query_name"
    end

    def configured_query_name
      I18n.t(query_name_i18n_key, name:)
    end

    def manual_mode?(filter_mode)
      filter_mode.to_s == "manual"
    end

    def configure_manual(query)
      query.add_filter(MANUAL_FILTER_NAME, "ow", [])
      query.sort_criteria = [%w[manual_sorting asc], %w[id asc]]
    end

    def configure_automatic(query, filters_json)
      # Drop a leftover manual sort so a re-filtered view no longer depends on
      # ordered_work_packages.
      query.sort_criteria = [%w[id asc]] if query.manually_sorted?

      parse_filters(filters_json).each do |filter|
        query.add_filter(filter[:attribute], filter[:operator], filter[:values])
      end
    end

    def parse_filters(filters_json)
      return [] if filters_json.blank?

      ::Queries::ParamsParser::APIV3FiltersParser.parse(filters_json)
    rescue JSON::ParserError
      []
    end

    def query_must_be_work_package_query
      resolved = effective_query
      return if resolved.nil? || resolved.is_a?(::Query)

      errors.add(:query, :must_be_work_package_query)
    end
  end
end

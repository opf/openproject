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
  module WorkPackageSelection
    extend ActiveSupport::Concern

    # The "ow" (ordered work packages) filter restricts results to a hand-picked set.
    MANUAL_FILTER_NAME = "manual_sort"

    # Work package queries advertise roughly fifty filters, most of which exist
    # to back autocompleters, full-text search, storage integrations or relation
    # lookups rather than resource planning. Only the attributes a planner
    # allocates by are offered, plus custom fields.
    #
    # `ProjectFilter` is deliberately absent: the view is always scoped to its
    # planner's project and a configured filter must not override that scoping.
    CONFIGURATION_FILTERS = [
      ::Queries::WorkPackages::Filter::CustomFieldFilter,
      ::Queries::WorkPackages::Filter::AncestorFilter,
      ::Queries::WorkPackages::Filter::AssignedToFilter,
      ::Queries::WorkPackages::Filter::AssigneeOrGroupFilter,
      ::Queries::WorkPackages::Filter::AuthorFilter,
      ::Queries::WorkPackages::Filter::CategoryFilter,
      ::Queries::WorkPackages::Filter::CreatedAtFilter,
      ::Queries::WorkPackages::Filter::DatesIntervalFilter,
      ::Queries::WorkPackages::Filter::DoneRatioFilter,
      ::Queries::WorkPackages::Filter::DueDateFilter,
      ::Queries::WorkPackages::Filter::DurationFilter,
      ::Queries::WorkPackages::Filter::EstimatedHoursFilter,
      ::Queries::WorkPackages::Filter::GroupFilter,
      ::Queries::WorkPackages::Filter::IdFilter,
      ::Queries::WorkPackages::Filter::ParentFilter,
      ::Queries::WorkPackages::Filter::PriorityFilter,
      ::Queries::WorkPackages::Filter::ProjectPhaseFilter,
      ::Queries::WorkPackages::Filter::ResponsibleFilter,
      ::Queries::WorkPackages::Filter::RoleFilter,
      ::Queries::WorkPackages::Filter::StartDateFilter,
      ::Queries::WorkPackages::Filter::StatusFilter,
      ::Queries::WorkPackages::Filter::SubjectFilter,
      ::Queries::WorkPackages::Filter::TargetVersionsFilter,
      ::Queries::WorkPackages::Filter::TypeFilter,
      ::Queries::WorkPackages::Filter::UpdatedAtFilter
    ].freeze

    # The custom field filter's key is a `cf_<id>` pattern rather than a single
    # name, hence the `===` match rather than a set lookup.
    CONFIGURATION_FILTER_KEYS = CONFIGURATION_FILTERS.map(&:key).freeze

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

    # A manually-picked view pins its hand-chosen ids; an automatic view forwards
    # its query filters so the API filters server-side instead of materialising a
    # potentially huge id list.
    def allocation_work_package_filters
      if manually_picked?
        # `reorder(nil)` drops the manual-sort ordering: it is irrelevant for a
        # filter set and its `ORDER BY ordered_work_packages.position` clashes
        # with the id-only GROUP BY otherwise.
        [{ name: "id", operator: "=", values: work_packages.reorder(nil).ids.map(&:to_s) }]
      else
        dump_query_filters(effective_query)
      end
    end

    def allocation_principal_filters
      nil
    end

    # The filters offered when configuring the view, alphabetically as they
    # appear in the picker. Takes the query rather than reading `effective_query`
    # so the new-view dialog can advertise them before the view has one.
    def configuration_filters(query)
      return [] if query.nil?

      query.available_advanced_filters
           .select { |filter| configuration_filter?(filter.name) }
           .sort_by(&:human_name)
    end

    def configuration_filter?(name)
      CONFIGURATION_FILTER_KEYS.any? { |key| key === name.to_sym }
    end

    private

    # The view's filters were originally built from API-v3 filter JSON, so
    # dumping `field`/`operator`/`values` round-trips back into that format.
    def dump_query_filters(query)
      (query&.filters || []).map do |filter|
        { name: filter.field.to_s, operator: filter.operator, values: filter.values }
      end
    end

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

      allowed_configuration_filters(parse_filters(filters_json)).each do |filter|
        query.add_filter(filter[:attribute], filter[:operator], filter[:values])
      end
    end

    # Drops anything the configuration UI does not offer, so a hand-crafted
    # payload cannot smuggle in a withheld filter — the project filter in
    # particular, which would override the built-in project scoping.
    def allowed_configuration_filters(filters)
      filters.select { |filter| configuration_filter?(filter[:attribute]) }
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

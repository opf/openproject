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

module WorkPackageTypes
  class FormConfigurationComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    ASPECT = TypeVariant::FORM_CONFIGURATION

    def initialize(variant:, form_attributes:, no_filter_query:)
      super(variant)
      @variant = variant
      @form_attributes = form_attributes
      @no_filter_query = no_filter_query
    end

    def readonly?
      OpenProject::FeatureDecisions.type_variants_active? && @variant.linked?(ASPECT)
    end

    def source
      @variant.effective_source_for(ASPECT)
    end

    # We memoize the exclusion state here to avoid an n+1 query
    def exclusion_state
      return @exclusion_state if defined?(@exclusion_state)

      @exclusion_state = readonly? ? WorkPackageTypes::ExclusionState.for(@variant, ASPECT) : nil
    end

    def ee_available?
      EnterpriseToken.allows_to?(:edit_attribute_groups)
    end

    def inactive_attributes
      @form_attributes[:inactives]
    end

    # In read-only mode the visible configuration is the linked source's
    def active_groups
      attributes = readonly? ? helpers.form_configuration_groups(source) : @form_attributes
      groups = attributes[:actives].reject { |g| g[:key].to_s == "__empty" }

      readonly? ? without_source_exclusions(groups) : groups
    end

    def wrapper_data
      return {} if readonly?

      {
        controller: "admin--type-form-configuration--main admin--type-form-configuration--rows-drag-and-drop",
        "admin--type-form-configuration--main-no-filter-query-value": @no_filter_query,
        "admin--type-form-configuration--main-add-group-url-value": add_group_type_form_configuration_groups_path(
          **@variant.path_args
        ),
        "admin--type-form-configuration--main-groups-url-value": type_form_configuration_groups_path(**@variant.path_args),
        "admin--type-form-configuration--rows-drag-and-drop-handle-selector-value": ".attribute-handle"
      }
    end

    def active_list_data
      return {} if readonly?

      {
        controller: "admin--type-form-configuration--drag-and-drop",
        "admin--type-form-configuration--drag-and-drop-handle-selector-value": ".group-handle",
        "admin--type-form-configuration--drag-and-drop-target": "scrollContainer",
        "admin--type-form-configuration--rows-drag-and-drop-target": "scrollContainer"
      }
    end

    def main_content_component
      groups_type = readonly? ? source : @variant
      groups = active_groups
      group_components = groups.map.with_index do |group, i|
        WorkPackageTypes::FormConfiguration::GroupComponent.new(
          group:,
          variant: groups_type,
          ee_available: ee_available?,
          first: i == 0,
          last: i == groups.length - 1,
          readonly: readonly?,
          exclusions: exclusion_state
        )
      end

      WorkPackageTypes::FormConfiguration::MainContentComponent.new(
        variant: @variant,
        group_components:,
        ee_available: ee_available?,
        readonly: readonly?
      )
    end

    private

    def without_source_exclusions(groups)
      return groups if exclusion_state.nil?

      groups.filter_map do |group|
        if group[:type].to_s == "query"
          retained_query_group(group)
        else
          narrowed_attribute_group(group)
        end
      end
    end

    def narrowed_attribute_group(group)
      attributes = group[:attributes].to_a
      remaining = attributes.reject { |attribute| exclusion_state.excluded_by_source?(attribute[:key]) }
      return if remaining.empty? && attributes.any?

      group.merge(attributes: remaining)
    end

    # A query group is a single entry in the section, so a source exclusion drops the whole section.
    def retained_query_group(group)
      group unless group[:element_key].present? && exclusion_state.excluded_by_source?(group[:element_key])
    end
  end
end

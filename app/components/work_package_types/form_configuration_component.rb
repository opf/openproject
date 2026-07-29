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

    ASPECT = Type::ConfigurationLink::FORM_CONFIGURATION

    # What this type does not inherit. `own` is this type's own link, `effective` the union over
    # the whole chain, so an element in `effective` but not in `own` was excluded above this type.
    ExclusionState = Data.define(:type, :own, :effective, :source_name) do
      def excluded?(key)
        effective.include?(key.to_s)
      end

      def inherited?(key)
        excluded?(key) && own.exclude?(key.to_s)
      end
    end

    def initialize(type:, form_attributes:, no_filter_query:)
      super(type)
      @type = type
      @form_attributes = form_attributes
      @no_filter_query = no_filter_query
    end

    def readonly?
      OpenProject::FeatureDecisions.type_variants_active? && @type.linked?(ASPECT)
    end

    def source
      @type.effective_source_for(ASPECT)
    end

    # We memoize the exclusion state here to avoid an n+1 query
    def exclusion_state
      return nil unless readonly?
      return @exclusion_state if defined?(@exclusion_state)

      @exclusion_state = build_exclusion_state
    end

    def ee_available?
      EnterpriseToken.allows_to?(:edit_attribute_groups)
    end

    def inactive_attributes
      @form_attributes[:inactives]
    end

    # In read-only mode the visible configuration is the linked source's, resolved at
    # render time; independent types show their own stored configuration.
    def active_groups
      attributes = readonly? ? helpers.form_configuration_groups(source) : @form_attributes
      attributes[:actives].reject { |g| g[:key].to_s == "__empty" }
    end

    def wrapper_data
      return {} if readonly?

      {
        controller: "admin--type-form-configuration--main admin--type-form-configuration--rows-drag-and-drop",
        "admin--type-form-configuration--main-no-filter-query-value": @no_filter_query,
        "admin--type-form-configuration--main-add-group-url-value": add_group_type_form_configuration_groups_path(@type),
        "admin--type-form-configuration--main-groups-url-value": type_form_configuration_groups_path(@type),
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
      groups_type = readonly? ? source : @type
      groups = active_groups
      group_components = groups.map.with_index do |group, i|
        WorkPackageTypes::FormConfiguration::GroupComponent.new(
          group:,
          type: groups_type,
          ee_available: ee_available?,
          first: i == 0,
          last: i == groups.length - 1,
          readonly: readonly?,
          exclusions: exclusion_state
        )
      end

      WorkPackageTypes::FormConfiguration::MainContentComponent.new(
        type: @type,
        group_components:,
        ee_available: ee_available?,
        readonly: readonly?
      )
    end

    private

    def build_exclusion_state
      link = @type.configuration_links.find_by(aspect: ASPECT)
      return nil unless link

      ExclusionState.new(
        type: @type,
        own: link.excluded_elements.map(&:to_s),
        effective: @type.effective_excluded_elements(ASPECT).map(&:to_s),
        source_name: link.source.composite_name
      )
    end
  end
end

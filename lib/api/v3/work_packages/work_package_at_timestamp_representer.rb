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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module V3
    module WorkPackages
      class WorkPackageAtTimestampRepresenter < WorkPackageRepresenter
        # We avoid caching since the properties displayed depend on the changes happening between
        # the baseline and the timestamp provided.
        cached_representer disabled: true

        # List of properties that are currently supported by this representer.
        # Probably, way more, maybe even all properties are supported but that is untested.
        SUPPORTED_NON_LINK_PROPERTIES = %w[
          date
          derived_estimated_time
          due_date
          estimated_time
          start_date
          subject
          story_points
        ].freeze

        SUPPORTED_LINK_PROPERTIES = %w[
          assignee
          labels
          observed_in_versions
          parent
          priority
          project
          responsible
          status
          target_versions
          type
          version
        ].freeze

        MULTI_VALUED_LINK_PROPERTIES = %w[
          labels
          observed_in_versions
          target_versions
        ].freeze

        SUPPORTED_CUSTOM_PROPERTIES = [CustomField::ATTRIBUTE_NAME_PATTERN].freeze

        SUPPORTED_PROPERTIES = (SUPPORTED_NON_LINK_PROPERTIES + SUPPORTED_LINK_PROPERTIES).freeze

        ALL_SUPPORTED_PROPERTIES = (SUPPORTED_PROPERTIES + SUPPORTED_CUSTOM_PROPERTIES).freeze

        STATIC_NON_LINK_PROPERTIES = %w[_meta].freeze
        STATIC_LINK_PROPERTIES = ["links", :schema, :self].freeze

        def initialize(model, current_user:)
          super(model, current_user:, embed_links:, timestamps: [model.timestamp])
        end

        def timestamps_active?
          true
        end

        private

        def representable_map(*)
          Representable::Binding::Map.new(super.select { |bind| rendered_properties.include?(bind.name) })
        end

        def compile_links_for(configs, *)
          super(configs.select { |config| rendered_properties_for_links.include?(config.first[:rel]) },
                *)
        end

        def rendered_properties
          @rendered_properties ||= begin
            properties = changed_properties_as_api_name.select { |prop| property_supported?(prop) } + STATIC_NON_LINK_PROPERTIES

            if represented.exists_at_timestamp?
              properties + STATIC_LINK_PROPERTIES
            else
              properties
            end
          end
        end

        # This separate property list is a workaround and ideally it is not required.
        # The reason is that names in the representable_map are underscored "custom_fields_1",
        # the :rel names in the config from the compile_links_for method are lower camel-cased "customField1".
        # The rendered_properties method contains the underscored names and the rendered_properties_for_links
        # contains the lower camel-cased names.
        def rendered_properties_for_links
          @rendered_properties_for_links ||= rendered_properties.map do |property|
            if CustomField.custom_field_attribute?(property) || MULTI_VALUED_LINK_PROPERTIES.include?(property)
              API::Utilities::PropertyNameConverter.from_ar_name(property)
            else
              property
            end
          end
        end

        def changed_properties_as_api_name
          # This conversion is good enough for the set of supported properties as it
          # * Converts assigned_to_id to assignee
          # * does not mess with `start_date` and `due_date`
          # * renders own and derived work together, as one cell displays both
          if represented.exists_at_current_timestamp?
            represented
              .attributes_changed_to_baseline
              .flat_map do |property|
              if property.ends_with?("_id")
                API::Utilities::PropertyNameConverter.from_ar_name(property)
              elsif %w[start_date due_date].include?(property)
                ["date", property]
              elsif %w[estimated_hours derived_estimated_hours].include?(property)
                %w[estimated_time derived_estimated_time]
              else
                property
              end
            end
          else
            SUPPORTED_PROPERTIES
          end
        end

        def property_supported?(property)
          ALL_SUPPORTED_PROPERTIES.any? { it.is_a?(Regexp) ? property =~ it : property == it }
        end
      end
    end
  end
end

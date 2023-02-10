# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
          subject
          start_date
          due_date
        ].freeze

        SUPPORTED_LINK_PROPERTIES = %w[
          assignee
          responsible
          project
          status
          priority
          type
          version
        ].freeze

        SUPPORTED_PROPERTIES = (SUPPORTED_NON_LINK_PROPERTIES + SUPPORTED_LINK_PROPERTIES).freeze

        def initialize(model, current_user:)
          super(model, current_user:, embed_links:, timestamps: [model.timestamp])
        end

        private

        def representable_map(*)
          Representable::Binding::Map.new(super.select { |bind| rendered_properties.include?(bind.name) })
        end

        def compile_links_for(configs, *args)
          super(configs.select { |config| rendered_properties.include?(config.first[:rel]) },
                *args)
        end

        def rendered_properties
          @rendered_properties ||= begin
            properties = (changed_properties_as_api_name & SUPPORTED_PROPERTIES) + ['_meta']

            if represented.exists_at_timestamp?
              properties + ["links", :self]
            else
              properties
            end
          end
        end

        def changed_properties_as_api_name
          # This conversion is good enough for the set of supported properties as it
          # * Converts assigned_to_id to assignee
          # * does not mess with `start_date` and `due_date`
          represented
            .attributes_changed_to_baseline
            .map do |property|
            if property.ends_with?('_id')
              API::Utilities::PropertyNameConverter.from_ar_name(property)
            else
              property
            end
          end
        end
      end
    end
  end
end

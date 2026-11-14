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

module Projects
  module Settings
    module WorkPackages
      module CustomFields
        class SubHeaderComponent < ApplicationComponent
          include OpPrimer::ComponentHelpers

          def initialize(project:, query:)
            super()

            @project = project
            @query = query
          end

          private

          attr_reader :project, :query

          def filters_form_attributes
            {
              controller: "filter--filters-form",
              "filter--filters-form-turbo-stream-request-value": true,
              "filter--filters-form-output-format-value": "json",
              "filter--filters-form-clear-button-id-value": clear_button_id,
              "filter--filters-form-current-filters-value": OpPrimer::QuickFilter.serialize(query.filters).to_json
            }
          end

          def name_filter_attributes
            {
              "filter-name": "name",
              "filter-type": "string",
              "filter-operator": "~",
              "filter--filters-form-target": "simpleFilter filterValueContainer simpleValue"
            }
          end

          def name_filter_value = query.find_active_filter(:name)&.values&.first

          def clear_button_id = "project-custom-fields-filters-clear-button"

          def format_filter
            filter = query.filter_for(:field_format)
            component = OpPrimer::QuickFilter::SelectPanelComponent.new(
              name: filter.human_name,
              query:,
              filter_key: :field_format,
              path_args: [project, :settings_work_packages_custom_fields],
              select_variant: :single
            )

            render(component) do |panel|
              filter.allowed_values.each { |label, value| panel.with_item(label:, value:) }
            end
          end

          def values_filter
            render(ValuesFilterComponent.new(project:, query:))
          end
        end
      end
    end
  end
end

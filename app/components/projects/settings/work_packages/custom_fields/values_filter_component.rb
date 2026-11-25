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
        class ValuesFilterComponent < ApplicationComponent
          def initialize(project:, query:)
            super()

            @project = project
            @query = query
          end

          def call
            action_menu = Primer::Alpha::ActionMenu.new(select_variant: :single,
                                                        test_selector: "project-custom-fields-values-filter")

            render(action_menu) do |menu|
              menu.with_show_button(scheme: :secondary) do |button|
                button.with_trailing_action_icon(icon: :"triangle-down")
                button_label
              end

              filter.available_operators.each do |operator|
                menu.with_item(label: operator.human_name, href: filter_path(operator), active: operator == active_operator)
              end
            end
          end

          private

          attr_reader :project, :query

          def filter
            @filter ||= query.filter_for(:project_values)
          end

          def active_operator
            query.find_active_filter(:project_values)&.operator_class || filter.default_operator
          end

          def button_label
            selection = active_operator == filter.default_operator ? t(:label_all_uppercase) : active_operator.human_name

            "#{filter.human_name}: #{selection}"
          end

          def filter_path(operator)
            filters = OpPrimer::QuickFilter.serialize(query.filters, except: :project_values)
            filters << selection_filter(operator) unless operator == filter.default_operator

            project_settings_work_packages_custom_fields_path(project, filters: filters.to_json)
          end

          def selection_filter(operator)
            { "project_values" => { "operator" => operator.symbol, "values" => [] } }
          end
        end
      end
    end
  end
end

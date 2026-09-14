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

module Projects
  module Settings
    module WorkPackages
      module Types
        # What the chosen switch will do. Streamable on its own so choosing a
        # target repaints it without re-rendering the form and moving focus off
        # the select.
        class SwitchImpactComponent < ApplicationComponent
          include OpPrimer::ComponentHelpers
          include OpTurbo::Streamable

          Section = Data.define(:id, :heading, :fields)

          DEFAULT_COLUMNS = %w[id type subject status].freeze

          def initialize(impact:)
            super()

            @impact = impact
          end

          private

          attr_reader :impact

          def field_sections
            [
              Section.new(id: "hidden",
                          heading: t("projects.settings.types.switch.impact.hidden_heading"),
                          fields: impact.hidden_fields),
              Section.new(id: "new",
                          heading: t("projects.settings.types.switch.impact.new_heading"),
                          fields: impact.new_fields)
            ].reject { it.fields.empty? }
          end

          def field_suffix(field)
            if field.kind == :table
              t("projects.settings.types.switch.impact.table_suffix")
            elsif (count = impact.value_count(field))
              t("projects.settings.types.switch.impact.value_count", count:)
            end
          end

          # Every counter answers "which ones?" by linking to the work packages behind it.
          # In a new tab on purpose: following a link in place would navigate away from the
          # dialog and discard the variant the reader is still deciding on.
          def filtered_work_packages_path(filters, columns: [])
            query_props = { c: DEFAULT_COLUMNS + columns, t: "id:asc", f: scope_filters + filters }.to_json

            if impact.single_project?
              project_work_packages_path(impact.project, query_props:)
            else
              work_packages_path(query_props:)
            end
          end

          def scope_filters
            return [] if impact.single_project?

            [{ "n" => "project_id", "o" => "=", "v" => impact.project_ids.map(&:to_s) }]
          end

          def all_path
            filtered_work_packages_path([type_filter])
          end

          def status_path(status)
            filtered_work_packages_path([type_filter, { "n" => "status", "o" => "=", "v" => [status.id.to_s] }])
          end

          # Filtered on the field holding a value, so the list is exactly what the counter
          # counted, and carrying it as a column so the values themselves are on screen.
          def field_path(field)
            name = api_name(field)

            filtered_work_packages_path([type_filter, { "n" => name, "o" => "*", "v" => [] }], columns: [name])
          end

          def type_filter
            { "n" => "type", "o" => "=", "v" => [impact.source.type_id.to_s] }
          end

          def api_name(field)
            ::API::Utilities::PropertyNameConverter.from_ar_name(field.key)
          end
        end
      end
    end
  end
end

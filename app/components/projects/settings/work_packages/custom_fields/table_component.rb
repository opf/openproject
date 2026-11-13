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
      module CustomFields
        class TableComponent < OpPrimer::BorderBoxTableComponent
          include ::WorkPackageTypes::VariantRoutes

          columns :custom_field, :field_format, :variants
          mobile_labels :field_format, :variants

          def initialize(project:, variants_by_field:, project_specific_value_counts:, **)
            super(rows: variants_by_field.keys, **)

            @project = project
            @variants_by_field = variants_by_field
            @project_specific_value_counts = project_specific_value_counts
            @values_manageable = User.current.allowed_in_project?(:manage_work_package_custom_field_values, project)
          end

          def headers
            [
              [:custom_field, { caption: t("projects.settings.custom_fields.column_name") }],
              [:field_format, { caption: t("projects.settings.custom_fields.column_format") }],
              [:variants, { caption: t("projects.settings.custom_fields.column_variants") }]
            ]
          end

          def variants_for(field) = @variants_by_field.fetch(field)

          def project_specific_value_count(field) = @project_specific_value_counts.fetch(field, 0)

          def values_manageable?(field)
            @values_manageable && (field.project_level_value_management? || field.allow_additional_project_values?)
          end

          def variant_path(variant)
            variant_settings_path(variant.project_owned? ? project : nil, variant)
          end

          def linked?(variant) = variant.configurable_by?(User.current)

          def mobile_title = t(:label_custom_field_plural)

          def blank_title = t("projects.settings.custom_fields.no_results_title_text")

          def blank_description = nil

          def blank_icon = :"list-unordered"

          private

          attr_reader :project
        end
      end
    end
  end
end

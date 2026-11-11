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

          columns :custom_field, :variants
          main_column :custom_field, :variants
          mobile_labels :variants

          def initialize(project:, variants_by_field:, **)
            super(rows: variants_by_field.keys, **)

            @project = project
            @variants_by_field = variants_by_field
          end

          def headers
            [
              [:custom_field, { caption: t("projects.settings.custom_fields.column_name") }],
              [:variants, { caption: t("projects.settings.custom_fields.column_variants") }]
            ]
          end

          def variants_for(field) = @variants_by_field.fetch(field)

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

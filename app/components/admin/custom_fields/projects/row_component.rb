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

module Admin
  module CustomFields
    module Projects
      class RowComponent < OpPrimer::BorderBoxRowComponent
        include ::CustomFields::AdminRoutes

        alias_method :project, :model

        def row_data = { test_selector: "custom-field-projects-row-#{project.id}" }

        def name
          render(::Projects::InfoLineComponent.new(project:))
        end

        def types
          safe_join(table.types_of(project).map { |type| link_to(type.name, type_settings_path(type_id: type.id)) }, ", ")
        end

        def project_specific_values
          count = table.usable_value_counts.fetch(project.id)
          total = table.value_count

          if count.zero?
            I18n.t("custom_fields.admin.projects.enabled_values.none")
          elsif count == total
            I18n.t("custom_fields.admin.projects.enabled_values.all")
          else
            I18n.t("custom_fields.admin.projects.enabled_values.some", count:, total:)
          end
        end

        def button_links
          [configure_button]
        end

        private

        def configure_button
          render(
            Primer::Beta::IconButton.new(
              icon: :"project-symlink",
              tag: :a,
              href: project_values_path(table.custom_field, project),
              scheme: :default,
              aria: { label: I18n.t("custom_fields.admin.projects.configure", project: project.name) },
              tooltip_direction: :w
            )
          )
        end
      end
    end
  end
end

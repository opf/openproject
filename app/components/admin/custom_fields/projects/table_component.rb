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
      class TableComponent < OpPrimer::BorderBoxTableComponent
        FRAME_ID = "custom-field-projects-list"

        columns :name, :types, :project_specific_values
        main_column :name
        mobile_labels :types, :project_specific_values

        attr_reader :custom_field

        def initialize(rows:, custom_field:, type_ids_by_project_id:, filtered: false)
          super(rows:)

          @custom_field = custom_field
          @type_ids_by_project_id = type_ids_by_project_id
          @filtered = filtered
        end

        def headers
          [
            [:name, { caption: Project.model_name.human }],
            [:types, { caption: I18n.t("custom_fields.admin.projects.types_column") }],
            if project_specific_values?
              [:project_specific_values,
               { caption: CustomField.human_attribute_name(:project_specific_value_restriction) }]
            end
          ].compact
        end

        def skip_column?(column)
          column == :project_specific_values && !project_specific_values?
        end

        def project_specific_values?
          custom_field.project_specific_value_restriction.present?
        end

        def types_of(project)
          types_by_id.values_at(*@type_ids_by_project_id.fetch(project.id, [])).compact.sort_by(&:position)
        end

        def value_count
          @value_count ||= custom_field.restrictable_values.count
        end

        def usable_value_counts
          @usable_value_counts ||= custom_field.usable_value_counts_in(Project.where(id: rows.map(&:id)))
        end

        def has_actions? = project_specific_values?

        def mobile_title = I18n.t(:label_project_plural)

        def blank_title
          if @filtered
            I18n.t("custom_fields.admin.projects.filter_no_results.title")
          else
            I18n.t("custom_fields.admin.projects.empty_state.title")
          end
        end

        def blank_description
          if @filtered
            I18n.t("custom_fields.admin.projects.filter_no_results.description")
          else
            I18n.t("custom_fields.admin.projects.empty_state.description")
          end
        end

        def blank_icon = @filtered ? :search : :project

        private

        def types_by_id
          @types_by_id ||= ::Type.where(id: @type_ids_by_project_id.values.flatten).index_by(&:id)
        end
      end
    end
  end
end

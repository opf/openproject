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

module Admin
  module Settings
    module CustomFields
      class TableComponent < OpPrimer::BorderBoxTableComponent
        options :work_package, :project_counts

        main_column :name
        mobile_columns :name, :field_format, :is_required, :used_in_projects, :contained_in_type
        mobile_labels :field_format, :is_required, :used_in_projects, :contained_in_type

        def main_column?(column)
          super || (work_package && column == :contained_in_type)
        end

        def mobile_title
          I18n.t(:label_custom_field_plural)
        end

        def has_actions?
          true
        end

        def reorderable?
          !work_package
        end

        def columns
          headers.map(&:first)
        end

        def mobile_columns
          super & columns
        end

        def mobile_labels
          super & columns
        end

        def headers
          [
            [:name, { caption: CustomField.human_attribute_name(:name) }],
            [:field_format, { caption: CustomField.human_attribute_name(:field_format) }],
            [:is_required, { caption: CustomField.human_attribute_name(:is_required) }],
            work_package ? [:used_in_projects, { caption: t(:label_used_in_projects) }] : nil,
            work_package ? [:contained_in_type, { caption: t("custom_fields.contained_in_type") }] : nil
          ].compact
        end

        def container_id
          "custom-fields-table"
        end

        def container_data
          return {} unless reorderable?

          {
            controller: "sortable-lists sortable-lists--list",
            sortable_lists_move_url_template_value: drop_url_template,
            sortable_lists_sortable_lists__list_outlet: "##{container_id}",
            sortable_lists_sortable_lists__item_outlet: "##{container_id} [data-controller~='sortable-lists--item']",
            sortable_lists__list_type_value: CustomField::SORTABLE_LIST_TYPE,
            sortable_lists__list_accepted_type_value: CustomField::SORTABLE_LIST_TYPE,
            sortable_lists__list_name_value: mobile_title,
            "sortable-lists--list-rows-container-element": ":scope > .#{rows_container_class}"
          }
        end

        # Built with a sentinel so relative-URL-root installations keep working; {id} is
        # expanded client-side by the sortable-lists controller. url_for(action:) targets
        # the current type's drop route, so the shared component needs no type-specific wiring.
        def drop_url_template
          placeholder = "__id__"
          helpers.url_for(action: :drop, id: placeholder).sub(placeholder, "{id}")
        end

        def blank_title
          t("custom_fields.no_results_title_text")
        end
      end
    end
  end
end

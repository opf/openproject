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
  module CustomFields
    class EditFormHeaderComponent < ApplicationComponent
      include ::CustomFields::AdminRoutes

      def initialize(custom_field:, selected:, section_label:, page_title:, **)
        @custom_field = custom_field
        @selected = selected
        @section_label = section_label
        @page_title = page_title
        super(custom_field, **)
      end

      def tabs
        [details_tab, items_tab, *extra_tabs].compact
      end

      private

      def details_tab
        { name: "edit", path: edit_path(@custom_field), label: t(:label_details) }
      end

      def items_tab
        if @custom_field.hierarchical_list?
          { name: "items", path: custom_field_items_path(@custom_field), label: t(:label_item_plural) }
        elsif @custom_field.list?
          { name: "items", path: list_item_path(@custom_field), label: t(:label_item_plural) }
        end
      end

      def extra_tabs
        return [] unless @custom_field.is_a?(WorkPackageCustomField)

        [{ name: "attribute_help_text", path: attribute_help_text_path(@custom_field),
           label: AttributeHelpText.human_attribute_name(:help_text) }]
      end

      def header_title
        concat @custom_field.attribute_in_database("name")
        concat render(Primer::Beta::Text.new(color: :muted)) { " (#{helpers.label_for_custom_field_format(@custom_field.field_format)})" }
      end

      def breadcrumbs_items
        [
          { href: admin_index_path, text: t(:label_administration) },
          { href: index_path(@custom_field), text: @section_label },
          { href: index_path(@custom_field), text: @page_title },
          helpers.nested_breadcrumb_element(helpers.label_for_custom_field_format(model.field_format),
                                            @custom_field.attribute_in_database("name"))
        ]
      end
    end
  end
end

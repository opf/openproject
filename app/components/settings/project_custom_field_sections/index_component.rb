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

module Settings
  module ProjectCustomFieldSections
    class IndexComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def initialize(project_custom_field_sections:)
        super

        @project_custom_field_sections = project_custom_field_sections
      end

      def row_component_class
        Settings::ProjectCustomFieldSections::ShowComponent
      end

      def first_and_last
        [@project_custom_field_sections.first, @project_custom_field_sections.last]
      end

      private

      def wrapper_data_attributes
        {
          controller: "sortable-lists",
          sortable_lists_position_mode_value: "absolute",
          sortable_lists_move_url_templates_value: move_url_templates.to_json,
          sortable_lists_sortable_lists__list_outlet: "[data-controller~='sortable-lists--list']",
          sortable_lists_sortable_lists__item_outlet: "[data-controller~='sortable-lists--item']"
        }
      end

      def move_url_templates
        {
          custom_field: drop_admin_settings_project_custom_field_path("PLACEHOLDER")
            .gsub("PLACEHOLDER", "{id}"),
          section: drop_admin_settings_project_custom_field_section_path("PLACEHOLDER")
            .gsub("PLACEHOLDER", "{id}")
        }
      end
    end
  end
end

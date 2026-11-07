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

module Settings
  module UserCustomFieldSections
    # A keyboard-reachable way to relocate a field or built-in attribute row
    # to another section.
    module MoveBetweenSections
      private

      def with_move_to_section_submenu(menu, key:, other_sections:)
        return if other_sections.none?

        menu.with_sub_menu_item(label: t("settings.user_custom_field_sections.label_move_to_section")) do |submenu|
          submenu.with_leading_visual_icon(icon: :"arrow-right")

          other_sections.each do |section|
            move_to_section_item(submenu, key:, section:)
          end
        end
      end

      def move_to_section_item(menu, key:, section:)
        menu.with_item(
          label: section.name,
          tag: :button,
          href: drop_admin_settings_user_custom_field_section_field_path(key),
          form_arguments: {
            method: :put,
            inputs: [
              { name: "list_type", value: "user_field" },
              { name: "list_id", value: section.id },
              { name: "prev_id", value: "" } # Move to top of section
            ]
          }
        )
      end
    end
  end
end

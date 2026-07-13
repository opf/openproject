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
  module UserCustomFieldSections
    class IndexComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def initialize(user_custom_field_sections:)
        super

        @user_custom_field_sections = user_custom_field_sections
      end

      def row_component_class
        Settings::UserCustomFieldSections::ShowComponent
      end

      def first_and_last
        [@user_custom_field_sections.first, @user_custom_field_sections.last]
      end

      private

      def wrapper_data_attributes
        {
          controller: "generic-drag-and-drop"
        }
      end

      def drop_target_config
        {
          generic_drag_and_drop_target: "container",
          "target-allowed-drag-type": "section"
        }
      end

      def draggable_item_config(section)
        {
          "draggable-id": section.id,
          "draggable-type": "section",
          "drop-url": drop_admin_settings_user_custom_field_section_path(section)
        }
      end
    end
  end
end

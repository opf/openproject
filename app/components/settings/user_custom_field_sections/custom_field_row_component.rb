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
    class CustomFieldRowComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable
      include ::CustomFields::AdminRoutes
      include SortableLists::MoveMenu

      def initialize(user_custom_field:)
        super()
        @user_custom_field = user_custom_field
      end

      private

      def edit_action_item(menu)
        menu.with_item(label: t("label_edit"),
                       href: edit_path(@user_custom_field),
                       data: { turbo: "false", test_selector: "user-custom-field-edit" }) do |item|
          item.with_leading_visual_icon(icon: :pencil)
        end
      end

      def delete_action_item(menu)
        menu.with_item(label: t("text_destroy"),
                       scheme: :danger,
                       href: deletion_dialog_path(@user_custom_field),
                       content_arguments: { data: { controller: "async-dialog" } }) do |item|
          item.with_leading_visual_icon(icon: :trash)
        end
      end
    end
  end
end

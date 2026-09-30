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

module Users::Invitation::ProjectStep
  class Form < ApplicationForm
    form do |f|
      f.project_autocompleter(
        name: "project_id",
        id: "project_id",
        label: Project.model_name.human,
        required: true,
        autocomplete_options: {
          with_search_icon: true,
          openDirectly: false,
          focusDirectly: false,
          dropdownPosition: "bottom",
          placeholder: I18n.t("users.invite_user_modal.project.required"),
          appendTo: "##{Users::Invitation::DialogComponent::DIALOG_ID}",
          filters: [
            { name: "active", operator: "=", values: ["t"] },
            { name: "user_action", operator: "=", values: ["memberships/create"] }
          ],
          data: {
            "test-selector": "project_id"
          }
        }
      )

      f.radio_button_group(
        name: :principal_type,
        visually_hide_label: true
      ) do |radio_group|
        radio_group.radio_button(
          value: "User",
          checked: model.principal_type.nil? || model.principal_type == "User",
          label: User.model_name.human,
          caption: I18n.t("users.invite_user_modal.type.user.description")
        )
        radio_group.radio_button(
          value: "Group",
          checked: model.principal_type == "Group",
          label: Group.model_name.human,
          caption: I18n.t("users.invite_user_modal.type.group.description")
        )

        radio_group.radio_button(
          value: "PlaceholderUser",
          disabled: !EnterpriseToken.allows_to?(:placeholder_users),
          checked: model.principal_type == "PlaceholderUser",
          label: PlaceholderUser.model_name.human,
          caption: I18n.t("users.invite_user_modal.type.placeholder_user.description")
        )
      end

      unless EnterpriseToken.allows_to?(:placeholder_users)
        f.html_content do
          render(EnterpriseEdition::BannerComponent.new(:placeholder_users,
                                                        dismissable: true,
                                                        dismiss_key: "invitation_placeholder_users"))
        end
      end
    end
  end
end

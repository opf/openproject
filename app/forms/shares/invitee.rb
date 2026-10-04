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
module Shares
  class Invitee < ApplicationForm
    form do |user_invite_form|
      user_invite_form.autocompleter(
        name: :user_id,
        label: I18n.t("sharing.label_search"),
        visually_hide_label: true,
        data: { "shares--user-limit-target": "autocompleter" },
        autocomplete_options: {
          appendTo: "##{Shares::ShareDialogComponent::DIALOG_ID}",
          component: "opce-user-autocompleter",
          defaultData: false,
          id: "op-share-dialog-invite-autocomplete",
          placeholder: I18n.t("sharing.label_search_placeholder"),
          data: {
            "test-selector": "op-share-dialog-invite-autocomplete"
          },
          url: ::API::V3::Utilities::PathHelper::ApiV3Path.principals,
          filters: [{ name: "type", operator: "=", values: %w[User Group] },
                    { name: "id", operator: "!", values: [::Queries::Filters::MeValue::KEY] },
                    { name: "status", operator: "=", values: [Principal.statuses[:active], Principal.statuses[:invited]] }],
          searchKey: "any_name_attribute",
          addTag: allowed_to_invite?,
          addTagText: I18n.t("members.send_invite_to"),
          multiple: true,
          focusDirectly: true,
          appendToComponent: true,
          disabled: @disabled,
          isOpenedInModal: true,
          hoverCards: true
        }
      )
    end

    def initialize(disabled: false)
      super()
      @disabled = disabled
    end

    def allowed_to_invite?
      return true if User.current.allowed_globally?(:create_user)

      if model.entity.respond_to?(:project)
        return User.current.allowed_in_project?(:invite_members_by_email, model.entity.project)
      end

      false
    end
  end
end

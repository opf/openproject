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

module Repositories::Admin
  class WebhookUserForm < ApplicationForm
    form do |f|
      f.autocompleter(
        name: :gitlab_user_id,
        label: model.class.human_attribute_name(:gitlab_user_id),
        caption: I18n.t("repositories.admin.steps.webhook_user.caption"),
        input_width: :large,
        autocomplete_options: {
          component: "opce-user-autocompleter",
          allowEmpty: true,
          defaultData: false,
          model: selected_user
        }
      )
    end

    private

    def selected_user
      user = model.webhook_user
      { id: user.id, name: user.name } if user
    end
  end
end

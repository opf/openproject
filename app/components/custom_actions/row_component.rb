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

module CustomActions
  class RowComponent < ::RowComponent
    def action
      row
    end

    def name
      link_to action.name, edit_custom_action_path(action)
    end

    delegate :description, to: :action

    def sort
      helpers.reorder_links("custom_action", { action: "update", id: action }, method: :put)
    end

    def button_links
      [
        edit_link,
        delete_link
      ]
    end

    def edit_link
      link_to(
        helpers.op_icon("icon icon-edit"),
        helpers.edit_custom_action_path(action),
        title: t(:button_edit)
      )
    end

    def delete_link
      link_to(
        helpers.op_icon("icon icon-delete"),
        helpers.custom_action_path(action),
        data: {
          turbo_method: :delete,
          turbo_confirm: I18n.t(:text_are_you_sure)
        },
        title: t(:button_delete)
      )
    end
  end
end

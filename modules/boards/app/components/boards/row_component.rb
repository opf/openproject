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

module Boards
  class RowComponent < ::RowComponent
    def project_name
      helpers.link_to_project model.project, {}, {}, false
    end

    def name
      link_to model.name, project_work_package_board_path(model.project, model)
    end

    def created_at
      safe_join([helpers.format_date(model.created_at), helpers.format_time(model.created_at, false)], " ")
    end

    def type
      case model.board_type
      when :action
        t("boards.board_types.action", attribute: t(model.board_type_attribute, scope: "boards.board_type_attributes"))
      else
        t("boards.board_types.free")
      end
    end

    def button_links
      [delete_link].compact
    end

    def delete_link
      if render_delete_link?
        link_to(
          "",
          work_package_board_path(model),
          method: :delete,
          class: "icon icon-delete",
          data: {
            confirm: I18n.t(:text_are_you_sure),
            "test-selector": "board-remove-#{model.id}"
          },
          title: t(:button_delete)
        )
      end
    end

    private

    def render_delete_link?
      table.current_project && table.current_user.allowed_in_project?(:manage_board_views, table.current_project)
    end
  end
end

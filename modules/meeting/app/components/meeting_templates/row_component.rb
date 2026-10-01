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

module MeetingTemplates
  class RowComponent < ::OpPrimer::BorderBoxRowComponent
    delegate :current_project, to: :table
    delegate :project, to: :model

    def project_name
      helpers.link_to_project project, {}, {}, false
    end

    def title
      render(Primer::Beta::Link.new(href: project_meeting_path(project, model), font_weight: :bold)) { model.title }
    end

    def button_links
      [action_menu]
    end

    def action_menu
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(
          icon: "kebab-horizontal",
          "aria-label": t(:label_more),
          scheme: :invisible,
          data: { "test-selector": "more-button" }
        )

        edit_action(menu)
        delete_action(menu)
      end
    end

    def edit_action(menu)
      return unless edit_allowed?

      menu.with_item(
        label: I18n.t(:label_meeting_template_edit),
        href: project_meeting_path(project, model)
      ) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
    end

    def delete_action(menu)
      return unless delete_allowed?

      menu.with_item(
        label: I18n.t(:label_meeting_template_delete),
        scheme: :danger,
        href: delete_dialog_project_meeting_path(project, model),
        tag: :a,
        content_arguments: {
          data: { controller: "async-dialog" }
        }
      ) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    def delete_allowed?
      User.current.allowed_in_project?(:delete_meetings, project)
    end

    def edit_allowed?
      User.current.allowed_in_project?(:edit_meetings, project)
    end
  end
end

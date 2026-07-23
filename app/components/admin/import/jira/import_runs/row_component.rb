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

module Admin::Import::Jira::ImportRuns
  class RowComponent < OpPrimer::BorderBoxRowComponent
    def id
      render(
        Primer::Beta::Link.new(
          href: admin_import_jira_run_path(jira_id: model.jira.id, id: model.id),
          font_weight: :bold,
          mr: 1
        )
      ) do
        "#{I18n.t('admin.jira.run.title')} ##{model.id}"
      end +
        render(Admin::Import::Jira::ImportRuns::StatusBadgeComponent.new(model.current_state))
    end

    def last_changed
      helpers.format_time(model.updated_at)
    end

    def projects
      (model.projects || []).pluck("name").join(", ")
    end

    def button_links
      [
        action_menu
      ]
    end

    def action_menu
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(
          scheme: :invisible,
          size: :small,
          icon: :"kebab-horizontal",
          "aria-label": t(:button_actions),
          tooltip_direction: :w
        )
        menu.with_item(scheme: :default, label: I18n.t(:"admin.jira.run.actions.button_edit"),
                       content_arguments: { tag: :a, href: admin_import_jira_run_path(jira_id: model.jira.id, id: model.id) }) do |item|
          item.with_leading_visual_icon(icon: :pencil)
        end
        menu.with_item(scheme: :default, label: I18n.t(:"admin.jira.run.actions.button_open_history"),
                       content_arguments: { tag: :a, href: history_admin_import_jira_run_path(jira_id: model.jira.id, id: model.id) }) do |item|
          item.with_leading_visual_icon(icon: :history)
        end
      end
    end
  end
end

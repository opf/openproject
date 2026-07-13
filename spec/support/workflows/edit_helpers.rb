# frozen_string_literal: true

# -- copyright
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
# ++

module Workflows
  module EditHelpers
    def workflow_checkbox(from_index, to_index)
      "status_#{statuses[from_index].id}_#{statuses[to_index].id}"
    end

    def visit_workflow_edit(roles: [], tab: nil)
      params = {}
      params[:role_ids] = roles.map(&:id) if roles.any?
      params[:tab] = tab if tab
      visit edit_workflow_path(type, **params)
    end

    def switch_role_via_panel(from_role, to_role)
      click_button from_role.name
      find("[data-item-id='#{to_role.id}']").click
      find("[data-item-id='#{from_role.id}']").click
      within("select-panel") { click_button "Apply" }
    end

    def add_status_via_dialog(status)
      within "#workflow-table" do # Otherwise, click on "Statuses" menu item
        click_link "Status"
      end
      within_dialog "Statuses" do
        find(".ng-arrow-wrapper").click
        find(".ng-option", text: status.name).click
        click_button "Apply"
      end
    end

    def remove_status_via_dialog(status)
      within "#workflow-table" do # Otherwise, click on "Statuses" menu item
        click_link "Status"
      end
      within_dialog "Statuses" do
        find(".ng-value", text: status.name).find(".ng-value-icon").click
        click_button "Apply"
      end
    end

    def toggle_select_all_in_column(to_index)
      find(:button, accessible_name: "Toggle transitions from all old statuses to #{statuses[to_index].name}").click
    end

    def toggle_select_all_in_row(from_index)
      find(:button, accessible_name: "Toggle transitions from #{statuses[from_index].name} to all new statuses").click
    end

    def indeterminate?(checkbox_id)
      page.evaluate_script("document.getElementById('#{checkbox_id}')?.indeterminate ?? false")
    end

    def indeterminate_visible?(checkbox_id)
      page.evaluate_script(<<~JS)
        (() => {
          const el = document.getElementById('#{checkbox_id}');
          const bg = window.getComputedStyle(el).backgroundColor;
          return bg !== 'rgba(0, 0, 0, 0)' && bg !== 'rgb(255, 255, 255)';
        })()
      JS
    end

    def expect_transition(role, from_index, to_index, exist:, author: false, assignee: false)
      expect(Workflow.exists?(role_id: role.id, type_id: type.id,
                              old_status_id: statuses[from_index].id,
                              new_status_id: statuses[to_index].id,
                              author:, assignee:)).to be exist
    end
  end
end

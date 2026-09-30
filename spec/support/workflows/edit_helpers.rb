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
      visit edit_type_workflow_path(type, **matrix_params(roles:, tab:))
    end

    def visit_workflow_page(roles: [], tab: nil, workflow: nil)
      visit edit_workflow_path(workflow || type.default_variant.workflow, **matrix_params(roles:, tab:))
    end

    def matrix_params(roles:, tab:)
      params = {}
      params[:role_ids] = roles.map(&:id) if roles.any?
      params[:tab] = tab if tab
      params
    end

    def switch_workflow_to(name)
      open_workflow_picker
      within_test_selector("workflow-panel") { click_link name }
    end

    def open_workflow_picker
      page.find_test_selector("workflow-selector").click
    end

    def choose_workflow_start(name)
      selected = "[data-test-selector='workflow-start-#{name}']:checked"

      retry_block do
        find_test_selector("workflow-start-#{name}").click
        raise "The #{name} option did not take the click" unless page.has_css?(selected, visible: :all, wait: 2)
      end
    end

    def run_workflow_start_dialog(start: "scratch")
      within_dialog I18n.t("workflows.start.title") do
        yield if block_given?
        choose_workflow_start(start)
        click_on I18n.t(:button_continue)
      end
    end

    def open_workflow_create_dialog(start: "scratch", &)
      wait_for_turbo_stream { page.find_test_selector("workflow-create-new").click }
      run_workflow_start_dialog(start:, &)
    end

    def switch_transition_tab(label)
      page.find_test_selector("workflow-transitions-menu").click
      click_link label
    end

    def switch_role_via_panel(from_role, to_role)
      click_button from_role.name
      find("[data-item-id='#{to_role.id}']").click
      find("[data-item-id='#{from_role.id}']").click
      within_test_selector("role-panel") { click_button "Apply" }
    end

    # The reuse mode section offers "Copy from another type", so a bare "Copy" is ambiguous.
    def open_copy_dialog
      within "#workflow-table" do
        click_link I18n.t(:label_copy_workflow_from_role)
      end
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
      expect(Workflows::StatusTransition.exists?(role_id: role.id, workflow_id: type.default_variant.workflow_id,
                              old_status_id: statuses[from_index].id,
                              new_status_id: statuses[to_index].id,
                              author:, assignee:)).to be exist
    end
  end
end

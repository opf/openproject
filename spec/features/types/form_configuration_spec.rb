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

require "spec_helper"

RSpec.describe "form configuration", :js, :selenium do
  shared_let(:admin) { create(:admin) }
  let(:type) { create(:type) }

  let!(:project) { create(:project, types: [type]) }
  let(:category) { create(:category, project:) }
  let(:work_package) do
    create(:work_package,
           project:,
           type:,
           done_ratio: 10,
           category:)
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:form) { Components::Admin::TypeConfigurationForm.new }

  describe "query group actions with EE token", with_ee: %i[edit_attribute_groups] do
    describe "default configuration" do
      let(:dialog) { Components::ConfirmationDialog.new }

      before do
        login_as(admin)
        visit edit_type_form_configuration_path(type)
      end

      def persisted_group_order(type)
        type.reload.attribute_groups.reject { |group| group.key == :__empty }.map(&:translated_key)
      end

      def persisted_attribute_order(type, group_key)
        type.reload.attribute_groups.find { |group| group.key.to_s == group_key.to_s }&.attributes
      end

      it "resets the form properly after changes" do
        form.rename_group("Details", "Whatever")
        form.expect_attribute(key: :assignee)

        # Reset and cancel
        form.reset_button.click
        dialog = find_test_selector("type-form-configuration-reset-dialog", visible: :all)
        within(dialog) do
          click_button I18n.t("js.button_cancel")
        end

        form.expect_group("Whatever", "Whatever")

        # Wait for dialog close animation to finish before opening it again
        expect(page).to have_no_css("dialog[open]")

        # Reset and confirm
        form.reset_button.click
        dialog = find_test_selector("type-form-configuration-reset-dialog", visible: :all)
        within(dialog) do
          click_button I18n.t("button_reset")
        end

        expect(page).to have_no_css("[data-group-key]", text: /\bWhatever\b/)
        form.expect_group("details", "Details")
        form.expect_attribute(key: :assignee)
      end

      it "can remove all groups to be left with an invisible one (Regression #33592)" do
        form.remove_group "Details"
        form.remove_group "Estimates and progress"
        form.remove_group "People"
        form.remove_group "Costs"
        form.remove_group "Other"

        form.expect_empty

        # Test the actual type backend
        type.reload
        expect(type.attribute_groups.count).to eq 1
        expect(type.attribute_groups.first.key).to eq :__empty
        expect(type.attribute_groups.first.attributes).to be_empty

        # Visit work package with that type
        wp_page.visit!
        wp_page.ensure_page_loaded

        wp_page.expect_hidden_field(:version)
        wp_page.expect_hidden_field(:assignee)
        wp_page.expect_hidden_field(:responsible)
        wp_page.expect_hidden_field(:priority)
        wp_page.expect_hidden_field(:date)
        wp_page.expect_hidden_field(:category)
        wp_page.expect_hidden_field(:done_ratio)

        groups = page.all(".attributes-group--header-text").map(&:text)
        expect(groups).to eq []
        expect(page)
          .to have_css(".work-packages--details--description", text: work_package.description)
      end

      it "allows modification of the form configuration" do
        #
        # Test default set of groups
        #
        form.expect_group "people",
                          "People",
                          { key: :assignee, translation: "Assignee" },
                          { key: :responsible, translation: "Accountable" }

        form.expect_group "estimates_and_progress",
                          "Estimates and progress",
                          { key: :estimated_time, translation: "Work" },
                          { key: :remaining_time, translation: "Remaining work" },
                          { key: :percentage_done, translation: "% Complete" },
                          { key: :spent_time, translation: "Spent time" }

        form.expect_group "details",
                          "Details",
                          { key: :category, translation: "Category" },
                          { key: :date, translation: "Date" },
                          { key: :priority, translation: "Priority" },
                          { key: :version, translation: "Version" }

        #
        # Modify configuration
        #

        # Disable version
        form.drag_and_drop(form.find_attribute_handle(:version), form.inactive_group)
        form.expect_inactive(:version)

        # Rename section
        form.rename_group("Details", "Whatever")
        form.rename_group("People", "Cool Stuff")

        # Start renaming, but cancel
        group_key = form.send(:find_group, "Cool Stuff")["data-group-key"]
        form.send(:open_group_menu, "Cool Stuff")
        page.find_test_selector("type-form-configuration-group-rename-#{group_key}", visible: :all).click
        input = find_test_selector("type-form-configuration-group-name-input", wait: 10)
        input.set("FOOBAR")
        page.find_test_selector("type-form-configuration-group-cancel", wait: 10).click
        form.expect_group("Cool Stuff", "Cool Stuff")
        expect(page).to have_no_css("[data-group-key]", text: /\bFOOBAR\b/)

        # Create new group
        form.add_attribute_group("New Group")
        form.move_to(:category, "New Group")

        # Delete attribute from group
        form.remove_attribute("assignee")

        # Expect configuration to be correct now
        form.expect_no_attribute("assignee", "Cool Stuff")

        form.expect_group "Cool Stuff",
                          "Cool Stuff",
                          { key: :responsible, translation: "Accountable" }

        form.expect_group "estimates_and_progress",
                          "Estimates and progress",
                          { key: :estimated_time, translation: "Work" },
                          { key: :remaining_time, translation: "Remaining work" },
                          { key: :percentage_done, translation: "% Complete" },
                          { key: :spent_time, translation: "Spent time" }

        form.expect_group "Whatever",
                          "Whatever",
                          { key: :date, translation: "Date" }

        form.expect_group "New Group",
                          "New Group",
                          { key: :category, translation: "Category" }

        form.expect_inactive(:version)

        # Test the actual type backend
        type.reload
        expect(type.attribute_groups.map(&:key))
          .to include(:people, :estimates_and_progress, :details, "New Group")
        expect(type.attribute_groups.detect { |g| g.key == :people }&.display_name).to eq("Cool Stuff")
        expect(type.attribute_groups.detect { |g| g.key == :details }&.display_name).to eq("Whatever")

        # Visit work package with that type
        wp_page.visit!
        wp_page.ensure_page_loaded

        # Version should be hidden
        wp_page.expect_hidden_field(:version)

        wp_page.expect_group("New Group") do
          wp_page.expect_attributes category: category.name
        end

        wp_page.expect_group("Whatever") do
          wp_page.expect_attributes combinedDate: "no start date - no finish date"
        end

        wp_page.expect_group("Cool Stuff") do
          wp_page.expect_attributes responsible: "-"
        end

        # Empty attributes should be shown on toggle
        wp_page.expect_hidden_field(:assignee)
        wp_page.expect_hidden_field(:spent_time)

        wp_page.expect_group("Estimates and progress") do
          wp_page.expect_attributes estimated_time: "-"
          wp_page.expect_attributes spent_time: "0h"
        end

        # New work package has the same configuration
        wp_page.expect_hidden_field(:assignee)
        wp_page.expect_hidden_field(:spent_time)
        wp_page.click_create_wp_button(type)

        wp_page.expect_group("Estimates and progress") do
          expect(page).to have_css(".inline-edit--container.estimatedTime")
        end

        find_by_id("work-packages--edit-actions-cancel").click
        expect(wp_page).not_to have_alert_dialog
        loading_indicator_saveguard
      end

      context "with field format labels" do
        let!(:custom_field) { create(:issue_custom_field, :integer, name: "MyNumber") }

        before do
          visit edit_type_form_configuration_path(type)
        end

        it "shows field format labels beside attributes" do
          builtin_label = I18n.t("types.edit.form_configuration.builtin_field")

          expect(page.find(form.attribute_selector(:assignee))).to have_text(builtin_label)
          expect(page.find(form.attribute_selector(:date))).to have_text(builtin_label)

          form.move_to(custom_field.attribute_name, "Details")
          expect(page.find(form.attribute_selector(custom_field.attribute_name))).to have_text(I18n.t(:label_integer))
        end
      end

      it "removes a newly added unsaved custom group when canceling edit" do
        initial_order = form.group_order

        form.add_button_dropdown.click

        expect(page).to have_text(I18n.t("types.edit.form_configuration.add_attribute_group"))
        expect(page).to have_text(I18n.t("types.edit.form_configuration.add_query_group"))

        click_on I18n.t("types.edit.form_configuration.add_attribute_group")

        expect(page.find_test_selector("type-form-configuration-group-name-input", wait: 10).value).to eq("")

        page.find_test_selector("type-form-configuration-group-cancel", wait: 10).click
        expect(page).to have_no_test_selector("type-form-configuration-group-name-input")

        expect(form.group_order).to eq(initial_order)
      end

      it "keeps a saved custom group when canceling rename" do
        form.add_attribute_group("Saved custom group")

        visit edit_type_form_configuration_path(type)

        group_key = form.send(:find_group, "Saved custom group")["data-group-key"]
        form.send(:open_group_menu, "Saved custom group")
        page.find_test_selector("type-form-configuration-group-rename-#{group_key}", visible: :all).click

        input = page.find_test_selector("type-form-configuration-group-name-input", wait: 10)
        expect(input.value).to eq("Saved custom group")

        input.set("Renamed group")
        page.find_test_selector("type-form-configuration-group-cancel", wait: 10).click

        form.expect_group("Saved custom group", "Saved custom group")
        expect(page).to have_no_css("[data-group-key]", text: /\bRenamed group\b/)
      end

      it "shows only the edit action for query rows" do
        form.add_query_group("Subtasks", :children)

        menu_id = form.open_query_menu("Subtasks")
        menu_selector = "##{menu_id}"

        expect(page).to have_selector(menu_selector, text: I18n.t("types.edit.form_configuration.edit_query"))
        expect(page).to have_no_selector("#{menu_selector} [role='menuitem']", text: I18n.t("label_agenda_item_move_to_top"))
        expect(page).to have_no_selector("#{menu_selector} [role='menuitem']", text: I18n.t("label_agenda_item_move_up"))
        expect(page).to have_no_selector("#{menu_selector} [role='menuitem']", text: I18n.t("label_agenda_item_move_down"))
        expect(page).to have_no_selector("#{menu_selector} [role='menuitem']", text: I18n.t("label_agenda_item_move_to_bottom"))
        expect(page).to have_no_selector("#{menu_selector} [role='menuitem']", text: I18n.t("button_delete"))
      end

      it "shows only delete for a single attribute row" do
        form.add_attribute_group("New Group")
        form.move_to(:category, "New Group")

        menu_id = form.open_attribute_menu(:category)
        menu_selector = "##{menu_id}"

        expect(page).to have_selector(menu_selector, text: I18n.t("button_delete"))
        expect(page).to have_no_selector("#{menu_selector} [role='menuitem']", text: I18n.t("label_agenda_item_move_to_top"))
        expect(page).to have_no_selector("#{menu_selector} [role='menuitem']", text: I18n.t("label_agenda_item_move_up"))
        expect(page).to have_no_selector("#{menu_selector} [role='menuitem']", text: I18n.t("label_agenda_item_move_down"))
        expect(page).to have_no_selector("#{menu_selector} [role='menuitem']", text: I18n.t("label_agenda_item_move_to_bottom"))
      end

      it "shows move actions only where valid for multi-row groups" do
        details_order = form.attribute_order("Details")

        first_row_menu_id = form.open_attribute_menu(details_order.first)

        within "##{first_row_menu_id}" do
          expect(page).to have_text(I18n.t("label_agenda_item_move_down"))
          expect(page).to have_text(I18n.t("label_agenda_item_move_to_bottom"))
          expect(page).to have_no_text(I18n.t("label_agenda_item_move_to_top"))
          expect(page).to have_no_text(I18n.t("label_agenda_item_move_up"))
          expect(page).to have_text(I18n.t("button_delete"))
        end

        find("body").click

        last_row_menu_id = form.open_attribute_menu(details_order.last)

        within "##{last_row_menu_id}" do
          expect(page).to have_text(I18n.t("label_agenda_item_move_to_top"))
          expect(page).to have_text(I18n.t("label_agenda_item_move_up"))
          expect(page).to have_no_text(I18n.t("label_agenda_item_move_down"))
          expect(page).to have_no_text(I18n.t("label_agenda_item_move_to_bottom"))
          expect(page).to have_text(I18n.t("button_delete"))
        end
      end

      it "opens the query editor from the query row action" do
        form.add_query_group("Subtasks", :children)

        menu_id = form.open_query_menu("Subtasks")

        within "##{menu_id}" do
          click_button I18n.t("types.edit.form_configuration.edit_query")
        end

        expect(page).to have_css(".wp-table--configuration-modal")
      end

      it "reorders and deletes groups via group actions" do
        expected_order = persisted_group_order(type)
        moving_group = expected_order.second
        initial_updated_at = type.updated_at

        form.invoke_group_action(moving_group, I18n.t("label_agenda_item_move_up"))
        wait_for { type.reload.updated_at }.not_to eq(initial_updated_at)
        index = expected_order.index(moving_group)
        expected_order[index], expected_order[index - 1] = expected_order[index - 1], expected_order[index]
        expect(persisted_group_order(type)).to eq(expected_order)

        initial_updated_at = type.updated_at
        form.invoke_group_action(moving_group, I18n.t("label_agenda_item_move_to_bottom"))
        wait_for { type.reload.updated_at }.not_to eq(initial_updated_at)
        expected_order.delete(moving_group)
        expected_order << moving_group
        expect(persisted_group_order(type)).to eq(expected_order)

        initial_updated_at = type.updated_at
        form.invoke_group_action(moving_group, I18n.t("label_agenda_item_move_up"))
        wait_for { type.reload.updated_at }.not_to eq(initial_updated_at)
        index = expected_order.index(moving_group)
        expected_order[index], expected_order[index - 1] = expected_order[index - 1], expected_order[index]
        expect(persisted_group_order(type)).to eq(expected_order)

        initial_updated_at = type.updated_at
        form.invoke_group_action(moving_group, I18n.t("label_agenda_item_move_to_top"))
        wait_for { type.reload.updated_at }.not_to eq(initial_updated_at)
        expected_order.delete(moving_group)
        expected_order.unshift(moving_group)
        expect(persisted_group_order(type)).to eq(expected_order)

        deleted_group = expected_order.last
        initial_updated_at = type.updated_at
        accept_confirm I18n.t("types.edit.form_configuration.confirm_delete_group") do
          form.invoke_group_action(deleted_group, I18n.t("button_delete"))
        end
        wait_for { type.reload.updated_at }.not_to eq(initial_updated_at)
        expected_order.delete(deleted_group)
        expect(persisted_group_order(type)).to eq(expected_order)
      end

      it "reorders and deletes attribute rows via row actions" do
        expected_order = persisted_attribute_order(type, :details)
        moving_attribute = expected_order.second
        initial_updated_at = type.updated_at

        form.invoke_attribute_action(moving_attribute, I18n.t("label_agenda_item_move_up"))
        wait_for { type.reload.updated_at }.not_to eq(initial_updated_at)
        index = expected_order.index(moving_attribute)
        expected_order[index], expected_order[index - 1] = expected_order[index - 1], expected_order[index]
        expect(persisted_attribute_order(type, :details)).to eq(expected_order)

        initial_updated_at = type.updated_at
        form.invoke_attribute_action(moving_attribute, I18n.t("label_agenda_item_move_down"))
        wait_for { type.reload.updated_at }.not_to eq(initial_updated_at)
        index = expected_order.index(moving_attribute)
        expected_order[index], expected_order[index + 1] = expected_order[index + 1], expected_order[index]
        expect(persisted_attribute_order(type, :details)).to eq(expected_order)

        initial_updated_at = type.updated_at
        form.invoke_attribute_action(moving_attribute, I18n.t("label_agenda_item_move_to_bottom"))
        wait_for { type.reload.updated_at }.not_to eq(initial_updated_at)
        expected_order.delete(moving_attribute)
        expected_order << moving_attribute
        expect(persisted_attribute_order(type, :details)).to eq(expected_order)

        initial_updated_at = type.updated_at
        form.invoke_attribute_action(moving_attribute, I18n.t("label_agenda_item_move_up"))
        wait_for { type.reload.updated_at }.not_to eq(initial_updated_at)
        index = expected_order.index(moving_attribute)
        expected_order[index], expected_order[index - 1] = expected_order[index - 1], expected_order[index]
        expect(persisted_attribute_order(type, :details)).to eq(expected_order)

        initial_updated_at = type.updated_at
        form.invoke_attribute_action(moving_attribute, I18n.t("label_agenda_item_move_to_top"))
        wait_for { type.reload.updated_at }.not_to eq(initial_updated_at)
        expected_order.delete(moving_attribute)
        expected_order.unshift(moving_attribute)
        expect(persisted_attribute_order(type, :details)).to eq(expected_order)

        initial_updated_at = type.updated_at
        form.invoke_attribute_action(moving_attribute, I18n.t("button_delete"))
        wait_for { type.reload.updated_at }.not_to eq(initial_updated_at)
        expected_order.delete(moving_attribute)
        expect(persisted_attribute_order(type, :details)).to eq(expected_order)
      end
    end

    describe "required custom field" do
      let(:custom_fields) { [custom_field] }
      let(:custom_field) { create(:issue_custom_field, :integer, is_required: true, name: "MyNumber") }
      let(:cf_identifier) { custom_field.attribute_name }
      let(:cf_identifier_api) { cf_identifier.camelcase(:lower) }

      before do
        project
        custom_field

        login_as(admin)
        visit edit_type_form_configuration_path(type)
      end

      it "shows the field" do
        # Should be initially disabled
        form.expect_inactive(cf_identifier)
        form.expect_attribute(key: cf_identifier, translation: "MyNumber")

        # Add into new group
        form.add_attribute_group("New Group")
        form.move_to(cf_identifier, "New Group")
        form.expect_attribute(key: cf_identifier, translation: "MyNumber")
      end
    end

    describe "custom fields" do
      let(:project_cf_settings_page) { Pages::Projects::Settings::WorkPackageCustomFields.new(project) }

      let(:custom_fields) { [custom_field] }
      let(:custom_field) { create(:issue_custom_field, :integer, name: "MyNumber") }
      let(:cf_identifier) { custom_field.attribute_name }
      let(:cf_identifier_api) { cf_identifier.camelcase(:lower) }

      def add_cf_to_group
        project
        custom_field

        login_as(admin)
        visit edit_type_form_configuration_path(type)

        # Should be initially disabled
        form.expect_inactive(cf_identifier)

        # Add into new group
        form.add_attribute_group("New Group")
        form.move_to(cf_identifier, "New Group")

        # Make visible
        form.expect_attribute(key: cf_identifier)
      end

      context "if inactive in project" do
        it "can be added to the type, but is not shown" do
          add_cf_to_group

          # Visit work package with that type
          wp_page.visit!
          wp_page.ensure_page_loaded

          # CF should be hidden
          wp_page.expect_no_group("New Group")
          wp_page.expect_attribute_hidden(cf_identifier_api)

          # Enable in project, should then be visible
          project_cf_settings_page.visit!
          expect(page).to have_css(".custom-field-#{custom_field.id} td", text: "MyNumber")
          expect(page).to have_css(".custom-field-#{custom_field.id} td", text: type.name)

          id_checkbox = find("input[name='project[work_package_custom_field_ids][]'][value='#{custom_field.id}']")
          expect(id_checkbox).not_to be_checked
          id_checkbox.set(true)

          click_button "Save"

          # Visit work package with that type
          wp_page.visit!
          wp_page.ensure_page_loaded

          # Category should be hidden
          wp_page.expect_group("New Group") do
            wp_page.expect_attributes cf_identifier_api => "-"
          end
        end
      end

      context "if active in project" do
        let(:project) do
          create(:project,
                 types: [type],
                 work_package_custom_fields: custom_fields)
        end

        it "can be added to type and is visible" do
          add_cf_to_group

          # Visit work package with that type
          wp_page.visit!
          wp_page.ensure_page_loaded

          # Category should be hidden
          wp_page.expect_group("New Group") do
            wp_page.expect_attributes cf_identifier_api => "-"
          end

          # Ensure CF is checked
          project_cf_settings_page.visit!
          expect(page).to have_css(".custom-field-#{custom_field.id} td", text: "MyNumber")
          expect(page).to have_css(".custom-field-#{custom_field.id} td", text: type.name)
          expect(page).to have_css("input[name='project[work_package_custom_field_ids][]'][value='#{custom_field.id}'][checked]")
        end
      end
    end
  end

  describe "without EE token", with_ee: false do
    it "hides protected group actions" do
      login_as(admin)
      visit edit_type_form_configuration_path(type)

      expect(page).to have_no_test_selector("type-form-configuration-add-button")

      menu_id = form.send(:open_group_menu, "Details")
      within "##{menu_id}" do
        expect(page).to have_no_text(I18n.t("types.edit.form_configuration.rename_group"))
        expect(page).to have_no_text(I18n.t("button_delete"))
      end
    end

    it "hides protected query group actions" do
      query = build(:global_query, user_id: 0)
      type.attribute_groups = [["Subtasks", [query]]]
      type.save!

      login_as(admin)
      visit edit_type_form_configuration_path(type)

      expect(page).to have_no_test_selector("type-form-configuration-query-actions-Subtasks")
    end
  end

  describe "with EE token", with_ee: %i[edit_attribute_groups] do
    it "shows protected group actions" do
      login_as(admin)
      visit edit_type_form_configuration_path(type)

      menu_id = form.send(:open_group_menu, "Details")
      within "##{menu_id}" do
        expect(page).to have_text(I18n.t("types.edit.form_configuration.rename_group"))
        expect(page).to have_text(I18n.t("button_delete"))
      end
    end
  end

  describe "form submission", :js, with_ee: %i[edit_attribute_groups] do
    it "only creates one group per add action" do
      call_count = 0
      subscription =
        ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*, payload|
          payload => { controller:, action: }
          if controller == "WorkPackageTypes::FormConfigurationGroupsTabController" && action == "create"
            call_count += 1
          end
        end

      login_as(admin)
      visit edit_type_form_configuration_path(type)

      form.expect_group("details", "Details")
      form.add_attribute_group("New Group")

      ActiveSupport::Notifications.unsubscribe(subscription)
      expect(call_count).to eq(1), "Expected 1 group creation but got #{call_count}"
    end
  end
end

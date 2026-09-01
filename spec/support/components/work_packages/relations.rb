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

require "support/components/autocompleter/ng_select_autocomplete_helpers"
require "support/flash/expectations"

module Components
  module WorkPackages
    class Relations
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include Flash::Expectations
      include RSpec::Matchers
      include RSpec::Wait
      include ::Components::Autocompleter::NgSelectAutocompleteHelpers

      attr_reader :work_package

      def initialize(work_package = nil)
        @work_package = work_package
      end

      def find_relatable(relatable)
        case relatable
        when WorkPackage
          relatable
        when Relation
          relatable.other_work_package(work_package)
        else
          raise "Unknown relatable type: #{relatable.class}"
        end
      end

      def expect_tab_is_loaded
        # Search the current window in order to avoid within scope restrictions
        within_window(page.current_window) do
          within("wp-relations-tab") do
            expect(page).to have_no_css("op-content-loader", wait: 10)
          end
        end
      end

      def expect_add_relation_button
        expect(page).to have_test_selector("add-relation-action-menu", wait: 10)
      end

      def expect_no_add_relation_button
        expect_tab_is_loaded # Make sure the tab is loaded before checking non existing elements
        expect(page).not_to have_test_selector("add-relation-action-menu")
      end

      def find_row(relatable)
        actual_relatable = find_relatable(relatable)
        page.find_test_selector("op-relation-row-visible-#{actual_relatable.id}", wait: 10)
      end

      def find_ghost_row(relatable)
        actual_relatable = find_relatable(relatable)
        page.find_test_selector("op-relation-row-ghost-#{actual_relatable.id}", wait: 10)
      end

      def find_some_row(text:)
        page.find("[data-test-selector^='op-relation-row']", text:, wait: 5)
      end

      def expect_no_row(relatable)
        expect_tab_is_loaded # Make sure the tab is loaded before checking non existing elements
        actual_relatable = find_relatable(relatable)
        expect(page).not_to have_test_selector("op-relation-row-visible-#{actual_relatable.id}"),
                            "expected no relation row for work package " \
                            "##{actual_relatable.id} #{actual_relatable.subject.inspect}"
      end

      def select_relation_type(relation_type)
        within_add_relation_action_menu(relation_type:) do
          click_link_or_button relation_type
        end
      end

      def expect_new_relation_type(relation_type)
        within_add_relation_action_menu(relation_type:) do
          expect(page).to have_link(relation_type, wait: 1)
        end
      end

      def expect_no_new_relation_type(relation_type)
        within_add_relation_action_menu(relation_type:) do
          expect(page).to have_no_link(relation_type, wait: 1)
        end
      end

      def expect_no_add_menu_sub_menu
        within(add_relation_action_menu) do
          expect(page).to have_no_link("add_relation_sub_menu", wait: 1)
        end
      end

      def open_add_relation_action_menu
        return if add_relation_action_menu.visible?

        new_relation_button.click
      end

      def open_relation_sub_menu
        return if add_relation_sub_menu.visible?

        new_relation_sub_menu_button.click
      end

      def add_relation_action_menu
        action_menu_id = new_relation_button["aria-controls"]
        page.find(id: action_menu_id, visible: :all)
      end

      def add_relation_sub_menu
        action_menu_id = new_relation_sub_menu_button["aria-controls"]
        page.find(id: action_menu_id, visible: :all)
      end

      def new_relation_button
        page.find(id: "add-relation-action-menu-button", wait: 10)
      end

      def new_relation_sub_menu_button
        page.find(id: "add-relation-sub-menu-button")
      end

      def remove_relation(relatable)
        actual_relatable = find_relatable(relatable)

        remove_relation_with_work_package(actual_relatable)
      end

      def relatable_action_menu(relatable)
        actual_relatable = find_relatable(relatable)
        page.find_test_selector("op-relation-row-#{actual_relatable.id}-action-menu")
      end

      def expect_relatable_action_menu(relatable)
        actual_relatable = find_relatable(relatable)
        expect(page).to have_test_selector("op-relation-row-#{actual_relatable.id}-action-menu")
      end

      def expect_no_relatable_action_menu(relatable)
        actual_relatable = find_relatable(relatable)
        expect(page).not_to have_test_selector("op-relation-row-#{actual_relatable.id}-action-menu")
      end

      def relatable_edit_button(relatable)
        actual_relatable = find_relatable(relatable)
        page.find_test_selector("op-relation-row-#{actual_relatable.id}-edit-button")
      end

      def relatable_delete_button(relatable)
        actual_relatable = find_relatable(relatable)
        page.find_test_selector("op-relation-row-#{actual_relatable.id}-delete-button")
      end

      def expect_relatable_delete_button(relatable)
        actual_relatable = find_relatable(relatable)
        expect(page).to have_test_selector("op-relation-row-#{actual_relatable.id}-delete-button")
      end

      def expect_no_relatable_delete_button(relatable)
        actual_relatable = find_relatable(relatable)
        expect(page).not_to have_test_selector("op-relation-row-#{actual_relatable.id}-delete-button")
      end

      def add_predecessor(work_package)
        add_relation(type: :follows, relatable: work_package)
      end

      def add_relation(type:, relatable:, description: nil)
        i18n_namespace = "#{WorkPackageRelationsTab::IndexComponent::I18N_NAMESPACE}.relations"
        # Open create form

        SeleniumHubWaiter.wait

        label_text_for_relation_type = I18n.t("#{i18n_namespace}.label_#{type}_singular")

        select_relation_type label_text_for_relation_type.capitalize

        wait_for_reload if using_cuprite?

        # Labels to expect
        modal_heading_label = "Add #{label_text_for_relation_type}"
        expect(page).to have_text(modal_heading_label)

        # Enter the query and select the child
        search_in_autocompleter(relatable)

        if description.present?
          fill_in "Description", with: description
        end

        click_link_or_button "Add"

        wait_for_reload if using_cuprite?

        label_text_for_relation_type_pluralized = I18n.t("#{i18n_namespace}.label_#{type}_plural").capitalize

        wait_for { page }.to have_no_text(modal_heading_label)
        wait_for { page }.to have_text(label_text_for_relation_type_pluralized)

        new_relation = work_package.reload.relations.last
        target_wp = new_relation.other_work_package(work_package)
        find_row(target_wp)
      end

      def search_in_autocompleter(relatable)
        autocomplete_field = page.find_test_selector("work-package-relation-form-to-id")
        select_autocomplete(autocomplete_field,
                            query: relatable.subject,
                            results_selector: "body")
      end

      def edit_relation_description(relatable, description)
        open_relation_dialog(relatable)

        within "##{WorkPackageRelationsTab::WorkPackageRelationDialogComponent::DIALOG_ID}" do
          expect(page).to have_field("Work package", readonly: true)
          expect(page).to have_field("Description")

          fill_in "Description", with: description

          click_link_or_button "Save"

          wait_for_reload if using_cuprite?
        end
      end

      def edit_lag_of_relation(relatable, lag)
        open_relation_dialog(relatable)

        within "##{WorkPackageRelationsTab::WorkPackageRelationDialogComponent::DIALOG_ID}" do
          expect(page).to have_field("Work package", readonly: true)
          expect(page).to have_field("Lag")

          fill_in "Lag", with: lag

          click_link_or_button "Save"

          wait_for_reload if using_cuprite?
        end
      end

      def open_relation_dialog(relatable)
        open_action_menu_with_work_package(relatable) do
          relatable_edit_button(relatable).click
        end

        wait_for_reload if using_cuprite?
      end

      def expect_relation(relatable)
        find_row(relatable)
      end

      def expect_closest_relation(relatable)
        expect(find_row(relatable)).to have_primer_label("Closest", scheme: :primary)
      end

      def expect_not_closest_relation(relatable)
        expect(find_row(relatable)).to have_no_primer_label("Closest", scheme: :primary)
      end

      def expect_ghost_relation(relatable)
        find_ghost_row(relatable)
      end

      def expect_relation_by_text(text)
        find_some_row(text:)
      end

      def expect_no_relation(relatable)
        expect_no_row(relatable)
      end

      def expect_no_relations
        expect(page).to have_test_selector("no-relations-blankslate", text: "This work package does not have any relations yet.")
      end

      def add_parent(work_package)
        # Open the parent edit
        SeleniumHubWaiter.wait
        find(".wp-relation--parent-change").click

        # Enter the query and select the child
        SeleniumHubWaiter.wait
        autocomplete = page.find_test_selector("wp-relations-autocomplete")
        select_autocomplete autocomplete,
                            query: work_package.subject,
                            results_selector: ".ng-dropdown-panel-items"
      end

      def expect_parent(work_package)
        expect(page).to have_test_selector "op-wp-breadcrumb-parent",
                                           text: work_package.subject,
                                           wait: 10
      end

      def expect_no_parent
        expect_tab_is_loaded # Make sure the tab is loaded before checking non existing elements
        expect(page).not_to have_test_selector "op-wp-breadcrumb-parent", wait: 10
      end

      def remove_parent
        SeleniumHubWaiter.wait
        find(".wp-relation--parent-remove").click
      end

      def children_table
        page.find_test_selector("op-relation-group-child")
      end

      def add_existing_child(work_package)
        SeleniumHubWaiter.wait

        retry_block do
          select_relation_type "Child"
        end

        within "##{WorkPackageRelationsTab::AddWorkPackageHierarchyFormComponent::DIALOG_ID}" do
          autocomplete_field = page.find_test_selector("work-package-hierarchy-form-id")
          select_autocomplete(autocomplete_field,
                              query: work_package.subject,
                              results_selector: "body")

          click_link_or_button "Save"
        end
        expect_and_dismiss_flash(message: "Successful update.")
      end

      def add_parent_relation(work_package)
        SeleniumHubWaiter.wait

        retry_block do
          select_relation_type "Parent"
        end

        within "##{WorkPackageRelationsTab::AddWorkPackageHierarchyFormComponent::DIALOG_ID}" do
          autocomplete_field = page.find_test_selector("work-package-hierarchy-form-id")
          select_autocomplete(autocomplete_field,
                              query: work_package.subject,
                              results_selector: "body")

          click_link_or_button "Save"
        end
        expect_and_dismiss_flash(message: "Successful update.")
      end

      def expect_parent_relation(work_package)
        expect_relation_group(Relation::TYPE_PARENT)
        find_row(work_package)
      end

      def relations_group
        page.find_by_id("work-package-relations-tab-content")
      end

      def expect_relation_group(group_type)
        expect(page).to have_test_selector("op-relation-group-#{group_type}", wait: 20)
      end

      def expect_child(work_package)
        find_row(work_package)
      end

      def expect_not_child(work_package)
        expect_no_row(work_package)
      end

      def remove_child(work_package)
        remove_relation_with_work_package(work_package)
      end

      # Removes the parent using the parent relation item (not using the cross
      # button from hierarchy breadcrumb at the top)
      def remove_parent_relation(work_package)
        remove_relation_with_work_package(work_package)
      end

      private

      def within_add_relation_action_menu(relation_type:, &)
        open_add_relation_action_menu
        open_relation_sub_menu unless first_level_relation?(relation_type)
        within(add_relation_action_menu, &)
      end

      def remove_relation_with_work_package(relatable)
        open_action_menu_with_work_package(relatable) do
          accept_confirm do
            relatable_delete_button(relatable).click
          end
        end

        expect_no_row(relatable)
      end

      def open_action_menu_with_work_package(relatable)
        retry_block do
          relatable_row = find_row(relatable)
          within(relatable_row) do
            relatable_action_menu(relatable).click
            yield
          end
        end
      end

      def first_level_relation?(relation_type)
        ["Related To", "Create new child", "Child", "Parent", "Predecessor (before)", "Successor (after)"].include?(relation_type)
      end
    end
  end
end

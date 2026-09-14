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

RSpec.describe "Primerized work package relations tab",
               :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[add_work_packages
                           manage_subtasks
                           manage_work_package_relations
                           view_work_packages]
           })
  end

  before_all do
    set_factory_default(:user, user)
    set_factory_default(:project, project)
    set_factory_default(:project_with_types, project)
  end

  shared_let(:parent_work_package) { create(:work_package, subject: "parent_work_package") }
  shared_let(:work_package) { create(:work_package, subject: "work_package (main)", parent: parent_work_package) }
  shared_let(:type1) { create(:type) }
  shared_let(:type2) { create(:type) }

  shared_let(:wp_predecessor1) do
    create(:work_package, type: type1, subject: "wp_predecessor1",
                          start_date: Date.current, due_date: Date.current + 1.week)
  end
  shared_let(:wp_predecessor2) do
    create(:work_package, type: type1, subject: "wp_predecessor2",
                          start_date: Date.current, due_date: Date.current + 2.weeks)
  end
  shared_let(:wp_related) { create(:work_package, type: type2, subject: "wp_related") }
  shared_let(:wp_blocker) { create(:work_package, type: type1, subject: "wp_blocker") }

  shared_let(:relation_follows1) do
    create(:relation,
           from: work_package,
           to: wp_predecessor1,
           relation_type: Relation::TYPE_FOLLOWS)
  end
  shared_let(:relation_follows2) do
    create(:relation,
           from: work_package,
           to: wp_predecessor2,
           relation_type: Relation::TYPE_FOLLOWS)
  end
  shared_let(:relation_relates) do
    create(:relation,
           from: work_package,
           to: wp_related,
           relation_type: Relation::TYPE_RELATES)
  end
  shared_let(:relation_blocked) do
    create(:relation,
           from: wp_blocker,
           to: work_package,
           relation_type: Relation::TYPE_BLOCKED)
  end
  shared_let(:child_wp) do
    create(:work_package,
           subject: "child_wp",
           parent: work_package,
           type: type1,
           project: project)
  end

  # The user should not be able to see any relations to work packages from this
  # project because the user does not have the permissions to view this project
  shared_let(:restricted_project) { create(:project) }
  shared_let(:restricted_work_package) do
    create(:work_package,
           subject: "restricted_work_package",
           project: restricted_project)
  end
  shared_let(:restricted_child_work_package) do
    create(:work_package,
           subject: "restricted_child_work_package",
           parent: work_package,
           start_date: Time.zone.today,
           project: restricted_project)
  end
  shared_let(:restricted_relation_relates) do
    create(:relation,
           from: work_package,
           to: restricted_work_package,
           relation_type: Relation::TYPE_RELATES)
  end

  let(:relations_tab) { Components::WorkPackages::Relations.new(work_package) }
  let(:relations_panel_selector) { ".detail-panel--relations" }
  let(:relations_panel) { find(relations_panel_selector) }
  let(:work_packages_page) { Pages::PrimerizedSplitWorkPackage.new(work_package) }
  let(:tabs) { Components::WorkPackages::PrimerizedTabs.new }
  let(:additional_setup) do
    # Nothing but contexts might overwrite it
  end

  current_user { user }

  def label_for_relation_type(relation_type)
    I18n.t("work_package_relations_tab.relations.label_#{relation_type}_plural").capitalize
  end

  before do
    additional_setup
    work_packages_page.visit_tab!("relations")
    expect_angular_frontend_initialized
    work_packages_page.expect_subject
    loading_indicator_saveguard
  end

  describe "rendering" do
    it "renders the relations tab" do
      scroll_to_element relations_panel

      wait_for_network_idle

      expect(page).to have_css(relations_panel_selector)

      tabs.expect_counter("relations", 8)

      relations_tab.expect_not_closest_relation(relation_follows1)
      relations_tab.expect_closest_relation(relation_follows2)
      relations_tab.expect_relation(relation_relates)
      relations_tab.expect_relation(relation_blocked)
      relations_tab.expect_relation(parent_work_package)

      # Relations not visible due to lack of permissions on the project
      relations_tab.expect_ghost_relation(restricted_relation_relates)
      relations_tab.expect_ghost_relation(restricted_child_work_package)
    end

    it "renders ghost children" do
      scroll_to_element relations_panel

      wait_for_network_idle

      restricted_child_row = relations_panel.find(
        "[data-test-selector='op-relation-row-ghost-#{restricted_child_work_package.id}']"
      )

      within(restricted_child_row) do
        expect(restricted_child_row).to have_no_css(
          "[data-test-selector='op-relation-row-#{restricted_child_work_package.id}-action-menu']"
        )

        expect(restricted_child_row).to have_text(Time.zone.today.strftime("%m/%d/%Y").to_s)
      end
    end
  end

  describe "deletion" do
    it "can delete relations" do
      scroll_to_element relations_panel

      wait_for_network_idle

      relations_tab.remove_relation(relation_follows1)

      expect { relation_follows1.reload }.to raise_error(ActiveRecord::RecordNotFound)

      tabs.expect_counter("relations", 7)

      # Relations not visible due to lack of permissions on the project
      relations_tab.expect_ghost_relation(restricted_relation_relates)
      relations_tab.expect_ghost_relation(restricted_child_work_package)
    end

    it "can delete parent" do
      scroll_to_element relations_panel

      wait_for_network_idle

      relations_tab.remove_parent_relation(parent_work_package)
      expect(work_package.reload.parent).to be_nil

      tabs.expect_counter("relations", 7)

      # Relations not visible due to lack of permissions on the project
      relations_tab.expect_ghost_relation(restricted_relation_relates)
      relations_tab.expect_ghost_relation(restricted_child_work_package)
    end

    it "can delete children" do
      scroll_to_element relations_panel

      wait_for_network_idle

      relations_tab.remove_child(child_wp)
      expect(child_wp.reload.parent).to be_nil

      tabs.expect_counter("relations", 7)

      # Relations not visible due to lack of permissions on the project
      relations_tab.expect_ghost_relation(restricted_relation_relates)
      relations_tab.expect_ghost_relation(restricted_child_work_package)
    end
  end

  describe "editing" do
    it "renders an edit form" do
      scroll_to_element relations_panel

      wait_for_network_idle

      relation_row = relations_tab.expect_relation(relation_follows1)

      relations_tab.edit_relation_description(relation_follows1, "Discovered relations have descriptions!")

      relations_tab.edit_lag_of_relation(relation_follows1, 5)

      # Reflects new description and lag
      expect(relation_row).to have_text("Discovered relations have descriptions!")
      expect(relation_row).to have_text("5 days")

      # Unchanged
      tabs.expect_counter("relations", 8)
      relations_tab.expect_ghost_relation(restricted_relation_relates)
      relations_tab.expect_ghost_relation(restricted_child_work_package)

      # Edit again
      relations_tab.edit_relation_description(relation_follows1, "And they can be edited!")

      # Reflects new description
      expect(relation_row).to have_text("And they can be edited!")

      # Unchanged
      tabs.expect_counter("relations", 8)

      # Relations not visible due to lack of permissions on the project
      relations_tab.expect_ghost_relation(restricted_relation_relates)
      relations_tab.expect_ghost_relation(restricted_child_work_package)
    end

    it "does not have an edit action for parent and children" do
      scroll_to_element relations_panel

      wait_for_network_idle

      child_row = relations_panel.find("[data-test-selector='op-relation-row-visible-#{child_wp.id}']")

      within(child_row) do
        page.find("[data-test-selector='op-relation-row-#{child_wp.id}-action-menu']").click
        expect(page).to have_no_css("[data-test-selector='op-relation-row-#{child_wp.id}-edit-button']")
      end

      parent_row = relations_panel.find("[data-test-selector='op-relation-row-visible-#{parent_work_package.id}']")

      within(parent_row) do
        page.find("[data-test-selector='op-relation-row-#{parent_work_package.id}-action-menu']").click
        expect(page).to have_no_css("[data-test-selector='op-relation-row-#{parent_work_package.id}-edit-button']")
      end
    end

    it "does not show the lag field for all relation types" do
      scroll_to_element relations_panel

      relations_tab.open_relation_dialog(relation_relates)

      within "##{WorkPackageRelationsTab::WorkPackageRelationDialogComponent::DIALOG_ID}" do
        expect(page).to have_field("Work package", readonly: true)
        expect(page).to have_no_field("Lag")
      end
    end

    context "with the shown WorkPackage being the 'to' relation part" do
      let(:another_wp) { create(:work_package, type: type2, subject: "Successor of main") }

      let(:relation_to) do
        create(:relation,
               from: another_wp,
               to: work_package,
               relation_type: Relation::TYPE_FOLLOWS)
      end

      let(:additional_setup) do
        relation_to
      end

      it "shows the correct related WorkPackage in the dialog (regression #59771)" do
        scroll_to_element relations_panel

        wait_for_network_idle

        relations_tab.open_relation_dialog(another_wp)

        within "##{WorkPackageRelationsTab::WorkPackageRelationDialogComponent::DIALOG_ID}" do
          expect(page).to have_field("Work package",
                                     readonly: true,
                                     with: "#{another_wp.type.name.upcase} ##{another_wp.id} - #{another_wp.subject}")
        end
      end
    end
  end

  describe "creating a relation" do
    let(:wp_successor) { create(:work_package, type: type1, subject: "successor of main") }
    let(:wp_blocks) { create(:work_package, type: type1, subject: "I am blocking") }

    it "renders the new relation form for the selected type and creates the relation" do
      scroll_to_element relations_panel

      wait_for_network_idle

      relations_tab.add_relation(type: :precedes,
                                 relatable: wp_successor,
                                 description: "Discovered relations have descriptions!")
      relations_tab.expect_relation(wp_successor)

      # Bumped by one
      tabs.expect_counter("relations", 9)
      # Relation is created
      expect(Relation.follows.where(from: wp_successor, to: work_package)).to exist

      # Ghost relations are shown here due to lack of permissions on the project
      relations_tab.expect_ghost_relation(restricted_relation_relates)
      relations_tab.expect_ghost_relation(restricted_child_work_package)
    end

    it "renders an error when there is no WP selected (regression #60869)" do
      scroll_to_element relations_panel

      wait_for_network_idle

      relations_tab.select_relation_type("Blocked by")

      wait_for_network_idle

      wait_for_turbo_stream { click_link_or_button "Add" }

      expect(page).to have_text "The selected work package could not be found."

      relations_tab.search_in_autocompleter(wp_blocks)

      wait_for_turbo_stream { click_link_or_button "Add" }

      relations_tab.expect_relation(wp_blocks)

      # Bumped by one
      tabs.expect_counter("relations", 9)
      # Relation is created
      expect(Relation.blocks.where(from: wp_blocks, to: work_package)).to exist
    end

    it "does not autocomplete unrelatable work packages" do
      # wp_predecessor1 is already related to work_package as relation_follows
      # in a predecessor relation, so it should not be autocompleteable anymore
      # under the "Predecessor (before)" type
      relations_tab.select_relation_type "Predecessor (before)"

      wait_for_reload

      within "##{WorkPackageRelationsTab::WorkPackageRelationFormComponent::DIALOG_ID}" do
        expect(page).to have_text("Add predecessor (before)")

        autocomplete_field = page.find("[data-test-selector='work-package-relation-form-to-id']")
        search_autocomplete(autocomplete_field,
                            query: wp_predecessor1.subject,
                            results_selector: "body")
        expect_no_ng_option(autocomplete_field,
                            wp_predecessor1.subject,
                            results_selector: "body")
      end
    end
  end

  describe "attaching a child" do
    shared_let(:not_child_yet_wp) do
      create(:work_package,
             subject: "not_child_yet_wp",
             type: type1,
             project:)
    end

    it "renders the new child form and creates the child relationship" do
      scroll_to_element relations_panel

      wait_for_network_idle

      tabs.expect_counter("relations", 8)

      relations_tab.add_existing_child(not_child_yet_wp)
      relations_tab.expect_child(not_child_yet_wp)

      # Bumped by one
      tabs.expect_counter("relations", 9)

      # Child relation is created
      expect(not_child_yet_wp.reload.parent).to eq work_package

      # Ghost relations are shown here due to lack of permissions on the project
      relations_tab.expect_ghost_relation(restricted_relation_relates)
      relations_tab.expect_ghost_relation(restricted_child_work_package)
    end

    it "doesn't autocomplete parent, children, and WP itself" do
      relations_tab.select_relation_type "Child"

      wait_for_reload

      within "##{WorkPackageRelationsTab::AddWorkPackageHierarchyFormComponent::DIALOG_ID}" do
        autocomplete_field = page.find("[data-test-selector='work-package-hierarchy-form-id']")

        # It doesn't autocomplete children
        search_autocomplete(autocomplete_field,
                            query: child_wp.subject,
                            results_selector: "body")

        expect_no_ng_option(autocomplete_field,
                            child_wp.subject,
                            results_selector: "body")

        # It doesn't autocomplete parent
        search_autocomplete(autocomplete_field,
                            query: parent_work_package.subject,
                            results_selector: "body")

        expect_no_ng_option(autocomplete_field,
                            parent_work_package.subject,
                            results_selector: "body")

        # It doesn't autocomplete work package itself
        search_autocomplete(autocomplete_field,
                            query: work_package.id,
                            results_selector: "body")

        expect_no_ng_option(autocomplete_field,
                            work_package.subject,
                            results_selector: "body")
      end
    end
  end

  describe "attaching a parent" do
    shared_let(:not_parent_yet_wp) do
      create(:work_package,
             subject: "not_parent_yet_wp",
             type: type1,
             project:)
    end

    it "renders the new parent form and creates the parent relationship" do
      scroll_to_element relations_panel

      wait_for_network_idle

      tabs.expect_counter("relations", 8)

      relations_tab.add_parent_relation(not_parent_yet_wp)
      relations_tab.expect_parent(not_parent_yet_wp) # breadcrumb
      relations_tab.expect_parent_relation(not_parent_yet_wp) # relation group

      # Did not change because there was already a parent relation
      tabs.expect_counter("relations", 8)

      # Parent relation is created
      expect(work_package.reload.parent).to eq not_parent_yet_wp

      # Ghost relations are shown here due to lack of permissions on the project
      relations_tab.expect_ghost_relation(restricted_relation_relates)
      relations_tab.expect_ghost_relation(restricted_child_work_package)
    end
  end

  describe "with limited permissions" do
    let(:no_permissions_role) { create(:project_role, permissions: %i[view_work_packages]) }
    let(:user_without_permissions) do
      create(:user,
             member_with_roles: { project => no_permissions_role })
    end
    let(:current_user) { user_without_permissions }

    it "does not show options to add or edit relations" do
      scroll_to_element relations_panel

      wait_for_network_idle

      tabs.expect_counter("relations", 8)

      relations_tab.expect_no_add_relation_button
      relations_tab.expect_no_relatable_action_menu(wp_related)
      relations_tab.expect_no_relatable_action_menu(child_wp)
    end

    context "with manage_relations permissions" do
      let(:no_permissions_role) do
        create(:project_role, permissions: %i(view_work_packages edit_work_packages manage_work_package_relations))
      end

      it "does not show the option to delete the child" do
        scroll_to_element relations_panel

        wait_for_network_idle

        tabs.expect_counter("relations", 8)

        # The menu is shown as the user can add a relation
        relations_tab.expect_add_relation_button

        # The relation can be edited and deleted
        relations_tab.expect_relatable_action_menu(wp_related)
        relations_tab.relatable_action_menu(wp_related).click
        relations_tab.expect_relatable_delete_button(wp_related)

        # The child cannot be changed
        relations_tab.expect_no_relatable_action_menu(child_wp)
      end
    end

    context "when the user does not have manage_subtasks in child's project" do
      let(:child_wp_project) { create(:project) }
      let!(:child_wp) do
        create(:work_package,
               subject: "child_wp",
               parent: work_package,
               type: type1,
               project: child_wp_project)
      end

      let(:restricted_role) { create(:project_role, permissions: %i[view_work_packages]) }

      let(:user_without_manage_subtasks) do
        create(:user,
               member_with_roles: {
                 project => create(:project_role, permissions: %i[view_work_packages manage_subtasks]),
                 child_wp_project => restricted_role
               })
      end

      let(:current_user) { user_without_manage_subtasks }

      it "does not show the option to delete the child relation" do
        scroll_to_element relations_panel

        wait_for_network_idle

        # The menu should NOT be available for child_wp since user lacks manage_subtasks permission
        relations_tab.expect_no_relatable_action_menu(child_wp)
      end
    end

    context "with manage_subtasks permissions" do
      let(:no_permissions_role) { create(:project_role, permissions: %i(view_work_packages edit_work_packages manage_subtasks)) }

      it "does not show the option to edit the relation but only the child" do
        scroll_to_element relations_panel

        wait_for_network_idle

        tabs.expect_counter("relations", 8)

        # The menu is shown as the user can add a child
        relations_tab.expect_add_relation_button

        # The relation cannot be edited
        relations_tab.expect_no_relatable_action_menu(wp_related)

        # The child can be removed
        relations_tab.expect_relatable_action_menu(child_wp)
        relations_tab.relatable_action_menu(child_wp).click
        relations_tab.expect_relatable_delete_button(child_wp)
      end

      it "does not show the option add new relations except for child" do
        scroll_to_element relations_panel

        wait_for_network_idle

        tabs.expect_counter("relations", 8)

        # The menu is shown as the user can add a child
        relations_tab.expect_add_relation_button
        relations_tab.open_add_relation_action_menu

        # Expect options to add children
        relations_tab.expect_new_relation_type("Parent")
        relations_tab.expect_new_relation_type("Child")
        relations_tab.expect_no_new_relation_type("Related To")

        # .. but no sub menu for further relations
        relations_tab.expect_no_add_menu_sub_menu
      end
    end
  end
end

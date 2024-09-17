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

RSpec.shared_examples "work package relations tab", :js, :selenium do
  include_context "ng-select-autocomplete helpers"

  let(:user) { create(:admin) }

  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:relations) { Components::WorkPackages::Relations.new(work_package) }

  let(:visit) { true }

  before do
    login_as user

    if visit
      visit_relations
    end
  end

  def visit_relations
    wp_page.visit_tab!("relations")
    expect_angular_frontend_initialized
    wp_page.expect_subject
    loading_indicator_saveguard
  end

  describe "as admin" do
    let!(:parent) { create(:work_package, project:, subject: "Parent WP") }
    let!(:child) { create(:work_package, project:, subject: "Child WP") }
    let!(:child2) { create(:work_package, project:, subject: "Another child WP") }

    it "allows to manage hierarchy" do
      # Add parent
      relations.add_parent(parent.id, parent)
      relations.expect_parent(parent)

      ##
      # Add child #1
      relations.open_children_autocompleter

      relations.add_existing_child(child)
      relations.expect_child(child)

      ##
      # Add child #2
      relations.open_children_autocompleter

      relations.add_existing_child(child2)
      relations.expect_child(child2)

      # Count child relations in split view
      tabs.expect_counter(relations_tab, 2)
    end

    context "when switching to custom field with required CF" do
      let(:custom_field) do
        create(
          :work_package_custom_field,
          field_format: "string",
          default_value: nil,
          is_required: true,
          is_for_all: true
        )
      end
      let(:type2) { create(:type, custom_fields: [custom_field]) }
      let(:relations) { Components::WorkPackages::Relations.new(parent) }
      let!(:status) { create(:status, is_default: true) }
      let!(:priority) { create(:priority, is_default: true) }

      before do
        project.types << type2
        project.save!
        custom_field
      end

      it "shows the required field when switching" do
        relations.inline_create_child "my new child"
        table = relations.children_table

        table.expect_work_package_subject "my new child"
        wp = WorkPackage.find_by!(subject: "my new child")
        type_field = table.edit_field(wp, :type)

        type_field.activate!
        type_field.set_value type2.name

        wp_page.expect_toast message: "#{custom_field.name} can't be blank.",
                             type: "error"

        cf_field = wp_page.edit_field(custom_field.attribute_name(:camel_case))
        cf_field.expect_active!
        cf_field.expect_value("")

        cf_field.set_value "my value"
        cf_field.save!

        wp_page.expect_toast message: "Successful update.",
                             type: "success"

        wp.reload
        expect(wp.custom_value_for(custom_field).value).to eq "my value"
      end
    end

    describe "inline create" do
      let!(:status) { create(:status, is_default: true) }
      let!(:priority) { create(:priority, is_default: true) }
      let(:type_bug) { create(:type_bug) }
      let!(:project) do
        create(:project, types: [type_bug])
      end

      it "can inline-create children" do
        relations.inline_create_child "my new child"
        table = relations.children_table

        table.expect_work_package_subject "my new child"
        work_package.reload
        expect(work_package.children.count).to eq(1)

        # If new child is inline created, counter should increase
        tabs.expect_counter(relations_tab, 1)
      end
    end
  end

  describe "relation group-by toggler" do
    let(:project) { create(:project, types: [type1, type2]) }
    let(:type1) { create(:type) }
    let(:type2) { create(:type) }

    let(:to1) { create(:work_package, type: type1, project:) }
    let(:to2) { create(:work_package, type: type2, project:) }

    let!(:relation1) do
      create(:relation,
             from: work_package,
             to: to1,
             relation_type: Relation::TYPE_FOLLOWS)
    end
    let!(:relation2) do
      create(:relation,
             from: work_package,
             to: to2,
             relation_type: Relation::TYPE_RELATES)
    end

    let(:toggle_btn_selector) { "#wp-relation-group-by-toggle" }
    let(:visit) { false }

    before do
      visit_relations

      wp_page.visit_tab!("relations")
      wp_page.expect_subject
      loading_indicator_saveguard
    end

    describe "with limited permissions" do
      let(:permissions) { %i(view_work_packages) }
      let(:user_role) do
        create(:project_role, permissions:)
      end

      let(:user) do
        create(:user,
               member_with_roles: { project => user_role })
      end

      context "as view-only user, with parent set" do
        let!(:parent) { create(:work_package, project:, subject: "Parent WP") }
        let!(:work_package) { create(:work_package, parent:, project:, subject: "Child WP") }

        it "shows no links to create relations" do
          # No create buttons should exist
          expect(page).to have_no_css(".wp-relations-create-button")

          # Test for add relation
          expect(page).to have_no_css("#relation--add-relation")

          # Test for add parent
          expect(page).to have_no_css(".wp-relation--parent-change")

          # Test for add children
          expect(page).to have_no_css("#hierarchy--add-existing-child")
          expect(page).to have_no_css("#hierarchy--add-new-child")

          # But it should show the linked parent
          expect(page).to have_test_selector("op-wp-breadcrumb-parent", text: parent.subject)

          # And it should count the two relations
          tabs.expect_counter(relations_tab, 2)
        end
      end

      context "with manage_subtasks permissions" do
        let(:permissions) { %i(view_work_packages manage_subtasks) }
        let!(:parent) { create(:work_package, project:, subject: "Parent WP") }
        let!(:child) { create(:work_package, project:, subject: "Child WP") }

        it "is able to link parent and children" do
          # Add parent
          relations.add_parent(parent.id, parent)
          wp_page.expect_and_dismiss_toaster(message: "Successful update.")
          relations.expect_parent(parent)

          ##
          # Add child
          relations.open_children_autocompleter

          relations.add_existing_child(child)
          wp_page.expect_and_dismiss_toaster(message: "Successful update.")
          relations.expect_child(child)

          # Expect counter to add up child to the existing relations
          tabs.expect_counter(relations_tab, 3)

          # Remove parent
          relations.remove_parent
          wp_page.expect_and_dismiss_toaster(message: "Successful update.")
          relations.expect_no_parent

          # Remove child
          relations.remove_child(child)
          # Should also check for successful update but no message is shown, yet.
          relations.expect_not_child(child)

          # Expect counter to count the two relations
          tabs.expect_counter(relations_tab, 2)
        end
      end
    end
  end
end

RSpec.context "within a split screen" do
  let(:wp_page) { Pages::SplitWorkPackage.new(work_package) }
  let(:tabs) { Components::WorkPackages::Tabs.new(work_package) }

  let(:relations_tab) { find(".op-tab-row--link_selected", text: "RELATIONS") }

  it_behaves_like "work package relations tab"
end

RSpec.context "within a primerized split screen" do
  let(:wp_page) { Pages::PrimerizedSplitWorkPackage.new(work_package) }
  let(:tabs) { Components::WorkPackages::PrimerizedTabs.new }
  let(:relations_tab) { "relations" }

  it_behaves_like "work package relations tab"
end

RSpec.context "within a full screen" do
  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:tabs) { Components::WorkPackages::Tabs.new(work_package) }

  let(:relations_tab) { find(".op-tab-row--link_selected", text: "RELATIONS") }

  it_behaves_like "work package relations tab"
end

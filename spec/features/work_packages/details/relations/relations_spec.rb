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

RSpec.shared_examples "Work package relations tab", :js, :selenium do
  include_context "ng-select-autocomplete helpers"

  let(:user) { create(:admin) }

  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:full_wp) { Pages::FullWorkPackage.new(work_package) }
  let(:relations) { Components::WorkPackages::Relations.new(work_package) }

  let(:visit) { true }

  before do
    login_as user

    if visit
      visit_relations
    end
  end

  def visit_relations
    work_packages_page.visit_tab!("relations")
    expect_angular_frontend_initialized
    work_packages_page.expect_subject
    loading_indicator_saveguard
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

      work_packages_page.visit_tab!("relations")
      work_packages_page.expect_subject
      loading_indicator_saveguard

      scroll_to_element find(".detail-panel--relations")
    end

    it "allows to toggle how relations are grouped" do
      # Expect to be grouped by relation type by default
      expect(page).to have_selector(toggle_btn_selector,
                                    text: "Group by work package type", wait: 20)

      expect(page).to have_css(".relation-group--header", text: "FOLLOWS")
      expect(page).to have_css(".relation-group--header", text: "RELATED TO")

      expect(page).to have_css(".relation-row--type", text: type1.name.upcase)
      expect(page).to have_css(".relation-row--type", text: type2.name.upcase)

      find(toggle_btn_selector).click
      expect(page).to have_selector(toggle_btn_selector, text: "Group by relation type", wait: 10)

      expect(page).to have_css(".relation-group--header", text: type1.name.upcase)
      expect(page).to have_css(".relation-group--header", text: type2.name.upcase)

      expect(page).to have_css(".relation-row--type", text: "Follows")
      expect(page).to have_css(".relation-row--type", text: "Related To")
    end

    it "allows to edit relation types when toggled" do
      find(toggle_btn_selector).click
      expect(page).to have_selector(toggle_btn_selector, text: "Group by relation type", wait: 20)

      # Expect current to be follows and other one related
      expect(page).to have_css(".relation-row--type", text: "Follows")
      expect(page).to have_css(".relation-row--type", text: "Related To")

      # edit to blocks
      relations.edit_relation_type(to1, to_type: "Blocks")

      # the other one should not be altered
      expect(page).to have_css(".relation-row--type", text: "Blocks")
      expect(page).to have_css(".relation-row--type", text: "Related To")

      updated_relation = Relation.find(relation1.id)
      expect(updated_relation.relation_type).to eq("blocks")
      expect(updated_relation.from_id).to eq(work_package.id)
      expect(updated_relation.to_id).to eq(to1.id)

      relations.edit_relation_type(to1, to_type: "Blocked by")

      expect(page).to have_css(".relation-row--type", text: "Blocked by")
      expect(page).to have_css(".relation-row--type", text: "Related To")

      updated_relation = Relation.find(relation1.id)
      expect(updated_relation.relation_type).to eq("blocks")
      expect(updated_relation.from_id).to eq(to1.id)
      expect(updated_relation.to_id).to eq(work_package.id)
    end
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
      let(:work_package) { create(:work_package, project:) }

      it "shows no links to create relations" do
        # No create buttons should exist
        expect(page).to have_no_css(".wp-relations-create-button")

        # Test for add relation
        expect(page).to have_no_css("#relation--add-relation")
      end
    end

    context "with relations permissions" do
      let(:permissions) do
        %i(view_work_packages add_work_packages manage_subtasks manage_work_package_relations)
      end

      let!(:relatable) { create(:work_package, project:) }

      it "allows to manage relations" do
        relations.add_relation(type: "follows", to: relatable)

        # Relations counter badge should increase number of relations
        tabs.expect_counter(relations_tab, 1)

        relations.remove_relation(relatable)
        expect(page).to have_no_css(".relation-group--header", text: "FOLLOWS")

        # If there are no relations, the counter badge should not be displayed
        tabs.expect_no_counter(relations_tab)

        work_package.reload
        expect(work_package.relations).to be_empty
      end

      it "allows to move between split and full view (Regression #24194)" do
        relations.add_relation(type: "follows", to: relatable)
        # Relations counter should increase
        tabs.expect_counter(relations_tab, 1)

        # Switch to full view
        work_packages_page.switch_to_fullscreen

        # Expect to have row
        relations.hover_action(relatable, :delete)

        expect(page).to have_no_css(".relation-group--header", text: "FOLLOWS")
        expect(page).to have_no_css(".wp-relations--subject-field", text: relatable.subject)

        # Back to split view
        page.execute_script("window.history.back()")
        work_packages_page.expect_subject

        expect(page).to have_no_css(".relation-group--header", text: "FOLLOWS")
        expect(page).to have_no_css(".wp-relations--subject-field", text: relatable.subject)
      end

      it "follows the relation links (Regression #26794)" do
        relations.add_relation(type: "follows", to: relatable)

        relations.click_relation(relatable)
        subject = full_wp.edit_field(:subject)
        subject.expect_state_text relatable.subject

        relations.click_relation(work_package)
        subject = full_wp.edit_field(:subject)
        subject.expect_state_text work_package.subject
      end

      it "allows to change relation descriptions" do
        relations.add_relation(type: "follows", to: relatable)

        ## Toggle description
        relations.hover_action(relatable, :info)

        # Open textarea
        created_row = relations.find_row(relatable)
        created_row.find(".wp-relation--description-read-value.-placeholder",
                         text: I18n.t("js.placeholders.relation_description")).click

        expect(page).to have_focus_on(".wp-relation--description-textarea")
        textarea = created_row.find(".wp-relation--description-textarea")
        textarea.set "my description!"

        # Save description
        created_row.find(".inplace-edit--control--save").click

        loading_indicator_saveguard

        # Wait for the relations table to be present
        sleep 2
        expect(page).to have_test_selector("op-relation--row-subject")

        scroll_to_element find(".detail-panel--relations")

        ## Toggle description again
        retry_block do
          relations.hover_action(relatable, :info)
          created_row = relations.find_row(relatable)

          find ".wp-relation--description-read-value"
        end

        created_row.find(".wp-relation--description-read-value",
                         text: "my description!").click

        # Cancel edition
        created_row.find(".inplace-edit--control--cancel").click
        created_row.find(".wp-relation--description-read-value",
                         text: "my description!").click

        relation = work_package.relations.first
        expect(relation.description).to eq("my description!")

        # Toggle to close
        relations.hover_action(relatable, :info)
        expect(created_row).to have_no_css(".wp-relation--description-read-value")
      end
    end
  end
end

RSpec.context "within a split screen" do
  let(:work_packages_page) { Pages::SplitWorkPackage.new(work_package) }
  let(:tabs) { Components::WorkPackages::Tabs.new(work_package) }

  let(:relations_tab) { find(".op-tab-row--link_selected", text: "RELATIONS") }

  it_behaves_like "Work package relations tab"
end

RSpec.context "within a primerized split screen" do
  let(:work_packages_page) { Pages::PrimerizedSplitWorkPackage.new(work_package) }
  let(:tabs) { Components::WorkPackages::PrimerizedTabs.new }
  let(:relations_tab) { "relations" }

  it_behaves_like "Work package relations tab"
end

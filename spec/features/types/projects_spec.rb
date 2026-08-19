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

RSpec.describe "Work package type projects tab", :js, with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type:, variant_name: "Hardware") }

  shared_let(:parent) { create(:project, name: "Foundry") }
  shared_let(:child) { create(:project, name: "Laboratory", parent:, types: [hardware]) }

  current_user { admin }

  def add_projects(project, include_sub_items:)
    find_test_selector("type-projects-add-button").click

    within("##{WorkPackageTypes::ProjectsTab::AddFormComponent::DIALOG_ID}") do
      check I18n.t("filterable_tree_view.include_sub_items") if include_sub_items
      find("[role='treeitem'][data-node-id='#{project.id}']").click
      click_link_or_button I18n.t(:button_add)
    end
  end

  def add_projects_including_sub_items(project)
    add_projects(project, include_sub_items: true)
  end

  it "adds a parent with its sub-projects when one of them is already on the variant" do
    visit edit_type_projects_path(type_id: type.id, variant_id: hardware.id)

    add_projects_including_sub_items(parent)

    expect_flash(message: I18n.t(:notice_successful_update))

    expect(page).to have_no_css("##{WorkPackageTypes::ProjectsTab::AddFormComponent::DIALOG_ID}", visible: :visible)

    within "#project-table" do
      expect(page).to have_text(parent.name)
      expect(page).to have_text(child.name)
    end

    expect(parent.reload.type_variant(type)).to eq(hardware)
  end

  describe "enabling the type in all projects" do
    shared_let(:elsewhere) { create(:project, name: "Warehouse") }

    it "flips the button between enable and disable as it is clicked" do
      visit edit_type_projects_path(type_id: type.id)

      click_link_or_button I18n.t("types.edit.projects.enable_all")

      expect(page).to have_test_selector("type-projects-enable-all",
                                         text: I18n.t("types.edit.projects.disable_all"))
      within("#project-table") { expect(page).to have_text(elsewhere.name) }

      click_link_or_button I18n.t("types.edit.projects.disable_all")

      expect(page).to have_test_selector("type-projects-enable-all",
                                         text: I18n.t("types.edit.projects.enable_all"))
      within("#project-table") { expect(page).to have_no_text(elsewhere.name) }
    end
  end

  it "leaves sub-projects out unless they are asked for" do
    outside = create(:project, name: "Warehouse")
    inside = create(:project, name: "Annex", parent: outside)

    visit edit_type_projects_path(type_id: type.id, variant_id: hardware.id)

    add_projects(outside, include_sub_items: false)

    expect_flash(message: I18n.t(:notice_successful_update))

    within "#project-table" do
      expect(page).to have_text(outside.name)
      expect(page).to have_no_text(inside.name)
    end

    # Scoped to this type: the project factory enables the default types on every project.
    expect(inside.reload.project_types.where(type_id: type.id)).to be_empty
  end

  it "flips the toggle label when the add dialog completes the set" do
    lone_type = create(:type, name: "Chore")
    Project.where.not(id: parent.id).find_each { |project| create(:project_type, project:, type: lone_type) }

    visit edit_type_projects_path(type_id: lone_type.id)

    expect(page).to have_test_selector("type-projects-enable-all",
                                       text: I18n.t("types.edit.projects.enable_all"))

    add_projects(parent, include_sub_items: false)

    expect_flash(message: I18n.t(:notice_successful_update))
    expect(page).to have_test_selector("type-projects-enable-all",
                                       text: I18n.t("types.edit.projects.disable_all"))
  end
end

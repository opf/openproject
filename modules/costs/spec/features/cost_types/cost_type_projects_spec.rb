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

RSpec.describe "Cost type projects activation", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project, name: "Alpha") }

  let(:cost_type) { create(:cost_type, name: "Translations", for_all_projects: false) }

  before do
    login_as(admin)
    visit admin_cost_type_projects_path(cost_type)
  end

  it "allows adding and removing a project mapping" do
    expect(page).to have_no_css("dialog")

    click_on "Add projects"

    within_test_selector("new-cost-type-projects-modal") do
      autocompleter = find(".op-project-autocompleter")
      autocompleter.fill_in with: project.name

      find(".ng-option-label", text: project.name).click

      click_on "Add"
    end

    expect(page).to have_text(project.name)
    expect(CostTypesProject.where(cost_type:, project:)).to exist

    row = page.find("#admin-cost-types-cost-type-projects-row-component-project-#{project.id}")
    row.hover
    within(row) do
      find("[data-test-selector='project-list-row--action-menu'] button").click
    end
    click_on "Remove from project"

    expect(page).to have_no_text(project.name)
    expect(CostTypesProject.where(cost_type:, project:)).not_to exist
  end

  it "shows an error in the dialog when no project is selected" do
    click_on "Add projects"

    within_test_selector("new-cost-type-projects-modal") do
      click_on "Add"

      expect(page).to have_text("Please select a project.")
    end

    expect(CostTypesProject.where(cost_type:)).to be_empty
  end

  context "when the cost type is for all projects" do
    let(:cost_type) { create(:cost_type, name: "Travel", for_all_projects: true) }

    it "does not show the add-projects sub-header" do
      expect(page).to have_text("This cost type is enabled in all projects")
      expect(page).not_to have_test_selector("add-projects-sub-header")
    end
  end
end

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
require "support/pages/projects/settings/work_package_types"

RSpec.describe "Project settings work package types", :js, with_flag: { type_variants: true } do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:epic) { create(:type, name: "Epic") }
  shared_let(:design) { create(:type, name: "Design", parent: epic) }
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:milestone) { create(:type, name: "Milestone") }
  shared_let(:feature) { create(:type, name: "Feature") }
  shared_let(:research) { create(:type, name: "Research", parent: feature) }

  let(:project) { create(:project, types: [design, bug]) }
  let(:settings_page) { Pages::Projects::Settings::WorkPackageTypes.new(project) }

  current_user do
    create(:user, member_with_permissions: { project => %i[edit_project manage_types view_work_packages] })
  end

  before { settings_page.visit! }

  it "lists each active family, naming the active variant behind its parent type" do
    settings_page.expect_type_row(design, variant: "Design")
    settings_page.expect_type_row(bug)
  end

  it "activates a root type through the dialog" do
    add_type("Milestone")

    settings_page.expect_type_row(milestone)
    expect(project.reload.types).to include(milestone)
  end

  it "activates a variant through the dialog" do
    add_type("Research", select_text: "Feature: Research")

    settings_page.expect_type_row(research, variant: "Research")
    expect(project.reload.types).to include(feature)
    expect(project.project_types.find_by(type: feature).variant).to eq(research)
  end

  it "removes a type that has no work packages" do
    settings_page.remove_type(bug)

    settings_page.expect_no_type_row(bug)
    expect(project.reload.types).not_to include(bug)
  end

  context "when work packages of that type exist" do
    let!(:work_package) { create(:work_package, project:, type: bug) }

    it "refuses the removal and explains why" do
      settings_page.remove_type(bug)

      expect_flash(type: :error, message: "Unable to deactivate type Bug because it's still in use by work packages")
      settings_page.expect_type_row(bug)
      expect(project.reload.types).to include(bug)
    end
  end

  # Located by test selector because the tab nav above renders a "Types" link,
  # which Capybara's non-exact text matching would confuse with this button.
  def add_type(query, select_text: query)
    page.find("[data-test-selector='project-types-add-button']").click

    expect(page).to have_text("Add type")

    select_autocomplete(page.find("[data-test-selector='project-types-add-select']"),
                        query:,
                        select_text:)
    click_on "Add"
  end
end

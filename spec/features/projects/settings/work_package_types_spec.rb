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
  shared_let(:blueprint) { create(:type, name: "Blueprint", parent: epic) }
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

  # The row names the active variant, so the removal is requested with the variant's id while
  # the row that has to go is the family's.
  it "removes a family the project runs through a variant" do
    settings_page.remove_type(design)

    settings_page.expect_no_type_row(design)
    expect(project.reload.types).not_to include(epic)
    expect(project.project_types.where(type: epic)).to be_empty
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

  it "switches the project to a sibling variant" do
    work_package = create(:work_package, project:, type: epic)

    settings_page.switch_type(design, target: "Epic: Blueprint")

    expect_flash(message: "The project now uses Epic: Blueprint.")
    settings_page.expect_type_row(blueprint, variant: "Blueprint")
    settings_page.expect_no_type_row(design)
    expect(project.reload.project_types.find_by(type: epic).variant).to eq(blueprint)
    # The family stays the same, so the work packages storing it are none the wiser.
    expect(work_package.reload.type).to eq(epic)
  end

  it "switches the project from a variant to the family parent" do
    settings_page.switch_type(design, target: "Epic")

    settings_page.expect_type_row(epic)
    expect(project.reload.project_types.find_by(type: epic).variant).to be_nil
  end

  it "warns about hidden custom field data and opens on the variant in use" do
    settings_page.open_switch_dialog(design)

    within(settings_page.switch_dialog) do
      expect(page).to have_text("Epic: Switch variant")
      expect(page).to have_text("you might lose information associated with custom fields")
      expect(page).to have_select("Variant", selected: "Epic: Design")
    end
  end

  # Reported under the select rather than as a flash, so the choice can be corrected where it
  # was made.
  it "refuses to apply the variant the project already uses" do
    settings_page.open_switch_dialog(design)
    settings_page.apply_switch

    within(settings_page.switch_dialog) do
      expect(page).to have_text("The target type must be different from the type the project uses now")
      expect(page).to have_select("Variant", selected: "Epic: Design")
    end
    expect(project.reload.project_types.find_by(type: epic).variant).to eq(design)
  end

  # A family with no variants has nothing to switch to, so offering the action
  # would open a dialog whose only option is the current one.
  it "offers no switch action for a family without variants" do
    settings_page.expect_no_switch_action(bug)
  end

  context "with configurations that differ between the two variants" do
    before do
      # Both variants borrow Epic's form configuration until the link is severed,
      # which would leave nothing for the preview to report.
      make_independent(design, Type::ConfigurationLink::FORM_CONFIGURATION)
      make_independent(blueprint, Type::ConfigurationLink::FORM_CONFIGURATION)

      design.attribute_groups = [["Details", %w[assignee]]]
      design.save!
      blueprint.attribute_groups = [["Details", %w[priority]]]
      blueprint.save!

      create(:work_package, project:, type: epic)
    end

    it "reports the impact once a different variant is chosen" do
      settings_page.open_switch_dialog(design)
      settings_page.expect_switch_impact("Select a different variant to see what will change")

      settings_page.choose_switch_target("Epic: Blueprint")

      settings_page.expect_switch_impact("1 work package will use the new configuration")
      settings_page.expect_switch_impact("Fields that will no longer be shown")
      settings_page.expect_switch_impact("Fields that become available")
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

  # A variant is created linked to its parent on every aspect, and the readers
  # resolve through the link once a pending change is saved, so a variant's own
  # configuration stays invisible until the link is severed.
  def make_independent(type, aspect)
    type.configuration_links.where(aspect:).destroy_all
  end
end

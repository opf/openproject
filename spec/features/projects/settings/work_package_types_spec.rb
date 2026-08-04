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

  # edit_work_packages is needed on top of manage_types: switching re-types the
  # project's work packages through WorkPackages::UpdateService as this user.
  current_user do
    create(:user, member_with_permissions: { project => %i[edit_project manage_types view_work_packages
                                                           edit_work_packages] })
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
    expect(project.reload.types).to include(research)
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

  it "switches the project to a sibling variant and re-types its work packages" do
    work_package = create(:work_package, project:, type: design)

    settings_page.switch_type(design, target: "Epic: Blueprint")
    settings_page.await_switch_queued(design)
    perform_enqueued_jobs

    expect_flash(message: "The project now uses Epic: Blueprint.")
    settings_page.expect_type_row(blueprint, variant: "Blueprint")
    settings_page.expect_no_type_row(design)
    expect(work_package.reload.type).to eq(blueprint)
  end

  it "switches the project from a variant to the family parent" do
    settings_page.switch_type(design, target: "Epic")
    settings_page.await_switch_queued(design)
    perform_enqueued_jobs

    settings_page.expect_type_row(epic)
    expect(project.reload.types).to include(epic)
  end

  it "warns about hidden custom field data and opens on the variant in use" do
    settings_page.open_switch_dialog(design)

    within(settings_page.switch_dialog) do
      expect(page).to have_text("Epic: Switch variant")
      expect(page).to have_text("you might lose information associated with custom fields")
      expect(page).to have_select("Variant", selected: "Epic: Design")
    end
  end

  it "refuses to apply the variant the project already uses" do
    settings_page.open_switch_dialog(design)
    settings_page.apply_switch

    within(settings_page.switch_dialog) do
      expect(page).to have_text("must be different from the one the project uses now")
    end
    expect(project.reload.types).to include(design)
  end

  # A family with no variants has nothing to switch to, so offering the action
  # would open a dialog whose only option is the current one.
  it "offers no switch action for a family without variants" do
    settings_page.expect_no_switch_action(bug)
  end

  # Nothing performs the job, so it is still queued when the debounce window
  # closes: the case where the switch outlives it and the indicators appear.
  context "when the switch outlives the debounce window" do
    before { create(:work_package, project:, type: design) }

    it "hands the switch to a background job instead of holding the request" do
      settings_page.switch_type(design, target: "Epic: Blueprint")

      settings_page.expect_switching_row(design, target: "Blueprint")
      # Nothing has run yet: the request only queued it.
      expect(project.reload.types).to contain_exactly(design, bug)

      perform_enqueued_jobs

      expect(project.reload.types).to contain_exactly(blueprint, bug)
    end

    it "settles the row without a reload, and never opens a dialog" do
      settings_page.switch_type(design, target: "Epic: Blueprint")

      settings_page.expect_switching_row(design, target: "Blueprint")
      settings_page.expect_no_dialog

      perform_enqueued_jobs

      settings_page.expect_type_row(blueprint, variant: "Blueprint")
      expect_flash(message: "The project now uses Epic: Blueprint.")
    end

    # Keyed on the project, so a colleague who did not start it still sees it.
    it "shows a switch started by somebody else" do
      Projects::Types::SwitchVariantJob.perform_later(user: current_user, project:, source: design, target: blueprint)

      settings_page.visit!

      settings_page.expect_switching_row(design, target: "Blueprint")
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

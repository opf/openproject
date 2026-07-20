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

RSpec.describe "Types", :js do
  shared_let(:admin) { create(:admin) }

  shared_let(:existing_role) { create(:project_role) }
  shared_let(:existing_type) { create(:type) }
  shared_let(:existing_workflow) { create(:workflow_with_default_status, role: existing_role, type: existing_type) }

  let(:index_page) { Pages::Types::Index.new }

  before do
    login_as(admin)
  end

  it "crud" do
    index_page.visit!

    index_page.click_new

    # Error messages if something was wrong
    fill_in "Name", with: existing_type.name
    select existing_type.name, from: "Copy workflow from"

    click_on "Save"

    expect(page).to have_css(".FormControl-inlineValidation", text: "Name has already been taken.", wait: 12)

    # Values are retained
    expect(page).to have_field("Name", with: existing_type.name)
    expect(page).to have_field("Copy workflow from", with: existing_type.id)

    # Successful creation
    fill_in "Name", with: "A new type"

    click_on "Save"

    expect(page).to have_content I18n.t(:notice_successful_create)

    # Workflow should be copied over from the source type.
    new_type = Type.find_by!(name: "A new type")
    expect(
      Workflow.exists?(type_id: new_type.id,
                       old_status_id: existing_workflow.old_status_id,
                       new_status_id: existing_workflow.new_status_id)
    ).to be true

    index_page.visit!

    index_page.expect_listed(existing_type, "A new type")

    index_page.click_edit("A new type")

    fill_in "Name", with: "Renamed type"

    click_on "Save"

    expect_flash(type: :success, message: I18n.t(:notice_successful_update))

    index_page.visit!

    index_page.expect_listed(existing_type, "Renamed type")

    index_page.delete "Renamed type"

    wait_for_network_idle

    expect_and_dismiss_flash(message: I18n.t(:notice_successful_delete))
    index_page.expect_listed(existing_type)
  end

  it "creates a sub-type through the parent select", with_flag: { subtypes: true } do
    index_page.visit!

    index_page.click_new

    fill_in "Name", with: "Phase"
    select existing_type.name, from: "Parent type"

    click_on "Save"

    expect(page).to have_text I18n.t(:notice_successful_create)
    expect(Type.find_by!(name: "Phase").parent).to eq(existing_type)

    index_page.visit!

    expect(page).to have_link("Phase", visible: :all)
  end

  it "lists a sub-type in the flat table when the feature flag is disabled", with_flag: { subtypes: false } do
    create(:type, name: "Phase", parent: existing_type)

    index_page.visit!

    within "table" do
      expect(page).to have_link("Phase")
    end
  end

  it "hides the inherited core settings while a parent is selected", with_flag: { subtypes: true } do
    index_page.visit!
    index_page.click_new

    # For a root type the inherited core settings are editable.
    expect(page).to have_field("Is milestone")
    expect(page).to have_field("Displayed in roadmap by default")
    expect(page).to have_field("Activated for new projects by default")

    # Selecting a parent turns this into a sub-type, so they are hidden.
    select existing_type.name, from: "Parent type"

    expect(page).to have_no_field("Is milestone")
    expect(page).to have_no_field("Displayed in roadmap by default")
    expect(page).to have_no_field("Activated for new projects by default")

    # Clearing the parent reveals them again.
    select "", from: "Parent type"

    expect(page).to have_field("Is milestone")
    expect(page).to have_field("Displayed in roadmap by default")
    expect(page).to have_field("Activated for new projects by default")
  end

  context "when a work package of a given type is part of an archived project" do
    shared_let(:project) do
      create(:project, :archived).tap do |p|
        p.types << existing_type
        p.save!
      end
    end

    shared_let(:work_package) { create(:work_package, type: existing_type, project:) }

    context "and I attempt to delete the type" do
      before do
        index_page.visit!
        index_page.delete existing_type.name
        wait_for_network_idle
      end

      it "renders an error message with links to the archived project in the projects list" do
        expect_flash type: :error, message: project.name
      end
    end
  end
end

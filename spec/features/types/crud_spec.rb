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

RSpec.describe "Types", :js, :with_cuprite do
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

    click_button "Create"

    expect(page)
      .to have_css(".errorExplanation", text: "Name has already been taken.")

    # Values are retained
    expect(page)
      .to have_field("Name", with: existing_type.name)

    # Successful creation
    fill_in "Name", with: "A new type"

    click_button "Create"

    expect(page)
      .to have_content I18n.t(:notice_successful_create)

    # Workflow should be copied over.
    # Workflow routes are not resource-oriented.
    visit(url_for(controller: :workflows, action: :edit, only_path: true))

    select existing_role.name, from: "Role"
    select "A new type", from: "Type"
    click_button "Edit"

    from_id = existing_workflow.old_status_id
    to_id = existing_workflow.new_status_id

    checkbox = page.find("input.old-status-#{from_id}.new-status-#{to_id}[value=always]")

    expect(checkbox)
      .to be_checked

    index_page.visit!

    index_page.expect_listed(existing_type, "A new type")

    index_page.click_edit("A new type")

    fill_in "Name", with: "Renamed type"

    click_button "Save"

    expect(page)
      .to have_content I18n.t(:notice_successful_update)

    index_page.visit!

    index_page.expect_listed(existing_type, "Renamed type")

    index_page.delete "Renamed type"

    index_page.expect_listed(existing_type)
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
        within ".op-toast.-error" do
          expect(page).to have_link(project.name)
        end
      end
    end
  end
end

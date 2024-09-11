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
require_relative "../principals/shared_memberships_examples"

RSpec.describe "Finding users with accents", :js, :with_cuprite do
  shared_let(:project) { create(:project) }
  shared_let(:principal) { create(:user, firstname: "Cécile", lastname: "Foobar") }
  shared_let(:admin) { create(:admin) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:role) do
    create(:project_role,
           name: "Developer",
           permissions: %i[view_work_packages edit_work_packages work_package_assigned])
  end

  let(:members_page) { Pages::Members.new project.identifier }
  let(:wp_page) { Pages::FullWorkPackage.new work_package }
  let(:assignee_field) { wp_page.edit_field :assignee }

  current_user { admin }

  it "finds a user with accents in the name in the global administration" do
    visit users_path

    fill_in "name", with: "Cecile"
    click_on "Apply"
    expect(page).to have_current_path /name=Cecile/
    expect(page).to have_css("td.firstname", text: "Cécile")

    fill_in "name", with: "Cécile"
    click_on "Apply"
    expect(page).to have_current_path /name=C%C3%A9cile/
    expect(page).to have_css("td.firstname", text: "Cécile")
  end

  it "can add the user as member and assignee" do
    visit project_members_path(project)

    members_page.open_new_member!
    members_page.search_and_select_principal! "Cecile",
                                              "Cécile Foobar"
    members_page.select_role! "Developer"

    click_on "Add"
    expect(members_page).to have_added_user "Cécile Foobar"

    members_page.open_filters!
    members_page.search_for_name "Cecile"
    members_page.find_user "Cécile Foobar"

    visit project_work_package_path(project, work_package)
    assignee_field.activate!

    assignee_field.openSelectField
    assignee_field.autocomplete("Cecile", select_text: "Cécile Foobar", select: true)
    wait_for_network_idle

    wp_page.expect_and_dismiss_toaster message: "Successful update."
    assignee_field.expect_inactive!
    assignee_field.expect_state_text "Cécile Foobar"
  end
end

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

RSpec.describe "Administrating memberships via the project settings", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }

  shared_let(:peter) do
    create(:user,
           status: User.statuses[:active],
           firstname: "Peter",
           lastname: "Pan",
           mail: "foo@example.org",
           preferences: { hide_mail: false })
  end
  shared_let(:hannibal) do
    create(:user,
           status: User.statuses[:invited],
           firstname: "Hannibal",
           lastname: "Smith",
           mail: "boo@bar.org",
           preferences: { hide_mail: true })
  end
  shared_let(:developer_placeholder) { create(:placeholder_user, name: "Developer 1") }
  shared_let(:group) do
    create(:group, lastname: "A-Team", members: [peter, hannibal])
  end

  shared_let(:manager)   { create(:project_role, name: "Manager", permissions: [:manage_members]) }
  shared_let(:developer) { create(:project_role, name: "Developer") }

  let(:member1) { create(:member, principal: peter, project:, roles: [manager]) }
  let(:member2) { create(:member, principal: hannibal, project:, roles: [developer]) }
  let(:member3) { create(:member, principal: group, project:, roles: [manager]) }

  let!(:existing_members) { [] }

  let(:members_page) { Pages::Members.new project.identifier }

  current_user { admin }

  before do
    members_page.visit!

    SeleniumHubWaiter.wait
  end

  context "with members in the project" do
    let!(:existing_members) { [member1, member2, member3] }

    it "sorting the page" do
      members_page.expect_sorted_by "name"
      expect(members_page.contents("name")).to eq [group.name, hannibal.name, peter.name]

      SeleniumHubWaiter.wait
      members_page.sort_by "name"
      members_page.expect_sorted_by "name", desc: true
      expect(members_page.contents("name")).to eq [peter.name, hannibal.name, group.name]

      SeleniumHubWaiter.wait
      members_page.sort_by "email"
      members_page.expect_sorted_by "email"
      expect(members_page.contents("email")).to eq [peter.mail]

      SeleniumHubWaiter.wait
      members_page.sort_by "status"
      members_page.expect_sorted_by "status"
      expect(members_page.contents("status", raw: true)).to eq %w(active active invited)

      SeleniumHubWaiter.wait
      members_page.sort_by "status"
      members_page.expect_sorted_by "status", desc: true
      expect(members_page.contents("status", raw: true)).to eq %w(invited active active)

      # Cannot sort by group, roles or status
      expect(page).to have_no_css(".generic-table--sort-header a", text: "ROLES")
      expect(page).to have_no_css(".generic-table--sort-header a", text: "GROUP")
    end

    it "navigating the menu" do
      members_page.expect_menu_item "All", selected: true
      members_page.expect_menu_item "Invited"
      members_page.expect_menu_item "Locked"

      members_page.expect_menu_item group.name
      members_page.expect_menu_item "Manager"
      members_page.expect_menu_item "Developer"

      # Viewing invited
      members_page.click_menu_item "Invited"
      expect(members_page).to have_user "Hannibal Smith"
      expect(members_page).not_to have_user "Peter Pan"
      expect(members_page).not_to have_group group.name

      # Viewing locked
      members_page.click_menu_item "Locked"
      expect(members_page).not_to have_user "Hannibal Smith"
      expect(members_page).not_to have_user "Peter Pan"
      expect(members_page).not_to have_group group.name

      # Viewing manager role
      members_page.click_menu_item "Manager"
      expect(members_page).to have_user "Peter Pan"
      expect(members_page).to have_group group.name
      expect(members_page).not_to have_user "Hannibal Smith"

      # Viewing developer role
      members_page.click_menu_item "Developer"
      expect(members_page).to have_user "Hannibal Smith"
      expect(members_page).not_to have_user "Peter Pan"
      expect(members_page).not_to have_group group.name
    end
  end

  it "Adding and Removing a Group as Member" do
    members_page.add_user! "A-Team", as: "Manager"

    expect(members_page).to have_added_group("A-Team")
    expect(page).to have_css ".op-avatar_group"
    SeleniumHubWaiter.wait

    members_page.remove_group! "A-Team"
    expect(page).to have_text "Removed A-Team from project"
    expect(page).to have_text "There are currently no members part of this project."
  end

  it "Adding and removing a User as Member" do
    members_page.add_user! "Hannibal Smith", as: "Manager"

    expect(members_page).to have_added_user "Hannibal Smith"
    expect(page).to have_css ".op-avatar_user"

    SeleniumHubWaiter.wait
    members_page.remove_user! "Hannibal Smith"
    expect(page).to have_text "Removed Hannibal Smith from project"
    expect(page).to have_text "There are currently no members part of this project."
  end

  it "Adding and removing a Placeholder as Member" do
    members_page.add_user! developer_placeholder.name, as: developer.name

    expect(members_page).to have_added_user developer_placeholder.name
    expect(page).to have_css ".op-avatar_placeholder-user"

    SeleniumHubWaiter.wait
    members_page.remove_user! developer_placeholder.name
    expect(page).to have_text "Removed #{developer_placeholder.name} from project"
    expect(page).to have_text "There are currently no members part of this project."
  end

  it "Entering a Username as Member in firstname, lastname order" do
    members_page.open_new_member!
    SeleniumHubWaiter.wait

    members_page.search_principal! "Hannibal S"
    expect(members_page).to have_search_result "Hannibal Smith"
  end

  it "Entering a Username as Member in lastname, firstname order" do
    members_page.open_new_member!
    SeleniumHubWaiter.wait

    members_page.search_principal! "Smith, H"
    expect(members_page).to have_search_result "Hannibal Smith"
  end

  context "with work packages shared" do
    let(:work_package) { create(:work_package, project:) }
    let(:view_work_package_role) { create(:view_work_package_role) }
    let(:member) { create(:member, entity: work_package, principal: peter, project:, roles: [view_work_package_role]) }

    let!(:existing_members) { [member] }

    it "still allows adding the user the work package is shared with" do
      members_page.open_new_member!

      SeleniumHubWaiter.wait

      members_page.search_principal! peter.firstname
      expect(members_page).to have_search_result peter.name
    end
  end
end

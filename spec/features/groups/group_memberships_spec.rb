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

RSpec.describe "group memberships through groups page", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }
  let!(:project) do
    create(:project, name: "Project 1", identifier: "project1", members: project_members)
  end

  let!(:peter)    { create(:user, firstname: "Peter", lastname: "Pan") }
  let!(:hannibal) { create(:user, firstname: "Hannibal", lastname: "Smith") }
  let(:group) do
    create(:group, lastname: "A-Team", members: group_members)
  end

  let!(:manager)   { create(:project_role, name: "Manager") }
  let!(:developer) { create(:project_role, name: "Developer") }

  let(:members_page) { Pages::Members.new project.identifier }
  let(:group_page)   { Pages::Groups.new.group(group.id) }
  let(:group_members) { [peter] }
  let(:project_members) { {} }

  before do
    allow(User).to receive(:current).and_return admin
  end

  it "adding a user to a group adds the user to the project as well" do
    group_page.visit!

    group_page.add_to_project! "Project 1", as: "Manager"
    expect(page).to have_text "Successful update"

    group_page.add_user! "Hannibal"

    members_page.visit!
    expect(members_page).to have_group "A-Team", roles: ["Manager"]
    expect(members_page).to have_user "Peter Pan", roles: ["Manager"]
    expect(members_page).to have_user "Hannibal Smith", roles: ["Manager"]
  end

  context "when there are only invited users not in the group" do
    let!(:peter)    { create(:invited_user, firstname: "Peter", lastname: "Pan") }
    let!(:hannibal) { create(:invited_user, firstname: "Hannibal", lastname: "Smith") }
    let(:group_members) { [admin] }

    it "is possible to add an invited user" do
      visit "/admin/groups/#{group.id}/edit?tab=users"

      # autocomplete section has been rendered
      expect(page).to have_text("NEW USER")
      expect(page).to have_text("Add")

      group_page.add_user! "Hannibal"
      expect(page).to have_text "Successful update"
      expect(page).to have_text("Hannibal Smith")
    end
  end

  context "given a group with members in a project" do
    let(:group_members) { [peter, hannibal] }
    let(:project_members) { { group => [manager] } }

    it "removing a user from the group removes them from the project too" do
      group_page.visit!
      group_page.remove_user! "Hannibal Smith"

      members_page.visit!
      expect(members_page).to have_user "A-Team"
      expect(members_page).to have_user "Peter Pan"
      expect(members_page).not_to have_user "Hannibal Smith"
    end

    it "removing the group from a project" do
      group_page.visit!
      group_page.open_projects_tab!
      expect(group_page).to have_project "Project 1"

      group_page.remove_from_project! "Project 1"
      expect(page).to have_text "Successful deletion"
      expect(page).to have_text "There are currently no projects part of this group."
    end
  end

  describe "with the group in two projects" do
    let!(:project2) do
      create(:project,
             name: "Project 2",
             identifier: "project2",
             members: project_members)
    end
    let(:members_page1) { Pages::Members.new project.identifier }
    let(:members_page2) { Pages::Members.new project2.identifier }
    let(:project_members) { { peter => manager, group => developer } }

    it "can add a new user to the group with correct member roles (Regression #33659)" do
      # Add hannibal to the group
      group_page.visit!
      group_page.add_user! "Hannibal"
      expect(page).to have_text "Successful update"

      members_page1.visit!
      expect(members_page1).to have_group "A-Team", roles: [developer]
      expect(members_page1).to have_user "Peter Pan", roles: [manager, developer]
      expect(members_page1).to have_user "Hannibal Smith", roles: [developer]

      members_page2.visit!

      expect(members_page2).to have_group "A-Team", roles: [developer]
      expect(members_page2).to have_user "Peter Pan", roles: [manager, developer]
      expect(members_page2).to have_user "Hannibal Smith", roles: [developer]

      group_member = project2.member_principals.find_by(user_id: group.id)
      expect(group_member.member_roles.count).to eq 1
      group_member_role = group_member.member_roles.first
      expect(group_member_role.role).to eq developer

      # Expect hannibal's role to be inherited by the group role
      hannibal_member = project2.members.find_by(user_id: hannibal.id)
      expect(hannibal_member.member_roles.count).to eq 1
      expect(hannibal_member.member_roles.first.inherited_from).to eq group_member_role.id
      expect(hannibal_member.member_roles.first.role).to eq developer

      # Remove the group from members page
      members_page2.remove_group! "A-Team"
      expect(page).to have_text "Removed A-Team from project."
      expect(members_page2).to have_user "Peter Pan", roles: [manager]

      expect(members_page2).not_to have_group "A-Team"
      expect(members_page2).not_to have_user "Hannibal Smith"

      # Expect we can remove peter pan now
      members_page2.remove_user! "Peter Pan"

      expect(page).to have_text "Removed Peter Pan from project."
      expect(members_page2).not_to have_user "Peter Pan"
      expect(members_page2).not_to have_group "A-Team"
      expect(members_page2).not_to have_user "Hannibal Smith"
    end

    context "with an archived project" do
      let!(:archived_project) do
        create(:project,
               name: "Archived project",
               identifier: "archived_project",
               active: false)
      end

      let!(:other_project) do
        create(:project,
               name: "Other project",
               identifier: "other_project")
      end

      it "can only a add the group to active projects in which the group is not yet a member" do
        group_page.visit!
        group_page.open_projects_tab!

        target_dropdown = group_page.search_for_project "project"
        expect(target_dropdown).to have_css(".ng-option", text: "Other project")
        expect(target_dropdown).to have_no_css(".ng-option", text: "Archived project")
      end
    end
  end
end

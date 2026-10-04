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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "group memberships through project members page", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:alice) { create(:user, firstname: "Alice", lastname: "Wonderland") }
  shared_let(:bob) { create(:user, firstname: "Bob", lastname: "Bobbit") }

  shared_let(:alpha) { create(:project_role, name: "alpha", permissions: [:manage_members]) }
  shared_let(:beta) { create(:project_role, name: "beta") }

  let(:group) { create(:group, lastname: "group1") }
  let(:project) { create(:project, name: "Project 1", identifier: "project1", members: project_member) }

  let(:members_page) { Pages::Members.new project.identifier }
  let(:groups_page) { Pages::Groups.new }
  let(:project_member) { {} }

  before do
    create(:member, user: bob, project:, roles: [alpha])
  end

  context "given a group with members" do
    shared_let(:group) { create(:group, lastname: "group1", members: alice) }

    current_user { bob }

    shared_examples "adding group1 as a member with the beta role" do
      it "can add group1 to the project" do
        members_page.visit!
        members_page.add_user! "group1", as: "beta"

        expect(members_page).to have_added_user "group1"
        expect(members_page).to have_user("Alice Wonderland", group_membership: true)
      end
    end

    context "when the user has the view_all_principals permission" do
      current_user do
        create(
          :user,
          global_permissions: [:view_all_principals],
          member_with_roles: { project => [alpha] }
        )
      end
      it_behaves_like "adding group1 as a member with the beta role"
    end

    context "when the user shares a membership with the group" do
      let!(:shared_project) { create(:project) }

      before do
        create(:member, user: bob, project: shared_project, roles: [beta])
        create(:member, user: group, project: shared_project, roles: [beta])
      end

      it_behaves_like "adding group1 as a member with the beta role"
    end

    context "which has has been added to a project" do
      let(:project_member) { { group => beta } }

      context "with the members having no roles of their own" do
        specify "removing the group removes its members too" do
          members_page.visit!
          expect(members_page).to have_user("Alice Wonderland")

          members_page.remove_group! "group1"
          expect(page).to have_text("Removed group1 from project")

          expect(members_page).not_to have_group("group1")
          expect(members_page).not_to have_user("Alice Wonderland")
        end
      end

      context "with the members having roles of their own" do
        before do
          project.members
                 .select { |m| m.user_id == alice.id }
                 .each { |m| m.roles << alpha }
        end

        specify "removing the group leaves the user without their group roles" do
          members_page.visit!
          expect(members_page).to have_user("Alice Wonderland", roles: ["alpha", "beta"])

          members_page.remove_group! "group1"
          expect(page).to have_text("Removed group1 from project")

          expect(members_page).not_to have_group("group1")

          expect(members_page).to have_user("Alice Wonderland", roles: ["alpha"])
          expect(members_page).not_to have_roles("Alice Wonderland", ["beta"])
        end
      end
    end
  end

  context "given an empty group in a project" do
    let(:project_member) { { group => beta } }

    current_user { admin }

    before do
      alice # create alice
    end

    specify "adding members to that group adds them to the project too" do
      members_page.visit!

      expect(members_page).not_to have_user("Alice Wonderland") # Alice not in the project yet
      expect(members_page).to have_user("group1") # the group is already there though

      groups_page.visit!
      SeleniumHubWaiter.wait
      groups_page.add_user_to_group! "Alice Wonderland", "group1"

      members_page.visit!
      expect(members_page).to have_user("Alice Wonderland", roles: ["beta"])
    end
  end
end

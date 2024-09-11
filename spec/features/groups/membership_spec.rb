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

RSpec.describe "group memberships through project members page", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }
  let(:project) { create(:project, name: "Project 1", identifier: "project1", members: project_member) }

  let(:alice) { create(:user, firstname: "Alice", lastname: "Wonderland") }
  let(:bob)   { create(:user, firstname: "Bob", lastname: "Bobbit") }
  let(:group) { create(:group, lastname: "group1") }

  let!(:alpha) { create(:project_role, name: "alpha", permissions: [:manage_members]) }
  let!(:beta)  { create(:project_role, name: "beta") }

  let(:members_page) { Pages::Members.new project.identifier }
  let(:groups_page)  { Pages::Groups.new }
  let(:project_member) { {} }

  before do
    create(:member, user: bob, project:, roles: [alpha])
  end

  context "given a group with members" do
    let!(:group) { create(:group, lastname: "group1", members: alice) }

    current_user { bob }

    specify "adding group1 as a member with the beta role" do
      members_page.visit!
      members_page.add_user! "group1", as: "beta"

      expect(members_page).to have_added_user "group1"
      expect(members_page).to have_user("Alice Wonderland", group_membership: true)
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
            .each   { |m| m.roles << alpha }
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

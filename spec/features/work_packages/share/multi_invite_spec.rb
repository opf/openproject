# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "Work package sharing",
               :js, :with_cuprite,
               with_ee: %i[work_package_sharing] do
  shared_let(:view_work_package_role) { create(:view_work_package_role) }
  shared_let(:comment_work_package_role) { create(:comment_work_package_role) }
  shared_let(:edit_work_package_role) { create(:edit_work_package_role) }

  shared_let(:not_shared_yet_with_user) { create(:user, firstname: "Not shared Yet", lastname: "User") }
  shared_let(:another_not_shared_yet_with_user) { create(:user, firstname: "Another not yet shared", lastname: "User") }
  shared_let(:richard) { create(:user, firstname: "Richard", lastname: "Hendricks") }

  shared_let(:not_shared_yet_with_group) { create(:group, members: [richard]) }
  shared_let(:empty_group) { create(:group, members: []) }

  let(:project) do
    create(:project,
           members: { current_user => [sharer_role] })
  end

  let(:sharer_role) do
    create(:project_role,
           permissions: %i(view_work_packages
                           view_shared_work_packages
                           share_work_packages))
  end
  let(:work_package) do
    create(:work_package, project:) do |wp|
      create(:work_package_member, entity: wp, user: richard, roles: [edit_work_package_role])
    end
  end

  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }
  let(:share_modal) { Components::Sharing::WorkPackages::ShareModal.new(work_package) }

  current_user { create(:user, firstname: "Signed in", lastname: "User") }

  def shared_principals
    Principal.where(id: Member.of_work_package(work_package).select(:user_id))
  end

  def inherited_member_roles(group:)
    MemberRole.where(inherited_from: MemberRole.where(member_id: group.memberships))
  end

  context "when having share permission" do
    it "allows seeing and administrating sharing" do
      work_package_page.visit!

      # Clicking on the share button opens a modal which lists all of the users a work package
      # is explicitly shared with.
      # Project members are not listed unless the work package is also shared with them explicitly.
      work_package_page.click_share_button

      aggregate_failures "Inviting multiple users or groups at once" do
        share_modal.expect_shared_count_of(1)

        # Inviting multiple users at once
        share_modal.invite_users([not_shared_yet_with_user, another_not_shared_yet_with_user], "Edit")

        share_modal.expect_shared_count_of(3)

        share_modal.expect_shared_with(not_shared_yet_with_user, "Edit", position: 1)
        share_modal.expect_shared_with(another_not_shared_yet_with_user, "Edit", position: 2)

        # They can be removed again
        share_modal.remove_user(not_shared_yet_with_user)
        # The additional check is needed because the second removal would otherwise be too fast for the test execution
        share_modal.expect_shared_count_of(2)

        share_modal.remove_user(another_not_shared_yet_with_user)
        share_modal.expect_shared_count_of(1)

        # Groups can be added simultaneously as well
        share_modal.invite_users([not_shared_yet_with_group, empty_group], "Comment")

        share_modal.expect_shared_count_of(3)

        share_modal.expect_shared_with(not_shared_yet_with_group, "Comment", position: 1)
        share_modal.expect_shared_with(empty_group, "Comment", position: 2)

        # They can be removed again
        share_modal.remove_user(not_shared_yet_with_group)
        share_modal.expect_shared_count_of(2)

        share_modal.remove_user(empty_group)
        share_modal.expect_shared_count_of(1)

        # We can also mix
        share_modal.invite_users([not_shared_yet_with_user, empty_group], "View")

        share_modal.expect_shared_count_of(3)

        share_modal.expect_shared_with(not_shared_yet_with_user, "View", position: 1)
        share_modal.expect_shared_with(empty_group, "View", position: 2)

        # They can be removed again
        share_modal.remove_user(not_shared_yet_with_user)
        share_modal.expect_shared_count_of(2)

        share_modal.remove_user(empty_group)
        share_modal.expect_shared_count_of(1)
      end

      share_modal.close
      work_package_page.click_share_button

      aggregate_failures "Re-opening the modal after changes performed" do
        # This user preserved
        share_modal.expect_shared_with(richard, "Edit", position: 1)

        # The users have been removed
        share_modal.expect_not_shared_with(not_shared_yet_with_user)
        share_modal.expect_not_shared_with(another_not_shared_yet_with_user)

        # This groups have been removed
        share_modal.expect_not_shared_with(not_shared_yet_with_group)
        share_modal.expect_not_shared_with(empty_group)

        share_modal.expect_shared_count_of(1)
      end
    end
  end

  context "when starting with no shares yet" do
    let(:work_package) { create(:work_package, project:) }
    let(:global_manager_user) { create(:user, global_permissions: %i[manage_user create_user]) }
    let(:current_user) { global_manager_user }

    before do
      work_package_page.visit!
      work_package_page.click_share_button
    end

    it "allows adding multiple users and updates the modal correctly" do
      share_modal.expect_open
      share_modal.expect_blankslate

      share_modal.invite_users([not_shared_yet_with_user, another_not_shared_yet_with_user], "Edit")

      share_modal.expect_shared_count_of(2)

      # Due to the exception of starting from a blankslate, the whole modal is re-rendered.
      # Thus the principals are sorted alphabetically, and not by the time there were added
      share_modal.expect_shared_with(not_shared_yet_with_user, "Edit", position: 2)
      share_modal.expect_shared_with(another_not_shared_yet_with_user, "Edit", position: 1)

      # They can be removed again
      share_modal.remove_user(not_shared_yet_with_user)
      # The additional check is needed because the second removal would otherwise be too fast for the test execution
      share_modal.expect_shared_count_of(1)

      share_modal.remove_user(another_not_shared_yet_with_user)
      share_modal.expect_blankslate
    end
  end

  context "when having global invite permission" do
    let(:global_manager_user) { create(:user, global_permissions: %i[manage_user create_user]) }
    let(:current_user) { global_manager_user }

    it "allows creating multiple users at once" do
      work_package_page.visit!
      work_package_page.click_share_button

      share_modal.expect_open
      share_modal.expect_shared_count_of(1)

      # Invite two users that does not exist yet
      share_modal.invite_users(["hello@world.de", "aloha@world.de"], "Comment")

      # New user is shown in the list of shares
      share_modal.expect_shared_count_of(3)

      # New user is created
      new_users = User.last(2)

      share_modal.expect_shared_with(new_users[0], "Comment", position: 1)
      share_modal.expect_shared_with(new_users[1], "Comment", position: 2)

      # The new users can be interacted with
      share_modal.change_role(new_users[0], "View")
      share_modal.expect_shared_with(new_users[0], "View", position: 1)
      share_modal.change_role(new_users[1], "View")
      share_modal.expect_shared_with(new_users[1], "View", position: 2)
      share_modal.expect_shared_count_of(3)

      # The new users can be updated simultaneously
      share_modal.invite_user(new_users, "Edit")
      share_modal.expect_shared_with(new_users[0], "Edit", position: 1)
      share_modal.expect_shared_with(new_users[1], "Edit", position: 2)
      share_modal.expect_shared_count_of(3)

      # The new users can be deleted
      share_modal.remove_user(new_users[0])
      share_modal.expect_not_shared_with(new_users[0])
      share_modal.remove_user(new_users[1])
      share_modal.expect_not_shared_with(new_users[1])
      share_modal.expect_shared_count_of(1)
    end

    it "allows sharing with an existing user and creating a new one at the same time" do
      work_package_page.visit!
      work_package_page.click_share_button

      share_modal.expect_open
      share_modal.expect_shared_count_of(1)

      # Add an existing and a non-existing user to the autocompleter
      share_modal.select_existing_user not_shared_yet_with_user
      share_modal.select_not_existing_user_option "hello@world.de"

      share_modal.select_invite_role("View")
      within share_modal.modal_element do
        click_button "Share"
      end

      # Two users are added
      share_modal.expect_shared_count_of(3)

      # New user is created
      new_user = User.last

      share_modal.expect_shared_with(not_shared_yet_with_user, "View", position: 1)
      share_modal.expect_shared_with(new_user, "View", position: 2)
    end

    context "and an instance user limit" do
      before do
        allow(OpenProject::Enterprise).to receive_messages(
          user_limit: 10,
          open_seats_count: 1
        )
      end

      it "shows a warning as soon as you reach the user limit" do
        work_package_page.visit!
        work_package_page.click_share_button

        share_modal.expect_open
        share_modal.expect_shared_count_of(1)

        # Add a non-existing user to the autocompleter
        share_modal.select_not_existing_user_option "hello@world.de"
        share_modal.expect_no_user_limit_warning

        # Add another non-existing user that would exceed the user limit
        share_modal.select_not_existing_user_option "hola@world.de"
        share_modal.expect_user_limit_warning
      end
    end
  end
end

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

  shared_let(:view_user) { create(:user, firstname: "View", lastname: "User") }
  shared_let(:comment_user) { create(:user, firstname: "Comment", lastname: "User") }
  shared_let(:edit_user) { create(:user, firstname: "Edit", lastname: "User") }
  shared_let(:non_shared_project_user) { create(:user, firstname: "Non Shared Project", lastname: "User") }
  shared_let(:shared_project_user) { create(:user, firstname: "Shared Project", lastname: "User") }
  shared_let(:not_shared_yet_with_user) { create(:user, firstname: "Not shared Yet", lastname: "User") }

  shared_let(:richard) { create(:user, firstname: "Richard", lastname: "Hendricks") }
  shared_let(:dinesh) { create(:user, firstname: "Dinesh", lastname: "Chugtai") }
  shared_let(:gilfoyle) { create(:user, firstname: "Bertram", lastname: "Gilfoyle") }
  shared_let(:not_shared_yet_with_group) { create(:group, members: [richard, dinesh, gilfoyle]) }

  let(:project) do
    create(:project,
           members: { current_user => [sharer_role],
                      # The roles of those users don't really matter, reusing the roles
                      # to save some creation work.
                      non_shared_project_user => [sharer_role],
                      shared_project_user => [sharer_role] })
  end
  let(:sharer_role) do
    create(:project_role,
           permissions: %i(view_work_packages
                           view_shared_work_packages
                           manage_members
                           share_work_packages))
  end
  let(:work_package) do
    create(:work_package, project:) do |wp|
      create(:work_package_member, entity: wp, user: view_user, roles: [view_work_package_role])
      create(:work_package_member, entity: wp, user: comment_user, roles: [comment_work_package_role])
      create(:work_package_member, entity: wp, user: edit_user, roles: [edit_work_package_role])
      create(:work_package_member, entity: wp, user: shared_project_user, roles: [edit_work_package_role])
      create(:work_package_member, entity: wp, user: current_user, roles: [view_work_package_role])
      create(:work_package_member, entity: wp, user: dinesh, roles: [edit_work_package_role])
    end
  end
  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }
  let(:share_modal) { Components::Sharing::WorkPackages::ShareModal.new(work_package) }
  let(:members_page) { Pages::Members.new project.identifier }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:columns) { Components::WorkPackages::Columns.new }
  let(:wp_modal) { Components::WorkPackages::TableConfigurationModal.new }

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
      work_package_page.expect_share_button_count(6)
      work_package_page.click_share_button

      aggregate_failures "Initial shares list" do
        share_modal.expect_title(I18n.t("js.work_packages.sharing.title"))
        share_modal.expect_shared_with(comment_user, "Comment", position: 1)
        share_modal.expect_shared_with(dinesh, "Edit", position: 2)
        share_modal.expect_shared_with(edit_user, "Edit", position: 3)
        share_modal.expect_shared_with(shared_project_user, "Edit", position: 4)
        # The current users share is also displayed but not editable
        share_modal.expect_shared_with(current_user, position: 5, editable: false)
        share_modal.expect_shared_with(view_user, "View", position: 6)

        share_modal.expect_not_shared_with(non_shared_project_user)
        share_modal.expect_not_shared_with(not_shared_yet_with_user)

        share_modal.expect_shared_count_of(6)
      end

      aggregate_failures "Inviting a user for the first time" do
        # Inviting a user will lead to that user being prepended to the list together with the rest of the shared with users.
        share_modal.invite_user(not_shared_yet_with_user, "View")

        share_modal.expect_shared_with(not_shared_yet_with_user, "View", position: 1)
        share_modal.expect_shared_count_of(7)
      end

      aggregate_failures "Removing a user" do
        # Removing a share will lead to that user being removed from the list of shared with users.
        share_modal.remove_user(edit_user)
        share_modal.expect_not_shared_with(edit_user)
        share_modal.expect_shared_count_of(6)
      end

      aggregate_failures "Re-inviting a user" do
        # Adding a user multiple times will lead to the user's role being updated.
        share_modal.invite_user(not_shared_yet_with_user, "Edit")
        share_modal.expect_shared_with(not_shared_yet_with_user, "Edit", position: 1)
        share_modal.expect_shared_count_of(6)

        # Sent out email only on first share and not again when updating.
        perform_enqueued_jobs
        expect(ActionMailer::Base.deliveries.size).to eq(1)
      end

      aggregate_failures "Updating a share" do
        # Updating the share
        share_modal.change_role(not_shared_yet_with_user, "Comment")
        share_modal.expect_shared_with(not_shared_yet_with_user, "Comment", position: 1)
        share_modal.expect_shared_count_of(6)

        # Sent out email only on first share and not again when updating so the
        # count should still be 1.
        perform_enqueued_jobs
        expect(ActionMailer::Base.deliveries.size).to eq(1)
      end

      aggregate_failures "Inviting a group" do
        # Inviting a group propagates the membership to the group's users. However, these propagated
        # memberships are not expected to be visible.
        share_modal.invite_group(not_shared_yet_with_group, "View")
        share_modal.expect_shared_with(not_shared_yet_with_group, "View", position: 1)

        # This user has a share independent of the group's share. Hence, that Role prevails
        share_modal.expect_shared_with(dinesh, "Edit")
        share_modal.expect_not_shared_with(richard)
        share_modal.expect_not_shared_with(gilfoyle)

        share_modal.expect_shared_count_of(7)

        expect(shared_principals)
          .to include(not_shared_yet_with_group,
                      richard,
                      gilfoyle,
                      dinesh)

        perform_enqueued_jobs
        # Sent out an email only to the group members that weren't already
        # previously shared the work package (richard and gilfoyle), so count increased to 3
        expect(ActionMailer::Base.deliveries.size).to eq(3)
      end

      aggregate_failures "Inviting a group member with its own independent role" do
        # Inviting a group user to a Work Package independently of the the group displays
        # said user in the shares list
        share_modal.invite_user(gilfoyle, "Comment")
        share_modal.expect_shared_with(gilfoyle, "Comment", position: 1)
        share_modal.expect_shared_count_of(8)

        perform_enqueued_jobs
        # No emails sent out since the user was already previously invited via the group.
        # Hence, count should remain at 3
        expect(ActionMailer::Base.deliveries.size).to eq(3)
      end

      aggregate_failures "Updating a group's share" do
        # Updating a group's share role also propagates to the inherited member roles of
        # its users
        share_modal.change_role(not_shared_yet_with_group, "Comment")
        wait_for_network_idle

        share_modal.expect_shared_with(not_shared_yet_with_group, "Comment")
        share_modal.expect_shared_count_of(8)
        expect(inherited_member_roles(group: not_shared_yet_with_group))
          .to all(have_attributes(role: comment_work_package_role))

        perform_enqueued_jobs
        # No emails sent out on updates
        expect(ActionMailer::Base.deliveries.size).to eq(3)
      end

      aggregate_failures "Removing a group share" do
        # When removing a group's share, its users also get their inherited member roles removed
        # while keeping member roles that were granted independently of the group
        share_modal.remove_user(not_shared_yet_with_group)
        wait_for_network_idle

        share_modal.expect_not_shared_with(not_shared_yet_with_group)
        share_modal.expect_not_shared_with(richard)
        share_modal.expect_shared_with(dinesh, "Edit")
        share_modal.expect_shared_with(gilfoyle, "Comment")
        share_modal.expect_shared_count_of(7)
        expect(inherited_member_roles(group: not_shared_yet_with_group))
          .to be_empty

        expect(shared_principals)
          .to include(gilfoyle, dinesh)
        expect(shared_principals)
          .not_to include(not_shared_yet_with_group, richard)
      end

      share_modal.close
      work_package_page.expect_share_button_count(7)
      work_package_page.click_share_button

      aggregate_failures "Re-opening the modal after changes performed" do
        # This user preserved its group independent share
        share_modal.expect_shared_with(gilfoyle, "Comment", position: 1)
        share_modal.expect_shared_with(comment_user, "Comment", position: 2)
        # This user preserved its group independent share
        share_modal.expect_shared_with(dinesh, "Edit", position: 3)
        # This user's role was updated
        share_modal.expect_shared_with(not_shared_yet_with_user, "Comment", position: 4)
        # These users were not changed
        share_modal.expect_shared_with(shared_project_user, "Edit", position: 5)
        share_modal.expect_shared_with(current_user, position: 6, editable: false)
        share_modal.expect_shared_with(view_user, "View", position: 7)

        # This group's share was revoked
        share_modal.expect_not_shared_with(not_shared_yet_with_group)
        # This user's share was revoked via its group
        share_modal.expect_not_shared_with(richard)
        # This user's share was revoked
        share_modal.expect_not_shared_with(edit_user)
        # This user has never been added
        share_modal.expect_not_shared_with(non_shared_project_user)

        share_modal.expect_shared_count_of(7)
      end

      visit project_members_path(project)

      aggregate_failures "Observing the shared members with view permission" do
        members_page.click_menu_item "View"
        expect(members_page).to have_user view_user.name
        members_page.in_user_row(view_user) do
          expect(page).to have_text "1 work package"
        end
        expect(members_page).not_to have_user gilfoyle.name
        expect(members_page).not_to have_user comment_user.name
        expect(members_page).not_to have_user dinesh.name
      end

      aggregate_failures "Observing the shared members with comment permission" do
        members_page.click_menu_item "Comment"
        expect(members_page).to have_user gilfoyle.name
        members_page.in_user_row(gilfoyle) do
          expect(page).to have_text "1 work package"
        end
        expect(members_page).to have_user comment_user.name
        expect(members_page).not_to have_user view_user.name
        expect(members_page).not_to have_user dinesh.name
      end

      aggregate_failures "Observing the shared members with edit permission" do
        members_page.click_menu_item "Edit"
        expect(members_page).to have_user dinesh.name
        expect(members_page).not_to have_user gilfoyle.name
        expect(members_page).not_to have_user comment_user.name
        expect(members_page).not_to have_user view_user.name
      end

      aggregate_failures "Showing the shared users in the table" do
        wp_table.visit!

        wp_modal.open!
        wp_modal.switch_to "Columns"

        columns.assume_opened
        columns.uncheck_all save_changes: false
        columns.add "ID", save_changes: false
        columns.add "Subject", save_changes: false
        columns.add "Shared with", save_changes: false
        columns.apply

        wp_row = wp_table.row(work_package)
        expect(wp_row).to have_css(".wp-table--cell-td.sharedWithUsers .badge", text: "7")
        wp_row.find(".wp-table--cell-td.sharedWithUsers .badge").click

        share_modal.expect_title(I18n.t("js.work_packages.sharing.title"))
        share_modal.expect_shared_count_of(7)
      end
    end

    it "lets the sharer know a user needs to be selected to share the work package with them" do
      work_package_page.visit!
      work_package_page.click_share_button

      share_modal.expect_open
      share_modal.click_share
      share_modal.expect_select_a_user_hint

      share_modal.invite_user(not_shared_yet_with_user, "View")
      share_modal.expect_shared_with(not_shared_yet_with_user, position: 1)
      share_modal.expect_no_select_a_user_hint
    end
  end

  context "when lacking share permission but having the viewing permission" do
    let(:sharer_role) do
      create(:project_role,
             permissions: %i(view_work_packages
                             view_shared_work_packages))
    end

    it "allows seeing shares but not editing" do
      work_package_page.visit!

      # Clicking on the share button opens a modal which lists all of the users a work package
      # is explicitly shared with.
      # Project members are not listed unless the work package is also shared with them explicitly.
      work_package_page.click_share_button

      share_modal.expect_open
      share_modal.expect_shared_with(view_user, editable: false)
      share_modal.expect_shared_with(comment_user, editable: false)
      share_modal.expect_shared_with(dinesh, editable: false)
      share_modal.expect_shared_with(edit_user, editable: false)
      share_modal.expect_shared_with(shared_project_user, editable: false)
      share_modal.expect_shared_with(current_user, editable: false)

      share_modal.expect_not_shared_with(non_shared_project_user)
      share_modal.expect_not_shared_with(not_shared_yet_with_user)

      share_modal.expect_shared_count_of(6)

      share_modal.expect_no_invite_option
    end
  end

  shared_examples_for "'Share' button is not rendered" do
    it "doesn't render the 'Share' button" do
      work_package_page.visit!

      within work_package_page.toolbar do
        # The button's rendering is conditional to the
        # response of the capabilities request for +shares/index+.
        # Hence, not waiting for the network to be idle could lead to
        # false positives on the button not being rendered because
        # its request is still pending.
        wait_for_network_idle(timeout: 10)
        expect(page).to have_no_button("Share")
      end
    end
  end

  context "without the viewing permission" do
    let(:sharer_role) do
      create(:project_role,
             permissions: %i(view_work_packages))
    end

    it_behaves_like "'Share' button is not rendered"
  end

  context "when having global invite permission" do
    let(:global_manager_user) { create(:user, global_permissions: %i[manage_user create_user]) }
    let(:current_user) { global_manager_user }
    let(:locked_user) { create(:user, mail: "holly@openproject.com", status: :locked) }

    before do
      work_package_page.visit!
      work_package_page.click_share_button
    end

    it "allows inviting and directly sharing with a user who is not part of the instance yet" do
      share_modal.expect_open
      share_modal.expect_shared_count_of(6)

      # Invite a user that does not exist yet
      share_modal.invite_user("hello@world.de", "View")

      # New user is shown in the list of shares
      share_modal.expect_shared_count_of(7)

      # New user is created
      new_user = User.last
      share_modal.expect_shared_with(new_user, "View", position: 1)

      perform_enqueued_jobs
      # Only one combined email for create and share should be send out
      expect(ActionMailer::Base.deliveries.size).to eq(1)

      # The new user can be interacted with
      share_modal.change_role(new_user, "Comment")
      share_modal.expect_shared_with(new_user, "Comment", position: 1)
      share_modal.expect_shared_count_of(7)

      # The new user can be updated
      share_modal.invite_user(new_user, "Edit")
      share_modal.expect_shared_with(new_user, "Edit", position: 1)
      share_modal.expect_shared_count_of(7)

      # The invite can be resent
      share_modal.resend_invite(new_user)
      share_modal.expect_invite_resent(new_user)
      perform_enqueued_jobs
      # Another invitation email sent out to the user
      expect(ActionMailer::Base.deliveries.size).to eq(2)

      # The new user can be deleted
      share_modal.remove_user(new_user)
      share_modal.expect_not_shared_with(new_user)
      share_modal.expect_shared_count_of(6)
    end

    it "shows an error message when inviting an existing locked user" do
      share_modal.expect_open
      share_modal.expect_shared_count_of(6)

      # Try to invite the locked user
      share_modal.search_user(locked_user.mail)

      # The locked user email is not listed in the result set, instead it can be invited
      share_modal.expect_ng_option("", 'Send invite to"holly@openproject.com"', results_selector: "body")
      share_modal.expect_no_ng_option("", locked_user.name, results_selector: "body")

      # Invite the email address
      share_modal.invite_user(locked_user.mail, "View")

      # The number of shared people has not changed, but an error message is shown
      share_modal.expect_shared_count_of(6)
      share_modal.expect_error_message(I18n.t("sharing.warning_locked_user", user: locked_user.name))
    end
  end

  context "when lacking global invite permission" do
    it "does not allow creating a user who is not part of the instance yet" do
      work_package_page.visit!
      work_package_page.click_share_button

      share_modal.expect_open
      share_modal.expect_shared_count_of(6)

      # Search for a user that does not exist
      share_modal.search_user("hello@world.de")

      # There is no option to directly create and share the WP for the unknown email address
      share_modal.expect_no_ng_option("", 'Send invite to"hello@world.de"', results_selector: "body")
      share_modal.expect_ng_option("", "No items found", results_selector: "body")
    end
  end
end

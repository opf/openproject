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

RSpec.describe "Work Packages", "Bulk Sharing",
               :js, :with_cuprite,
               with_ee: %i[work_package_sharing] do
  shared_let(:view_work_package_role)    { create(:view_work_package_role)    }
  shared_let(:comment_work_package_role) { create(:comment_work_package_role) }
  shared_let(:edit_work_package_role)    { create(:edit_work_package_role)    }

  shared_let(:sharer_role) do
    create(:project_role, permissions: %i[view_work_packages
                                          view_shared_work_packages
                                          share_work_packages])
  end

  shared_let(:viewer_role) do
    create(:project_role, permissions: %i[view_work_packages
                                          view_shared_work_packages])
  end

  shared_let(:sharer) { create(:user, firstname: "Sharer", lastname: "User") }
  shared_let(:viewer) { create(:user, firstname: "Viewer", lastname: "User") }

  shared_let(:project) do
    create(:project, members: { sharer => [sharer_role], viewer => [viewer_role] })
  end

  shared_let(:dinesh)   { create(:user, firstname: "Dinesh", lastname: "Chugtai")    }
  shared_let(:gilfoyle) { create(:user, firstname: "Bertram", lastname: "Gilfoyle")  }
  shared_let(:richard)  { create(:user, firstname: "Richard", lastname: "Hendricks") }

  shared_let(:work_package) do
    create(:work_package, project:) do |wp|
      create(:work_package_member, principal: richard,  entity: wp, roles: [view_work_package_role])
      create(:work_package_member, principal: dinesh,   entity: wp, roles: [edit_work_package_role])
      create(:work_package_member, principal: gilfoyle, entity: wp, roles: [comment_work_package_role])
    end
  end

  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }
  let(:share_modal)       { Components::Sharing::WorkPackages::ShareModal.new(work_package) }

  context "when having share permission" do
    current_user { sharer }

    it "allows administrating shares in bulk" do
      work_package_page.visit!

      work_package_page.click_share_button

      share_modal.expect_open
      share_modal.expect_shared_count_of(3)

      aggregate_failures "Selection behavior" do
        # Bulk actions hidden until at least one selection
        share_modal.expect_bulk_actions_not_available

        # Selecting one individually
        share_modal.select_shares(richard)
        share_modal.expect_selected(richard)
        share_modal.expect_selected_count_of(1)
        share_modal.expect_select_all_untoggled
        # Available now
        share_modal.expect_bulk_actions_available
        share_modal.expect_bulk_update_label("View")

        # Toggling all selects all
        share_modal.toggle_select_all
        share_modal.expect_selected(richard, dinesh, gilfoyle)
        share_modal.expect_selected_count_of(3)
        share_modal.expect_select_all_toggled
        share_modal.expect_bulk_actions_available
        share_modal.expect_bulk_update_label("Mixed")

        # Deselecting one individually
        share_modal.deselect_shares(richard)
        share_modal.expect_selected(dinesh, gilfoyle)
        share_modal.expect_selected_count_of(2)
        share_modal.expect_select_all_untoggled
        share_modal.expect_bulk_actions_available
        share_modal.expect_bulk_update_label("Mixed")

        # Re-selecting the missing share
        share_modal.select_shares(richard)
        share_modal.expect_selected(richard, dinesh, gilfoyle)
        share_modal.expect_selected_count_of(3)
        share_modal.expect_select_all_toggled
        share_modal.expect_bulk_actions_available
        share_modal.expect_bulk_update_label("Mixed")

        # De-selecting all
        share_modal.toggle_select_all
        share_modal.expect_deselected(richard, dinesh, gilfoyle)
        share_modal.expect_shared_count_of(3)
        share_modal.expect_select_all_untoggled
        # No longer available
        share_modal.expect_bulk_actions_not_available

        # Re-selecting all
        share_modal.toggle_select_all
        share_modal.expect_selected(richard, dinesh, gilfoyle)
        share_modal.expect_selected_count_of(3)
        share_modal.expect_select_all_toggled
        # Available again
        share_modal.expect_bulk_actions_available
        share_modal.expect_bulk_update_label("Mixed")

        # De-selecting all individually
        share_modal.deselect_shares(richard, dinesh, gilfoyle)
        share_modal.expect_shared_count_of(3)
        share_modal.expect_select_all_untoggled
        # No longer available
        share_modal.expect_bulk_actions_not_available
      end

      aggregate_failures "Preserving selected states when performing individual deletions" do
        share_modal.select_shares(richard, dinesh)
        share_modal.expect_selected_count_of(2)
        share_modal.expect_select_all_untoggled
        share_modal.expect_bulk_update_label("Mixed")

        share_modal.remove_user(gilfoyle)
        share_modal.expect_not_shared_with(gilfoyle)

        share_modal.expect_selected(richard, dinesh)
        share_modal.expect_selected_count_of(2)
        share_modal.expect_select_all_toggled
        share_modal.expect_bulk_update_label("Mixed")

        share_modal.invite_user(gilfoyle, "Comment")
        share_modal.expect_shared_with(gilfoyle)
        share_modal.expect_selected(richard, dinesh)
        share_modal.expect_selected_count_of(2)
        share_modal.expect_select_all_untoggled
        share_modal.expect_bulk_update_label("Mixed")
      end

      aggregate_failures "Preserving selected states when performing individual updates" do
        share_modal.change_role(gilfoyle, "View")
        share_modal.expect_shared_with(gilfoyle, "View")

        share_modal.expect_selected(richard, dinesh)
        share_modal.expect_selected_count_of(2)
        share_modal.expect_select_all_untoggled
        share_modal.expect_bulk_update_label("Mixed")

        share_modal.toggle_select_all
        share_modal.expect_selected_count_of(3)
        share_modal.expect_select_all_toggled
        share_modal.expect_bulk_update_label("Mixed")

        share_modal.change_role(gilfoyle, "Edit")
        share_modal.expect_shared_with(gilfoyle, "Edit")
        share_modal.expect_selected_count_of(3)
        share_modal.expect_select_all_toggled
        share_modal.expect_bulk_update_label("Mixed")
      end

      # Reset
      share_modal.toggle_select_all
      share_modal.expect_select_all_untoggled

      aggregate_failures "Bulk deletion" do
        share_modal.select_shares(richard, dinesh)
        share_modal.expect_selected(richard, dinesh)
        share_modal.expect_selected_count_of(2)
        share_modal.expect_select_all_untoggled

        share_modal.bulk_remove

        share_modal.expect_not_shared_with(richard, dinesh)
        share_modal.expect_shared_with(gilfoyle)
        share_modal.expect_shared_count_of(1)

        share_modal.select_shares(gilfoyle)
        share_modal.expect_selected(gilfoyle)
        share_modal.expect_selected_count_of(1)
        share_modal.expect_select_all_toggled
        share_modal.bulk_remove

        share_modal.expect_blankslate
      end

      # Re-populate
      share_modal.invite_user(richard, "View")
      share_modal.expect_shared_with(richard)
      share_modal.invite_user(dinesh, "Comment")
      share_modal.expect_shared_with(dinesh)

      aggregate_failures "Bulk updating" do
        share_modal.select_shares(richard)
        share_modal.expect_selected(richard)
        share_modal.expect_selected_count_of(1)
        share_modal.expect_bulk_update_label("View")

        share_modal.bulk_update("Edit")

        share_modal.expect_shared_with(richard, "Edit")
        share_modal.expect_shared_with(dinesh, "Comment")
        share_modal.expect_selected(richard)
        share_modal.expect_selected_count_of(1)
        share_modal.expect_bulk_update_label("Edit")

        share_modal.select_shares(richard, dinesh)
        share_modal.expect_selected(richard, dinesh)
        share_modal.expect_selected_count_of(2)
        share_modal.expect_bulk_update_label("Mixed")

        share_modal.bulk_update("View")

        share_modal.expect_shared_with(richard, "View")
        share_modal.expect_shared_with(dinesh, "View")
        share_modal.expect_selected(richard, dinesh)
        share_modal.expect_selected_count_of(2)
        share_modal.expect_bulk_update_label("View")

        share_modal.toggle_select_all
        share_modal.expect_deselected(richard, dinesh)
        share_modal.expect_shared_count_of(2)
      end

      aggregate_failures "Bulk selection disabled when current user is the only shared with user" do
        create(:work_package_member,
               principal: current_user,
               entity: work_package,
               roles: [comment_work_package_role])

        share_modal.close
        share_modal.expect_closed

        work_package_page.click_share_button
        share_modal.expect_open

        share_modal.expect_shared_count_of(3)
        share_modal.expect_select_all_available

        share_modal.remove_user(richard)
        share_modal.expect_not_shared_with(richard)
        share_modal.remove_user(dinesh)
        share_modal.expect_not_shared_with(dinesh)

        share_modal.expect_shared_count_of(1)
        share_modal.expect_select_all_not_available
        share_modal.expect_bulk_actions_not_available

        share_modal.invite_user(richard, "View")
        share_modal.expect_shared_with(richard, "View")
        share_modal.expect_shared_count_of(2)

        share_modal.expect_select_all_available
      end
    end
  end

  context "without share permission" do
    current_user { viewer }

    it "does not allow bulk sharing" do
      work_package_page.visit!

      work_package_page.click_share_button
      share_modal.expect_open

      share_modal.expect_shared_count_of(3)
      share_modal.expect_shared_with(richard, editable: false)
      share_modal.expect_shared_with(dinesh,  editable: false)
      share_modal.expect_shared_with(gilfoyle, editable: false)

      share_modal.expect_select_all_not_available
      share_modal.expect_bulk_actions_not_available
      share_modal.expect_not_selectable(richard, dinesh, gilfoyle)
    end
  end
end

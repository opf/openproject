# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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

require 'spec_helper'

RSpec.describe 'Work package sharing',
               :js,
               :with_cuprite,
               with_flag: { work_package_sharing: true } do
  let(:sharer_role) do
    create(:project_role,
           permissions: %i(view_work_packages
                           view_shared_work_packages
                           share_work_packages))
  end
  let(:view_work_package_role) { create(:view_work_package_role) }
  let(:comment_work_package_role) { create(:comment_work_package_role) }
  let(:edit_work_package_role) { create(:edit_work_package_role) }
  let(:project) do
    create(:project,
           members: { current_user => [sharer_role],
                      # The roles of those users don't really matter, reusing the roles
                      # to save some creation work.
                      non_shared_project_user => [sharer_role],
                      shared_project_user => [sharer_role] })
  end
  let(:work_package) do
    create(:work_package, project:) do |wp|
      create(:work_package_member, entity: wp, user: view_user, roles: [view_work_package_role])
      create(:work_package_member, entity: wp, user: comment_user, roles: [comment_work_package_role])
      create(:work_package_member, entity: wp, user: edit_user, roles: [edit_work_package_role])
      create(:work_package_member, entity: wp, user: shared_project_user, roles: [edit_work_package_role])
      create(:work_package_member, entity: wp, user: current_user, roles: [view_work_package_role])
    end
  end

  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }
  let(:share_modal) { Components::WorkPackages::ShareModal.new(work_package) }

  let!(:view_user) { create(:user, firstname: 'View', lastname: 'User') }
  let!(:comment_user) { create(:user, firstname: 'Comment', lastname: 'User') }
  let!(:edit_user) { create(:user, firstname: 'Edit', lastname: 'User') }
  let!(:non_shared_project_user) { create(:user, firstname: 'Non Shared Project', lastname: 'User') }
  let!(:shared_project_user) { create(:user, firstname: 'Shared Project', lastname: 'User') }
  let!(:not_shared_yet_with_user) { create(:user, firstname: 'Not shared Yet', lastname: 'User') }

  let!(:dinesh) { create(:user, firstname: 'Dinesh', lastname: 'Chugtai') }
  let!(:gilfoyle) { create(:user, firstname: 'Bertram', lastname: 'Gilfoyle') }
  let!(:not_shared_yet_with_group) { create(:group, members: [dinesh, gilfoyle]) }

  current_user { create(:user, firstname: 'Signed in', lastname: 'User') }

  context 'when having share permission' do
    it 'allows seeing and administrating sharing' do
      work_package_page.visit!

      # Clicking on the share button opens a modal which lists all of the users a work package
      # is explicitly shared with.
      # Project members are not listed unless the work package is also shared with them explicitly.
      click_button 'Share'

      share_modal.expect_open
      share_modal.expect_shared_with(comment_user, 'Comment', position: 1)
      share_modal.expect_shared_with(edit_user, 'Edit', position: 2)
      share_modal.expect_shared_with(shared_project_user, 'Edit', position: 3)
      # The current users share is also displayed but not editable
      share_modal.expect_shared_with(current_user, position: 4, editable: false)
      share_modal.expect_shared_with(view_user, 'View', position: 5)

      share_modal.expect_not_shared_with(non_shared_project_user)
      share_modal.expect_not_shared_with(not_shared_yet_with_user)

      share_modal.expect_shared_count_of(5)

      # Inviting a user will lead to that user being prepended to the list together with the rest of the shared with users.
      share_modal.invite_user(not_shared_yet_with_user, 'View')

      share_modal.expect_shared_with(not_shared_yet_with_user, 'View', position: 1)
      share_modal.expect_shared_count_of(6)

      # Removing a share will lead to that user being removed from the list of shared with users.
      share_modal.remove_user(edit_user)
      share_modal.expect_not_shared_with(edit_user)
      share_modal.expect_shared_count_of(5)

      # Adding a user multiple times will lead to the user's role being updated.
      share_modal.invite_user(not_shared_yet_with_user, 'Edit')
      share_modal.expect_shared_with(not_shared_yet_with_user, 'Edit', position: 1)

      # Sent out email only on first share and not again when updating.
      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to eq(1)

      # Updating the share
      share_modal.change_role(not_shared_yet_with_user, 'Comment')
      share_modal.expect_shared_with(not_shared_yet_with_user, 'Comment', position: 1)

      # Sent out email only on first share and not again when updating so the
      # count should still be 1.
      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to eq(1)

      # Reopening the modal will show the same state as before.
      work_package_page.visit!

      click_button 'Share'

      # These users were not changed
      share_modal.expect_shared_with(comment_user, 'Comment', position: 1)
      # This user's role was updated
      share_modal.expect_shared_with(not_shared_yet_with_user, 'Comment', position: 2)
      share_modal.expect_shared_with(shared_project_user, 'Edit', position: 3)
      share_modal.expect_shared_with(current_user, position: 4, editable: false)
      share_modal.expect_shared_with(view_user, 'View', position: 5)

      # This user's share was revoked
      share_modal.expect_not_shared_with(edit_user)
      # This user has never been added
      share_modal.expect_not_shared_with(non_shared_project_user)

      share_modal.expect_shared_count_of(5)
    end

    it 'allows seeing and managing group sharing' do
      work_package_page.visit!

      click_button 'Share'

      share_modal.expect_open
      share_modal.invite_group(not_shared_yet_with_group, 'Comment')
      share_modal.expect_shared_with(not_shared_yet_with_group, 'Comment', position: 1)

      # Close and re-open modal
      share_modal.close
      share_modal.expect_closed
      click_button 'Share'
      share_modal.expect_open

      # Shares are propagated to the group's users
      share_modal.expect_shared_with(not_shared_yet_with_group, 'Comment')
      share_modal.expect_shared_with(dinesh, 'Comment')
      share_modal.expect_shared_with(gilfoyle, 'Comment')
    end
  end

  context 'when lacking share permission' do
    let(:sharer_role) do
      create(:project_role,
             permissions: %i(view_work_packages
                             view_shared_work_packages))
    end

    it 'allows seeing shares but not editing' do
      work_package_page.visit!

      # Clicking on the share button opens a modal which lists all of the users a work package
      # is explicitly shared with.
      # Project members are not listed unless the work package is also shared with them explicitly.
      click_button 'Share'

      share_modal.expect_open
      share_modal.expect_shared_with(view_user, editable: false)
      share_modal.expect_shared_with(comment_user, editable: false)
      share_modal.expect_shared_with(edit_user, editable: false)
      share_modal.expect_shared_with(shared_project_user, editable: false)
      share_modal.expect_shared_with(current_user, editable: false)

      share_modal.expect_not_shared_with(non_shared_project_user)
      share_modal.expect_not_shared_with(not_shared_yet_with_user)

      share_modal.expect_shared_count_of(5)

      share_modal.expect_no_invite_option
    end
  end
end

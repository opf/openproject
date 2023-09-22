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
require 'support/pages/work_packages/full_work_package'
require 'support/components/work_packages/share_modal'

RSpec.describe 'Work package sharing', :js do
  let(:sharer_role) do
    # TODO: Remove necessity to have manage_members permission
    create(:role,
           permissions: %i(view_work_packages
                           share_work_packages
                           manage_members))
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
      create(:member, entity: wp, user: view_user, roles: [view_work_package_role])
      create(:member, entity: wp, user: comment_user, roles: [comment_work_package_role])
      create(:member, entity: wp, user: edit_user, roles: [edit_work_package_role])
      create(:member, entity: wp, user: shared_project_user, roles: [edit_work_package_role])
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

  current_user { create(:user) }

  # TODO:
  #   - Check title
  #   - Check roles
  #   - Delete case
  it 'allows seeing and administrating sharing' do
    work_package_page.visit!

    # Clicking on the share button opens a modal which lists all of the users a work package
    # is explicitly shared with.
    # Project members are not listed unless the work package is also shared with them explicitly.
    click_button 'Share'

    share_modal.expect_open
    share_modal.expect_shared_with(view_user)
    share_modal.expect_shared_with(comment_user)
    share_modal.expect_shared_with(edit_user)
    share_modal.expect_shared_with(shared_project_user)

    share_modal.expect_not_shared_with(non_shared_project_user)
    share_modal.expect_not_shared_with(not_shared_yet_with_user)

    share_modal.expect_shared_count_of(4)

    # Inviting a user will lead to that user being listed together with the rest of the shared with users.
    share_modal.invite_user(not_shared_yet_with_user)

    share_modal.expect_shared_with(not_shared_yet_with_user)

    share_modal.expect_shared_count_of(5)
  end
end

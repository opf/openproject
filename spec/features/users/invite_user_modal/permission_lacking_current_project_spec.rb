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

RSpec.describe "Inviting user in project the current user is lacking permission in", :js do
  shared_let(:standard) { create(:standard_global_role) }
  let(:modal) do
    Components::Users::InviteUserModal.new project: invite_project,
                                           principal: other_user,
                                           role: view_role
  end
  let(:quick_add) { Components::QuickAddMenu.new }

  let(:view_role) do
    create(:project_role,
           permissions: [])
  end
  let(:invite_role) do
    create(:project_role,
           permissions: %i[manage_members])
  end

  let!(:other_user) { create(:user) }
  let!(:view_project) { create(:project, members: { current_user => view_role }) }
  let!(:invite_project) { create(:project, members: { current_user => invite_role }) }

  current_user do
    create(:user, global_permissions: %i[view_all_principals])
  end

  specify "user cannot invite in current project but for different one" do
    visit project_path(view_project)

    quick_add.expect_visible

    quick_add.toggle

    quick_add.click_link "Invite user"

    wait_for_network_idle

    modal.expect_help_displayed I18n.t("users.invite_user_modal.project.no_invite_rights")

    # Attempting to proceed without having a different project selected

    modal.click_continue

    modal.expect_error_displayed "Project can't be blank."

    # Proceeding with the invite project
    modal.run_all_steps

    # Expect to be added to project
    expect(invite_project.users.reload)
      .to include(other_user)
  end
end

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

RSpec.describe "Invite user modal subprojects", :js, :with_cuprite do
  shared_let(:project) { create(:project, name: "Parent project") }
  shared_let(:subproject) { create(:project, name: "Subproject", parent: project) }
  shared_let(:work_package) { create(:work_package, project: subproject) }
  shared_let(:invitable_user) { create(:user, firstname: "Invitable", lastname: "User") }

  let(:permissions) { %i[view_work_packages edit_work_packages manage_members work_package_assigned] }
  let(:global_permissions) { %i[] }
  let(:modal) do
    Components::Users::InviteUserModal.new project: subproject,
                                           principal: invitable_user,
                                           role:
  end
  let!(:role) do
    create(:project_role,
           name: "Member",
           permissions:)
  end
  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:assignee_field) { wp_page.edit_field :assignee }

  current_user do
    create(:user,
           member_with_roles: { project => role, subproject => role },
           global_permissions:)
  end

  context "with manage permissions in subproject" do
    it "uses the subproject as the preselected project" do
      wp_page.visit!

      assignee_field.activate!

      find(".ng-dropdown-footer button", text: "Invite", wait: 10).click

      modal.expect_open
      modal.within_modal do
        expect(page).to have_css ".ng-value", text: "Subproject"
      end

      modal.run_all_steps

      assignee_field.expect_inactive!
      assignee_field.expect_display_value invitable_user.name

      new_member = subproject.reload.member_principals.find_by(user_id: invitable_user.id)
      expect(new_member).to be_present
      expect(new_member.roles).to eq [role]
    end
  end

  context "without manage permissions in subproject" do
    let(:permissions) { %i[view_work_packages edit_work_packages] }

    it "does not show the invite button of the subproject" do
      wp_page.visit!

      assignee_field.activate!

      expect(page).to have_css ".ng-dropdown-panel"

      expect(page).to have_no_css(".ng-dropdown-footer button", text: "Invite")
    end
  end
end

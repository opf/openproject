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

RSpec.describe "Shared users in the members table", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:role) { create(:project_role, name: "Developer") }

  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:work_package2) { create(:work_package, project:) }

  shared_let(:view_work_package_role) { create(:view_work_package_role) }
  shared_let(:comment_work_package_role) { create(:comment_work_package_role) }

  shared_let(:active_user) { create(:user, firstname: "Active", lastname: "User", status: Principal.statuses[:active]) }
  shared_let(:shared_user) { create(:user, firstname: "Shared", lastname: "User", status: Principal.statuses[:active]) }
  shared_let(:other_shared_user) { create(:user, firstname: "Other", lastname: "User", status: Principal.statuses[:active]) }

  shared_let(:active_user_member) do
    create(:member,
           project:,
           roles: [role],
           principal: active_user)
  end
  shared_let(:active_user_shared_member_view) do
    create(:member,
           project:,
           roles: [view_work_package_role],
           entity: work_package,
           principal: shared_user)
  end
  shared_let(:active_user_shared_member_comment) do
    create(:member,
           project:,
           roles: [comment_work_package_role],
           entity: work_package2,
           principal: shared_user)
  end
  shared_let(:other_shared_member) do
    create(:member,
           project:,
           roles: [view_work_package_role],
           entity: work_package,
           principal: other_shared_user)
  end

  let(:members_page) { Pages::Members.new project.identifier }

  current_user { admin }

  before do
    members_page.visit!

    SeleniumHubWaiter.wait
  end

  it "shows the shared users in the members table and allows filtering it" do
    expect(members_page).to have_user active_user.name
    expect(members_page).to have_user shared_user.name
    expect(members_page).to have_user other_shared_user.name

    members_page.in_user_row(active_user) do
      expect(page).to have_css("td.shared", text: "", exact_text: true)
      expect(page).to have_css("td.roles", text: "Developer")
    end

    members_page.in_user_row(shared_user) do
      expect(page).to have_text "2 work packages"
      expect(page).to have_css("td.roles", text: "", exact_text: true)
    end

    members_page.in_user_row(other_shared_user) do
      expect(page).to have_text "1 work package"
      expect(page).to have_css("td.roles", text: "", exact_text: true)
    end

    members_page.click_menu_item "View"
    expect(members_page).to have_user shared_user.name
    expect(members_page).to have_user other_shared_user.name
    expect(members_page).not_to have_user active_user.name

    members_page.in_user_row(shared_user) do
      expect(page).to have_text "1 work package"
    end

    members_page.in_user_row(other_shared_user) do
      expect(page).to have_text "1 work package"
    end

    members_page.click_menu_item "Comment"
    expect(members_page).to have_user shared_user.name
    expect(members_page).not_to have_user other_shared_user.name
    expect(members_page).not_to have_user active_user.name

    members_page.in_user_row(shared_user) do
      expect(page).to have_text "1 work package"
    end
  end
end

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

RSpec.describe "index placeholder users", :js, with_ee: %i[placeholder_users] do
  let!(:current_user) { create(:admin) }
  let!(:anonymous) { create(:anonymous) }
  let!(:placeholder_user_1) do
    create(:placeholder_user,
           name: "B",
           created_at: 3.minutes.ago)
  end
  let!(:placeholder_user_2) do
    create(:placeholder_user,
           name: "A",
           created_at: 2.minutes.ago)
  end
  let!(:placeholder_user_3) do
    create(:placeholder_user,
           name: "C",
           created_at: 1.minute.ago)
  end
  let(:manager_role) { create(:existing_project_role, permissions: [:manage_members]) }
  let(:member_role) { create(:existing_project_role, permissions: [:view_work_packages]) }
  let(:index_page) { Pages::Admin::PlaceholderUsers::Index.new }

  shared_examples "placeholders index flow" do
    it "shows the placeholder users and allows filtering and ordering" do
      index_page.visit!

      index_page.expect_not_listed(anonymous, current_user)

      # Order is by id, asc
      # so first ones created are on top.
      index_page.expect_listed(placeholder_user_1, placeholder_user_2, placeholder_user_3)

      index_page.order_by("Name")
      index_page.expect_ordered(placeholder_user_2, placeholder_user_1, placeholder_user_3)

      index_page.order_by("Name")
      index_page.expect_ordered(placeholder_user_3, placeholder_user_1, placeholder_user_2)

      index_page.order_by("Created on")
      index_page.expect_ordered(placeholder_user_3, placeholder_user_2, placeholder_user_1)

      index_page.order_by("Created on")
      index_page.expect_ordered(placeholder_user_1, placeholder_user_2, placeholder_user_3)

      index_page.filter_by_name(placeholder_user_3.name)
      index_page.expect_listed(placeholder_user_3)
      index_page.expect_not_listed(placeholder_user_1, placeholder_user_2)
    end
  end

  context "as admin" do
    current_user { create(:admin) }

    it_behaves_like "placeholders index flow"
  end

  context "as user with global permission" do
    current_user { create(:user, global_permissions: %i[manage_placeholder_user]) }

    it_behaves_like "placeholders index flow"

    context "when all placeholder users are not members of any project" do
      before do
        index_page.visit!
      end

      it "allows the deletion of all placeholder users" do
        # Reason: As the placeholder users are not used anywhere it is safe to delete them.
        index_page.expect_delete_button(placeholder_user_1)
        index_page.expect_delete_button(placeholder_user_2)
        index_page.expect_delete_button(placeholder_user_3)
      end
    end

    context "when user is allowed to manage members only in some projects of the placeholder users" do
      let(:shared_project) do
        create(:project, members: {
                 placeholder_user_1 => member_role,
                 placeholder_user_2 => member_role,
                 current_user => manager_role
               })
      end

      let(:not_shared_project) do
        create(:project, members: {
                 placeholder_user_2 => member_role,
                 placeholder_user_3 => member_role
               })
      end

      before do
        shared_project
        not_shared_project

        index_page.visit!
      end

      it "shows the delete buttons where allowed" do
        # Show the delete buttons only for those placeholder users that are only in projects
        # where the current user has the permission to manage members.
        index_page.expect_delete_button(placeholder_user_1)
        index_page.expect_no_delete_button(placeholder_user_2)
        index_page.expect_no_delete_button(placeholder_user_3)
      end
    end
  end

  context "as user without global permission" do
    current_user { create(:user) }

    it "returns an error" do
      index_page.visit!
      expect(page).to have_text "You are not authorized to access this page."
    end
  end
end

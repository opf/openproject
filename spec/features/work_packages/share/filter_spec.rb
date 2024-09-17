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

  shared_let(:project_user) { create(:user, firstname: "Anton") }
  shared_let(:project_user2) { create(:user, firstname: "Bertha") }
  shared_let(:inherited_project_user) { create(:user, firstname: "Caesar") }
  shared_let(:non_project_user) { create(:user, firstname: "Dora") }

  shared_let(:shared_project_group) { create(:group, members: [project_user, inherited_project_user]) }
  shared_let(:shared_non_project_group) { create(:group, members: [project_user2, non_project_user]) }

  let(:project) do
    create(:project,
           members: { current_user => [sharer_role],
                      project_user => [sharer_role],
                      project_user2 => [sharer_role],
                      shared_project_group => [sharer_role] })
  end

  let(:sharer_role) do
    create(:project_role,
           permissions: %i(view_work_packages
                           view_shared_work_packages
                           share_work_packages))
  end
  let(:work_package) do
    create(:work_package, project:) do |wp|
      create(:work_package_member, entity: wp, user: project_user, roles: [view_work_package_role])
      create(:work_package_member, entity: wp, user: project_user2, roles: [comment_work_package_role])
      create(:work_package_member, entity: wp, user: inherited_project_user, roles: [edit_work_package_role])
      create(:work_package_member, entity: wp, user: non_project_user, roles: [edit_work_package_role])
      create(:work_package_member, entity: wp, user: shared_project_group, roles: [edit_work_package_role])
      create(:work_package_member, entity: wp, user: shared_non_project_group, roles: [view_work_package_role])
    end
  end

  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }
  let(:share_modal) { Components::Sharing::WorkPackages::ShareModal.new(work_package) }

  current_user { create(:admin, firstname: "Signed in", lastname: "User") }

  context "when having share permission" do
    before do
      work_package_page.visit!
      work_package_page.click_share_button
    end

    it "allows to filter for the type" do
      share_modal.expect_open
      share_modal.expect_shared_count_of(6)

      # Filter for: project members (users only)
      share_modal.filter("type", I18n.t("sharing.filter.project_member"))
      share_modal.expect_shared_count_of(3)

      share_modal.expect_shared_with(project_user, "View")
      share_modal.expect_shared_with(project_user2, "Comment")
      # The non-project user is listed because it is part of the project group and thus the membership is inherited.
      share_modal.expect_shared_with(inherited_project_user, "Edit")
      share_modal.expect_not_shared_with(non_project_user)
      share_modal.expect_not_shared_with(shared_project_group)
      share_modal.expect_not_shared_with(shared_non_project_group)

      # Filter for: non-project members (users only)
      share_modal.filter("type", I18n.t("sharing.filter.not_project_member"))
      share_modal.expect_shared_count_of(1)

      share_modal.expect_shared_with(non_project_user, "Edit")
      share_modal.expect_not_shared_with(inherited_project_user)
      share_modal.expect_not_shared_with(project_user)
      share_modal.expect_not_shared_with(project_user2)
      share_modal.expect_not_shared_with(shared_project_group)
      share_modal.expect_not_shared_with(shared_non_project_group)

      # Filter for: project members (groups only)
      share_modal.filter("type", I18n.t("sharing.filter.project_group"))
      share_modal.expect_shared_count_of(1)

      share_modal.expect_shared_with(shared_project_group, "Edit")
      share_modal.expect_not_shared_with(project_user)
      share_modal.expect_not_shared_with(project_user2)
      share_modal.expect_not_shared_with(inherited_project_user)
      share_modal.expect_not_shared_with(non_project_user)
      share_modal.expect_not_shared_with(shared_non_project_group)

      # Filter for: non-project members (groups only)
      share_modal.filter("type", I18n.t("sharing.filter.not_project_group"))
      share_modal.expect_shared_count_of(1)

      share_modal.expect_shared_with(shared_non_project_group, "View")
      share_modal.expect_not_shared_with(project_user)
      share_modal.expect_not_shared_with(project_user2)
      share_modal.expect_not_shared_with(inherited_project_user)
      share_modal.expect_not_shared_with(non_project_user)
      share_modal.expect_not_shared_with(shared_project_group)

      # Clicking again on the filter will reset it
      share_modal.filter("type", I18n.t("sharing.filter.not_project_group"))
      share_modal.expect_shared_count_of(6)

      share_modal.expect_shared_with(project_user, "View")
      share_modal.expect_shared_with(project_user2, "Comment")
      share_modal.expect_shared_with(inherited_project_user, "Edit")
      share_modal.expect_shared_with(non_project_user, "Edit")
      share_modal.expect_shared_with(shared_project_group, "Edit")
      share_modal.expect_shared_with(shared_non_project_group, "View")
    end

    it "allows to filter for the role" do
      share_modal.expect_open
      share_modal.expect_shared_count_of(6)

      # Filter for: all principals with Edit permission
      share_modal.filter("role", I18n.t("work_package.permissions.edit"))
      share_modal.expect_shared_count_of(3)

      share_modal.expect_shared_with(inherited_project_user, "Edit")
      share_modal.expect_shared_with(non_project_user, "Edit")
      share_modal.expect_shared_with(shared_project_group, "Edit")
      share_modal.expect_not_shared_with(project_user)
      share_modal.expect_not_shared_with(project_user2)
      share_modal.expect_not_shared_with(shared_non_project_group)

      # Filter for: all principals with View permission
      share_modal.filter("role", I18n.t("work_package.permissions.view"))
      share_modal.expect_shared_count_of(2)

      share_modal.expect_shared_with(project_user, "View")
      share_modal.expect_shared_with(shared_non_project_group, "View")
      share_modal.expect_not_shared_with(project_user2)
      share_modal.expect_not_shared_with(inherited_project_user)
      share_modal.expect_not_shared_with(non_project_user)
      share_modal.expect_not_shared_with(shared_project_group)

      # Filter for: all principals with Comment permission
      share_modal.filter("role", I18n.t("work_package.permissions.comment"))
      share_modal.expect_shared_count_of(1)

      share_modal.expect_shared_with(project_user2, "Comment")
      share_modal.expect_not_shared_with(project_user)
      share_modal.expect_not_shared_with(inherited_project_user)
      share_modal.expect_not_shared_with(non_project_user)
      share_modal.expect_not_shared_with(shared_project_group)
      share_modal.expect_not_shared_with(shared_non_project_group)

      # Clicking again on the filter will reset it
      share_modal.filter("role", I18n.t("work_package.permissions.comment"))
      share_modal.expect_shared_count_of(6)

      share_modal.expect_shared_with(project_user, "View")
      share_modal.expect_shared_with(project_user2, "Comment")
      share_modal.expect_shared_with(inherited_project_user, "Edit")
      share_modal.expect_shared_with(non_project_user, "Edit")
      share_modal.expect_shared_with(shared_project_group, "Edit")
      share_modal.expect_shared_with(shared_non_project_group, "View")
    end

    it "allows to filter for role and type at the same time" do
      share_modal.expect_open
      share_modal.expect_shared_count_of(6)

      # Filter for: all principals with View permission
      # role: view
      # type: none
      share_modal.filter("role", I18n.t("work_package.permissions.view"))
      share_modal.expect_shared_count_of(2)

      share_modal.expect_shared_with(project_user, "View")
      share_modal.expect_shared_with(shared_non_project_group, "View")
      share_modal.expect_not_shared_with(project_user2)
      share_modal.expect_not_shared_with(inherited_project_user)
      share_modal.expect_not_shared_with(non_project_user)
      share_modal.expect_not_shared_with(shared_project_group)

      # Additional filter for: project members (users only)
      # role: view
      # type: project members (users only)
      share_modal.filter("type", I18n.t("sharing.filter.project_member"))
      share_modal.expect_shared_count_of(1)

      share_modal.expect_shared_with(project_user, "View")
      share_modal.expect_not_shared_with(project_user2)
      share_modal.expect_not_shared_with(inherited_project_user)
      share_modal.expect_not_shared_with(non_project_user)
      share_modal.expect_not_shared_with(shared_project_group)
      share_modal.expect_not_shared_with(shared_non_project_group)

      # Change type filter to: project members (groups only)
      # role: view
      # type: non-project members (groups only)
      share_modal.filter("type", I18n.t("sharing.filter.not_project_group"))
      share_modal.expect_shared_count_of(1)

      share_modal.expect_shared_with(shared_non_project_group, "View")
      share_modal.expect_not_shared_with(project_user)
      share_modal.expect_not_shared_with(project_user2)
      share_modal.expect_not_shared_with(inherited_project_user)
      share_modal.expect_not_shared_with(non_project_user)
      share_modal.expect_not_shared_with(shared_project_group)

      # Reset role filter
      # role: none
      # type: non-project members (groups only)
      share_modal.filter("role", I18n.t("work_package.permissions.view"))
      share_modal.expect_shared_count_of(1)

      share_modal.expect_shared_with(shared_non_project_group, "View")
      share_modal.expect_not_shared_with(project_user)
      share_modal.expect_not_shared_with(project_user2)
      share_modal.expect_not_shared_with(inherited_project_user)
      share_modal.expect_not_shared_with(non_project_user)
      share_modal.expect_not_shared_with(shared_project_group)

      # Reset type filter
      # role: none
      # type: none
      share_modal.filter("type", I18n.t("sharing.filter.not_project_group"))
      share_modal.expect_shared_count_of(6)

      share_modal.expect_shared_with(project_user, "View")
      share_modal.expect_shared_with(project_user2, "Comment")
      share_modal.expect_shared_with(inherited_project_user, "Edit")
      share_modal.expect_shared_with(non_project_user, "Edit")
      share_modal.expect_shared_with(shared_project_group, "Edit")
      share_modal.expect_shared_with(shared_non_project_group, "View")
    end

    context "and there are no matching results for my filter" do
      it 'does not check the "toggle all" checkbox' do
        share_modal.expect_open
        share_modal.filter("type", I18n.t("sharing.filter.not_project_member"))
        share_modal.filter("role", I18n.t("work_package.permissions.view"))

        share_modal.expect_empty_search_blankslate
        share_modal.expect_shared_count_of(0)
        share_modal.expect_select_all_untoggled
      end
    end

    it "only displays shares that match the current set of applied filters" do
      share_modal.expect_open

      share_modal.toggle_select_all
      share_modal.bulk_update("View")
      share_modal.toggle_select_all

      share_modal.filter("role", "View")

      share_modal.expect_shared_with(project_user)
      share_modal.expect_shared_with(project_user2)
      share_modal.expect_shared_with(inherited_project_user)
      share_modal.expect_shared_with(non_project_user)
      share_modal.expect_shared_with(shared_project_group)
      share_modal.expect_shared_with(shared_non_project_group)

      share_modal.change_role(project_user, "Comment")
      share_modal.filter("role", "Comment")
      share_modal.expect_shared_with(project_user, "Comment")
      share_modal.expect_not_shared_with(project_user2)
      share_modal.expect_not_shared_with(inherited_project_user)
      share_modal.expect_not_shared_with(non_project_user)
      share_modal.expect_not_shared_with(shared_project_group)
      share_modal.expect_not_shared_with(shared_non_project_group)

      share_modal.filter("role", "Edit")
      share_modal.expect_empty_search_blankslate
    end

    context "when filtering for a specific role" do
      before do
        share_modal.expect_open
        share_modal.filter("role", "View")
      end

      context "and a share from the filtered list is subsequently updated" do
        before do
          share_modal.change_role(project_user, "Comment")
        end

        it "removes the updated share from the list" do
          share_modal.expect_not_shared_with(project_user)
        end
      end
    end
  end
end

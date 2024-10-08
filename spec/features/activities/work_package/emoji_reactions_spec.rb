#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe "Emoji reactions on work package activity", :js, :with_cuprite,
               with_flag: { primerized_work_package_activities: true } do
  let(:project) { create(:project) }
  let(:admin) { create(:admin) }
  let(:member) { create_user_as_project_member }
  let(:viewer) { create_user_with_view_work_packages_permission }
  let(:viewer_with_commenting_permission) { create_user_with_view_and_commenting_permission }

  let(:first_comment) do
    create(:work_package_journal, user: admin, notes: "First comment by admin", journable: work_package,
                                  version: 2)
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:activity_tab) { Components::WorkPackages::EmojiReactions.new(work_package) }

  context "when user is the work package author" do
    current_user { member }

    let(:work_package) do
      create(:work_package, project:, author: member, subject: "Test work package")
    end

    before do
      first_comment

      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "can add an emoji reactions" do
      activity_tab.can_add_emoji_reaction_for_journal(first_comment, "👍")
    end
  end

  context "when user only has `view_work_packages` permissions"
  context "when a user has `add_work_package_notes` and `edit_own_work_package_notes` permission"
  context "with anonymouse user"

  def create_user_as_project_member
    member_role = create(:project_role,
                         permissions: %i[view_work_packages edit_work_packages add_work_packages work_package_assigned
                                         add_work_package_notes])
    create(:user, firstname: "A", lastname: "Member",
                  member_with_roles: { project => member_role })
  end

  def create_user_with_view_work_packages_permission
    viewer_role = create(:project_role, permissions: %i[view_work_packages])
    create(:user,
           firstname: "A",
           lastname: "Viewer",
           member_with_roles: { project => viewer_role })
  end

  def create_user_with_view_and_commenting_permission
    viewer_role_with_commenting_permission = create(:project_role,
                                                    permissions: %i[view_work_packages add_work_package_notes
                                                                    edit_own_work_package_notes])
    create(:user,
           firstname: "A",
           lastname: "Viewer",
           member_with_roles: { project => viewer_role_with_commenting_permission })
  end
end

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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Work package filtering by assignee's role", :js, :with_cuprite do
  shared_let(:project) { create(:project) }

  shared_let(:manager_role) { create(:project_role, permissions: %i[view_members view_work_packages save_queries]) }
  shared_let(:invisible_project_role) { create(:project_role, permissions: %i[view_work_packages]) }
  shared_let(:project_role) { create(:project_role, permissions: %i[view_work_packages work_package_assigned]) }
  shared_let(:visible_work_package_role) { create(:work_package_role, permissions: %i[view_work_packages work_package_assigned]) }
  shared_let(:invisible_work_package_role) { create(:work_package_role, permissions: %i[view_work_packages]) }

  shared_let(:builtin_roles) { [create(:non_member), create(:anonymous_role)] }
  shared_let(:non_assignable_roles) { [invisible_project_role, invisible_work_package_role] }
  shared_let(:assignable_roles) { [project_role, visible_work_package_role] }

  shared_let(:other_user) do
    create(:user,
           firstname: "Other",
           lastname: "User",
           member_with_roles: { project => project_role, work_package_user_assignee => visible_work_package_role })
  end

  shared_let(:work_package_user_assignee) do
    create(:work_package,
           project:,
           assigned_to: other_user)
  end
  shared_let(:work_package_user_not_assignee) do
    create(:work_package,
           project:,
           assigned_to: current_user)
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:filters) { Components::WorkPackages::Filters.new }

  shared_current_user do
    create(:user, member_with_roles: { project => manager_role })
  end

  it "shows the work package matching the assignee's role to filter" do
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package_user_assignee, work_package_user_not_assignee)

    filters.open
    # It does not show builtin roles such as Anonymous and NonMember or roles that don't allow the user to become an assignee
    filters.expect_missing_filter_value_by("Assignee's role",
                                           "is (OR)",
                                           (builtin_roles + non_assignable_roles),
                                           "assignedToRole")

    filters.add_filter_by("Assignee's role", "is (OR)", assignable_roles, "assignedToRole")

    filters.expect_filter_count("2")

    wp_table.expect_work_package_listed(work_package_user_assignee)
    wp_table.ensure_work_package_not_listed!(work_package_user_not_assignee)

    # TODO: Remove
    # If that sleep is not here, the test fails because the 2nd role is not added
    # to the filter. If we sleep it is correctly saved. I really don't know why this is happening.
    # The screenshot shows that the role is selected but it does not really get persisted correctly

    sleep 1

    wp_table.save_as("Subject query", by_title: true)
    wp_table.expect_and_dismiss_toaster(message: "Successful creation.")

    # Revisit query
    wp_table.visit_query Query.last
    wp_table.expect_work_package_listed(work_package_user_assignee)
    wp_table.ensure_work_package_not_listed!(work_package_user_not_assignee)

    filters.open
    # Do not show the already selected roles in the autocomplete dropdown
    filters.expect_missing_autocomplete_value("assignedToRole", assignable_roles)

    # Ensure that all assigned roles are shown in the filter
    filters.expect_filter_by("Assignee's role", "is (OR)", assignable_roles, "assignedToRole")
  end
end

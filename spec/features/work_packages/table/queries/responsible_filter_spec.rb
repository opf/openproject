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

RSpec.describe "Work package filtering by responsible", :js do
  let(:project) { create(:project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:filters) { Components::WorkPackages::Filters.new }
  let(:role) { create(:project_role, permissions: %i[view_work_packages save_queries]) }
  let(:other_user) do
    create(:user,
           firstname: "Other",
           lastname: "User",
           member_with_roles: { project => role })
  end
  let(:placeholder_user) do
    create(:placeholder_user,
           member_with_roles: { project => role })
  end

  let!(:work_package_user_responsible) do
    create(:work_package,
           project:,
           responsible: other_user)
  end
  let!(:work_package_placeholder_user_responsible) do
    create(:work_package,
           project:,
           responsible: placeholder_user)
  end

  current_user do
    create(:user, member_with_roles: { project => role })
  end

  it "shows the work package matching the responsible filter" do
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package_user_responsible, work_package_placeholder_user_responsible)

    filters.open
    filters.add_filter_by("Accountable", "is (OR)", [other_user.name], "responsible")

    wp_table.ensure_work_package_not_listed!(work_package_placeholder_user_responsible)
    wp_table.expect_work_package_listed(work_package_user_responsible)

    wp_table.save_as("Responsible query")

    wp_table.expect_and_dismiss_toaster(message: "Successful creation.")

    # Revisit query
    wp_table.visit_query Query.last
    wp_table.ensure_work_package_not_listed!(work_package_placeholder_user_responsible)
    wp_table.expect_work_package_listed(work_package_user_responsible)

    filters.open
    filters.expect_filter_by("Accountable", "is (OR)", [other_user.name], "responsible")
    filters.remove_filter "responsible"
    filters.add_filter_by("Accountable", "is (OR)", [placeholder_user.name], "responsible")

    wp_table.ensure_work_package_not_listed!(work_package_user_responsible)
    wp_table.expect_work_package_listed(work_package_placeholder_user_responsible)
  end
end

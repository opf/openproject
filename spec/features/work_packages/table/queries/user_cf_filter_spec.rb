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

RSpec.describe "Work package filtering by user custom field", :js do
  let(:project) { create(:project) }
  let(:type) { project.types.first }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:filters) { Components::WorkPackages::Filters.new }
  let!(:user_cf) do
    create(:user_wp_custom_field).tap do |cf|
      type.custom_fields << cf
      project.work_package_custom_fields << cf
    end
  end
  let(:role) { create(:project_role, permissions: %i[view_work_packages save_queries]) }
  let!(:other_user) do
    create(:user,
           firstname: "Other",
           lastname: "User",
           member_with_roles: { project => role })
  end
  let!(:placeholder_user) do
    create(:placeholder_user,
           member_with_roles: { project => role })
  end
  let!(:group) do
    create(:group,
           member_with_roles: { project => role })
  end

  let!(:work_package_user) do
    create(:work_package,
           type:,
           project:).tap do |wp|
      wp.custom_field_values = { user_cf.id => other_user }
      wp.save!
    end
  end
  let!(:work_package_placeholder) do
    create(:work_package,
           type:,
           project:).tap do |wp|
      wp.custom_field_values = { user_cf.id => placeholder_user }
      wp.save!
    end
  end
  let!(:work_package_group) do
    create(:work_package,
           type:,
           project:).tap do |wp|
      wp.custom_field_values = { user_cf.id => group }
      wp.save!
    end
  end

  current_user do
    create(:user, member_with_roles: { project => role })
  end

  it "shows the work package matching the user cf filter" do
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package_user, work_package_placeholder, work_package_group)

    filters.open

    # Filtering by user

    filters.add_filter_by(user_cf.name, "is (OR)", [other_user.name], user_cf.attribute_name(:camel_case))

    wp_table.ensure_work_package_not_listed!(work_package_placeholder, work_package_group)
    wp_table.expect_work_package_listed(work_package_user)

    wp_table.save_as("Saved query")

    wp_table.expect_and_dismiss_toaster(message: "Successful creation.")

    # Revisit query
    wp_table.visit_query Query.last
    wp_table.ensure_work_package_not_listed!(work_package_placeholder, work_package_group)
    wp_table.expect_work_package_listed(work_package_user)

    filters.open
    filters.expect_filter_by(user_cf.name, "is (OR)", [other_user.name], "customField#{user_cf.id}")

    # Filtering by placeholder

    filters.remove_filter user_cf.attribute_name(:camel_case)
    filters.add_filter_by(user_cf.name, "is (OR)", [placeholder_user.name], user_cf.attribute_name(:camel_case))

    wp_table.ensure_work_package_not_listed!(work_package_user, work_package_group)
    wp_table.expect_work_package_listed(work_package_placeholder)

    # Filtering by group

    filters.remove_filter user_cf.attribute_name(:camel_case)
    filters.add_filter_by(user_cf.name, "is (OR)", [group.name], user_cf.attribute_name(:camel_case))

    wp_table.ensure_work_package_not_listed!(work_package_user, work_package_placeholder)
    wp_table.expect_work_package_listed(work_package_group)
  end
end

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

RSpec.describe "Work package filtering",
               "by shared with user",
               :js,
               :with_cuprite do
  shared_let(:visible_project) do
    create(:project_with_types)
  end
  shared_let(:invisible_project) do
    create(:project_with_types)
  end

  shared_let(:project_role_with_sufficient_permissions) do
    create(:project_role,
           permissions: %i[view_work_packages
                           save_queries
                           share_work_packages
                           view_shared_work_packages])
  end
  shared_let(:project_role_with_insufficient_permissions) do
    create(:project_role, permissions: %i[view_work_packages
                                          save_queries])
  end
  shared_let(:work_package_role) do
    create(:work_package_role, permissions: %i[view_work_packages])
  end

  shared_let(:user_with_sufficient_permissions) do
    create(:user,
           firstname: "Bruce",
           lastname: "Wayne",
           member_with_roles: { visible_project => project_role_with_sufficient_permissions })
  end
  shared_let(:user_with_insufficient_permissions) do
    create(:user,
           firstname: "Alfred",
           lastname: "Pennyworth",
           member_with_roles: { visible_project => project_role_with_insufficient_permissions })
  end
  shared_let(:user_with_shared_work_package) do
    create(:user,
           firstname: "Clark",
           lastname: "Kent",
           member_with_roles: { visible_project => project_role_with_insufficient_permissions })
  end
  shared_let(:invisible_user) do
    create(:user,
           firstname: "Salvatore",
           lastname: "Maroni",
           member_with_roles: { invisible_project => project_role_with_insufficient_permissions })
  end

  shared_let(:shared_work_package) do
    create(:work_package,
           project: visible_project) do |wp|
      create(:member,
             project: visible_project,
             user: user_with_shared_work_package,
             entity: wp,
             roles: [work_package_role])
    end
  end
  shared_let(:non_shared_work_package) do
    create(:work_package,
           project: visible_project)
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(visible_project) }
  let(:filters) { Components::WorkPackages::Filters.new }

  context 'when I have sufficient permissions for the "Shared with user" filter' do
    current_user { user_with_sufficient_permissions }

    it "filters work packages by their shared status" do
      wp_table.visit!
      wp_table.expect_work_package_listed(shared_work_package, non_shared_work_package)
      filters.open

      aggregate_failures "Members of a Project I'm not a member of are invisible" do
        filters.expect_missing_filter_value_by("Shared with user",
                                               "is (OR)",
                                               [invisible_user.name],
                                               "sharedWithUser")
      end

      aggregate_failures "operator filtering" do
        filters.add_filter_by("Shared with user",
                              "is (OR)",
                              [user_with_shared_work_package.name],
                              "sharedWithUser")

        wp_table.ensure_work_package_not_listed!(non_shared_work_package)
        wp_table.expect_work_package_listed(shared_work_package)
      end

      aggregate_failures "Filters persist on saved query" do
        wp_table.save_as("Non shared work packages")

        wp_table.expect_and_dismiss_toaster(message: "Successful creation.")

        wp_table.visit_query Query.last
        wp_table.ensure_work_package_not_listed!(non_shared_work_package)
        wp_table.expect_work_package_listed(shared_work_package)
      end
    end
  end

  context 'when I lack the sufficient permissions for the "Shared with user" filter' do
    current_user { user_with_insufficient_permissions }

    it 'does not show the "Shared with user" filter' do
      wp_table.visit!
      wp_table.expect_work_package_listed(shared_work_package, non_shared_work_package)
      filters.open
      filters.expect_missing_filter("Shared with user")
    end
  end
end

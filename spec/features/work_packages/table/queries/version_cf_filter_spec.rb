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

# This is not strictly version CF specific, but targets regression #53198.
RSpec.describe "Work package filtering by version custom field", :js do
  let!(:project) { create(:project) }
  let!(:type) { project.types.first }
  let!(:version_cf1) do
    create(
      :version_wp_custom_field,
      name: "Versions 1",
      multi_value: true,
      types: [type],
      projects: [project]
    )
  end
  let!(:version_cf2) do
    create(
      :version_wp_custom_field,
      name: "Versions 2",
      multi_value: true,
      types: [type],
      projects: [project]
    )
  end
  let!(:version_1) { create(:version, project:, name: "Version 1") }
  let!(:version_2) { create(:version, project:, name: "Version 2") }

  let(:role) { create(:project_role, permissions: %i[view_work_packages save_queries]) }

  let!(:work_package_1_1) do
    create(:work_package,
           type:,
           project:,
           subject: "WP 1->1").tap do |wp|
      wp.custom_field_values = { version_cf1.id => [version_1.id.to_s] }
      wp.save!
    end
  end
  let!(:work_package_2_1) do
    create(:work_package,
           type:,
           project:,
           subject: "WP 2->1").tap do |wp|
      wp.custom_field_values = { version_cf2.id => [version_1.id.to_s] }
      wp.save!
    end
  end
  let!(:work_package_mix) do
    create(:work_package,
           type:,
           project:,
           subject: "WP 1->1, 2->2").tap do |wp|
      wp.custom_field_values = {
        version_cf1.id => [version_1.id.to_s],
        version_cf2.id => [version_2.id.to_s]
      }
      wp.save!
    end
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:filters) { Components::WorkPackages::Filters.new }

  current_user do
    create(:user, member_with_roles: { project => role })
  end

  it 'shows the work package matching the version CF "is (AND)" filter' do
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package_1_1, work_package_2_1, work_package_mix)

    filters.open

    # Filtering by cf1 "is (AND)"

    filters.add_filter_by(version_cf1.name, "is (AND)", [version_1.name], version_cf1.attribute_name(:camel_case))

    wp_table.expect_work_package_listed(work_package_1_1, work_package_mix)
    wp_table.ensure_work_package_not_listed!(work_package_2_1)

    # Filtering by multiple cf1 values (nothing matches)
    filters.remove_filter version_cf1.attribute_name(:camel_case)
    filters.add_filter_by(version_cf1.name, "is (AND)", [version_1.name, version_2.name], version_cf1.attribute_name(:camel_case))

    wp_table.ensure_work_package_not_listed!(work_package_2_1, work_package_1_1, work_package_mix)
  end

  it 'shows the work package matching the version CF "is not" filter' do
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package_1_1, work_package_2_1, work_package_mix)

    filters.open

    # Filtering by cf1 "is not"
    filters.add_filter_by(version_cf2.name, "is not", [version_1.name], version_cf2.attribute_name(:camel_case))

    wp_table.expect_work_package_listed(work_package_mix, work_package_1_1)
    wp_table.ensure_work_package_not_listed!(work_package_2_1)
  end
end

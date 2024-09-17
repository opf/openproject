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

RSpec.describe "Work package filtering by bool custom field", :js do
  let(:project) { create(:project) }
  let(:type) { project.types.first }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:filters) { Components::WorkPackages::Filters.new }
  let!(:bool_cf) do
    create(:boolean_wp_custom_field) do |cf|
      type.custom_fields << cf
      project.work_package_custom_fields << cf
    end
  end
  let(:role) { create(:project_role, permissions: %i[view_work_packages save_queries]) }
  let!(:work_package_true) do
    create(:work_package,
           type:,
           project:) do |wp|
      wp.custom_field_values = { bool_cf.id => true }
      wp.save!
    end
  end
  let!(:work_package_false) do
    create(:work_package,
           type:,
           project:) do |wp|
      wp.custom_field_values = { bool_cf.id => false }
      wp.save!
    end
  end
  let!(:work_package_without) do
    # Has no custom field value set
    create(:work_package,
           type:,
           project:)
  end
  let!(:work_package_other_type) do
    # Does not have the custom field at all
    create(:work_package,
           type: project.types.last,
           project:)
  end

  current_user do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages save_queries] })
  end

  it "shows the work package matching the bool cf filter" do
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package_true, work_package_false, work_package_without, work_package_other_type)

    filters.open

    # Add filtering by bool custom field which defaults to false
    filters.add_filter(bool_cf.name)

    wp_table.ensure_work_package_not_listed!(work_package_false, work_package_without, work_package_other_type)
    wp_table.expect_work_package_listed(work_package_true)

    wp_table.save_as("Saved query")

    wp_table.expect_and_dismiss_toaster(message: "Successful creation.")

    # Revisit query
    wp_table.visit_query Query.last
    wp_table.ensure_work_package_not_listed!(work_package_false, work_package_without, work_package_other_type)
    wp_table.expect_work_package_listed(work_package_true)

    filters.open

    # Inverting the filter
    page.find("#div-values-customField#{bool_cf.id} #{test_selector('spot-switch-handle')}").click

    wp_table.ensure_work_package_not_listed!(work_package_true)
    wp_table.expect_work_package_listed(work_package_false, work_package_without, work_package_other_type)
  end
end

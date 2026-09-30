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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Work Package group by boolean field", :js do
  let(:user) { create(:admin) }

  let(:project) { create(:project, types: [type], work_package_custom_fields: [bool_cf]) }
  let(:bool_cf) { create(:boolean_wp_custom_field, name: "booleanField", types: [type]) }
  let(:type) { create(:type) }

  let!(:wp1) { create(:work_package, project:, type:) }
  let!(:wp2) { create(:work_package, project:, type:, custom_field_values: { bool_cf.id => true }) }
  let!(:wp3) { create(:work_package, project:, type:, custom_field_values: { bool_cf.id => false }) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:group_by) { Components::WorkPackages::GroupBy.new }

  before do
    login_as(user)
    wp_table.visit!
    wp_table.expect_work_package_listed wp1, wp2, wp3
  end

  it "shows group headers for groups by bool cf (regression test #34904)" do
    # Group by category
    group_by.enable_via_menu "booleanField"
    loading_indicator_saveguard

    # Expect table to be grouped
    group_by.expect_number_of_groups 3
    group_by.expect_grouped_by_value "-", 1
    group_by.expect_grouped_by_value "true", 1
    group_by.expect_grouped_by_value "false", 1
  end
end

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

require 'spec_helper'

# This spec deals exclusively with a user custom field in
# the _global_ Work Packages list.
# There are several possible issues here:
# - Custom fields to appear here have to have the "is_for_all"
#   flag set (or not?).
# - The value range for the field should be the global list of
#   users. But what about the permission of the current_user to
#   see other users? The result is not defined yet, so there is
#   no test here (yet).
# - Performance could be an issue with thousands of users
#   potentially.
describe 'Work package filtering by user custom field', js: true do
  let(:wp_table_global) { ::Pages::WorkPackagesTable.new }
  let(:filters) { ::Components::WorkPackages::Filters.new }
  let!(:user_cf_single_project) { create(:user_wp_custom_field, is_for_all: false, name: "Single Project CF") }
  let!(:user_cf_all_projects) { create(:user_wp_custom_field, is_for_all: true, name: "All Projects CF") }

  current_user do
    create :admin
  end

  it 'appears on the global work package page if is_for_all is set' do
    wp_table_global.visit!
    filters.open

    # Check for presence by adding the filter.
    # add_filter_by seems to wait for the XHR call with filter options,
    # while expect_available_filters doesn't.
    filters.add_filter_by(user_cf_all_projects.name, 'is', [current_user.name], "customField#{user_cf_all_projects.id}")

    # Check that the project specific filter is not available in the filter list
    filters.expect_available_filter(user_cf_single_project.name, present: false)
  end
end

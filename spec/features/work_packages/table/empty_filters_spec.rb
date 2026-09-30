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

RSpec.describe "Empty query filters", :js do
  let(:user) { create(:admin) }
  let(:work_package) { create(:work_package) }
  let(:wp_table) { Pages::WorkPackagesTable.new }
  let(:filters) { Components::WorkPackages::Filters.new }

  before do
    login_as(user)
    work_package
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package)
  end

  # Tests for regression #23739
  it "allows to delete the last query filter" do
    # Open filter menu
    filters.expect_filter_count(1)
    filters.open

    # Remove only filter
    filters.remove_filter(:status)

    wp_table.expect_work_package_listed(work_package)

    wp_table.expect_no_toaster(type: :error)
    filters.expect_filter_count(0)
  end
end

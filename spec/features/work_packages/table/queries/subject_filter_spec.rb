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

RSpec.describe "Work package filtering by subject", :js do
  let(:project) { create(:project, public: true) }
  let(:admin) { create(:admin) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:filters) { Components::WorkPackages::Filters.new }

  let!(:wp_match) { create(:work_package, project:, subject: "R#1234 Foobar") }
  let!(:wp_nomatch) { create(:work_package, project:, subject: "R!1234 Foobar") }

  before do
    login_as admin
  end

  it "shows the one work package filtering for myself" do
    wp_table.visit!
    wp_table.expect_work_package_listed(wp_match, wp_nomatch)

    # Add and save query with me filter
    filters.open
    filters.remove_filter "status"
    filters.add_filter_by("Subject", "contains", ["R#"])

    wp_table.ensure_work_package_not_listed!(wp_nomatch)
    wp_table.expect_work_package_listed(wp_match)

    wp_table.save_as("Subject query")
    loading_indicator_saveguard

    # Expect correct while saving
    wp_table.expect_title "Subject query"
    query = Query.last
    expect(query.filters.first.values).to eq ["R#"]
    filters.expect_filter_by("Subject", "contains", ["R#"])

    # Revisit query
    wp_table.visit_query query
    wp_table.ensure_work_package_not_listed!(wp_nomatch)
    wp_table.expect_work_package_listed(wp_match)

    filters.open
    filters.expect_filter_by("Subject", "contains", ["R#"])
  end
end

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

RSpec.describe "Work Package table configuration modal", :js do
  let(:user) { create(:admin) }

  let(:project) { create(:project) }
  let!(:wp_1) { create(:work_package, project:) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:modal) { Components::WorkPackages::TableConfigurationModal.new }

  let!(:query) do
    query              = build(:query, user:, project:)
    query.column_names = ["subject", "done_ratio"]

    query.save!
    query
  end

  before do
    login_as(user)

    wp_table.visit!
    wp_table.expect_work_package_listed wp_1
  end

  it "focuses on the columns tab when opened through header" do
    # Open header dropdown
    find(".work-package-table--container th #subject").click

    # Open insert columns entry
    find("#column-context-menu .menu-item", text: "Insert columns").click

    # Expect active tab is columns
    expect(page).to have_css(".op-tab-row--link_selected", text: "COLUMNS")
  end
end

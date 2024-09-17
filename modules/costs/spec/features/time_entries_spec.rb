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

require_relative "../spec_helper"

RSpec.describe "Work Package table cost entries", :js do
  shared_let(:project) { create(:project_with_types) }
  shared_let(:user) { create(:admin) }

  shared_let(:parent) { create(:work_package, project:) }
  shared_let(:work_package) { create(:work_package, project:, parent:) }
  shared_let(:hourly_rate) { create(:default_hourly_rate, user:, rate: 1.00) }

  let!(:time_entry1) do
    create(:time_entry,
           user:,
           work_package: parent,
           project:,
           hours: 10)
  end

  let!(:time_entry2) do
    create(:time_entry,
           user:,
           work_package:,
           project:,
           hours: 2.50)
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:query) do
    query = build(:query, user:, project:)
    query.column_names = %w(id subject spent_hours)

    query.save!
    query
  end

  before do
    login_as(user)
  end

  it "shows the correct sum of the time entries" do
    wp_table.visit_query(query)
    wp_table.expect_work_package_listed(parent)
    wp_table.expect_work_package_listed(work_package)

    parent_row = wp_table.row(parent)
    wp_row = wp_table.row(work_package)

    expect(parent_row).to have_css(".inline-edit--container.spentTime", text: "12.5h")
    expect(wp_row).to have_css(".inline-edit--container.spentTime", text: "2.5h")
  end

  it "creates an activity" do
    visit project_activities_path project

    # Activate the spent time filter
    check("Spent time")
    click_on "Apply"

    wp1 = time_entry1.work_package
    wp2 = time_entry2.work_package
    expect(page).to have_css(".op-activity-list--item-title", text: "#{wp1.type.name} ##{wp1.id}: #{wp1.subject}")
    expect(page).to have_css(".op-activity-list--item-title", text: "#{wp2.type.name} ##{wp2.id}: #{wp2.subject}")
  end
end

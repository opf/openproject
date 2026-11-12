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

RSpec.describe "Duration field in the work package table", :js do
  shared_let(:current_user) { create(:admin) }
  shared_let(:work_package) do
    next_monday = Time.zone.today.beginning_of_week.next_occurring(:monday)
    create(:work_package,
           subject: "moved",
           author: current_user,
           start_date: next_monday,
           due_date: next_monday.next_occurring(:thursday))
  end

  let!(:wp_table) { Pages::WorkPackagesTable.new(work_package.project) }
  let!(:query) do
    query              = build(:query, user: current_user, project: work_package.project)
    query.column_names = %w(subject start_date due_date duration)
    query.filters.clear
    query.show_hierarchies = false

    query.save!
    query
  end

  let(:duration) { wp_table.edit_field work_package, :duration }
  let(:date_field) { wp_table.edit_field work_package, :startDate }

  before do
    login_as(current_user)

    wp_table.visit_query query
    wp_table.expect_work_package_listed work_package
  end

  it "shows the duration as days and opens the datepicker on click" do
    duration.expect_state_text "4 days"
    duration.activate!
    wait_for_network_idle

    date_field.expect_duration_highlighted
    expect(page).to have_field("work_package[duration]", with: "4", wait: 10)
  end
end

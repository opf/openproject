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
require_relative "shared_context"

RSpec.describe "Team planner split view navigation", :js, with_ee: %i[team_planner_view] do
  include_context "with team planner full access"

  let!(:view) { create(:view_team_planner, query:) }
  let!(:query) { create(:query, user:, project:, public: true) }

  let(:start_of_week) { Time.zone.today.beginning_of_week(:sunday) }

  let!(:work_package1) do
    create(:work_package,
           project:,
           subject: "First task",
           assigned_to: user,
           start_date: start_of_week.next_occurring(:tuesday),
           due_date: start_of_week.next_occurring(:thursday))
  end

  let!(:work_package2) do
    create(:work_package,
           project:,
           subject: "Another task",
           assigned_to: user,
           start_date: start_of_week.next_occurring(:tuesday),
           due_date: start_of_week.next_occurring(:thursday))
  end

  it "allows to navigate to the split view" do
    team_planner.visit!

    team_planner.add_assignee user
    team_planner.within_lane(user) do
      team_planner.expect_event work_package1
      team_planner.expect_event work_package2
    end

    # Expect clicking on a work package does not open the details
    page.find_test_selector("op-wp-single-card--content-subject", text: work_package1.subject).click
    expect(page).to have_no_current_path /team_planners\/new\/details\/#{work_package1.id}/

    # Open split view through info icon
    split_view = team_planner.open_split_view_by_info_icon work_package1
    expect(page).to have_current_path /team_planners\/new\/details\/#{work_package1.id}/

    card1 = Pages::WorkPackageCard.new work_package1
    card1.expect_selected

    # now clicking on another card switches
    page.find_test_selector("op-wp-single-card--content-subject", text: work_package2.subject).click
    expect(page).to have_current_path /team_planners\/new\/details\/#{work_package2.id}/

    card2 = Pages::WorkPackageCard.new work_package2
    card2.expect_selected
    card1.expect_selected selected: false

    # Close the split view again
    split_view.close
    split_view.expect_closed

    # Expect no card selected
    card2.expect_selected selected: false
    card1.expect_selected selected: false
  end
end

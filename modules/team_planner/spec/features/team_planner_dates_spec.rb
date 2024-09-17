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

RSpec.describe "Team planner working days", :js,
               with_ee: %i[team_planner_view],
               with_settings: { start_of_week: 1 } do
  include_context "with team planner full access"

  context "with week days defined" do
    let!(:week_days) { week_with_saturday_and_sunday_as_weekend }

    it 'hides sat and sun in the "Work week" view andd renders sat and sun as non working in the "1-week" view' do
      team_planner.visit!

      team_planner.expect_empty_state
      team_planner.add_assignee user.name

      # Initially, in the "Work week" view, non working days are hidden
      expect(page).to have_css(".fc-day-mon")
      expect(page).to have_css(".fc-day-tue")
      expect(page).to have_css(".fc-day-wed")
      expect(page).to have_css(".fc-day-thu")
      expect(page).to have_css(".fc-day-fri")

      expect(page).to have_no_css(".fc-day-sat")
      expect(page).to have_no_css(".fc-day-sun")

      # In the "1-week" view, non working days are displayed but marked
      team_planner.switch_view_mode "1-week"

      expect(page).to have_css(".fc-day-sat.fc-non-working-day", minimum: 1, wait: 10)
      expect(page).to have_css(".fc-day-sun.fc-non-working-day", minimum: 1)

      expect(page).to have_no_css(".fc-day-mon.fc-non-working-day")
      expect(page).to have_no_css(".fc-day-tue.fc-non-working-day")
      expect(page).to have_no_css(".fc-day-wed.fc-non-working-day")
      expect(page).to have_no_css(".fc-day-thu.fc-non-working-day")
      expect(page).to have_no_css(".fc-day-fri.fc-non-working-day")

      find(".fc-next-button").click

      expect(page).to have_css(".fc-day-sat.fc-non-working-day", minimum: 1, wait: 10)
      expect(page).to have_css(".fc-day-sun.fc-non-working-day", minimum: 1)

      expect(page).to have_no_css(".fc-day-mon.fc-non-working-day")
      expect(page).to have_no_css(".fc-day-tue.fc-non-working-day")
      expect(page).to have_no_css(".fc-day-wed.fc-non-working-day")
      expect(page).to have_no_css(".fc-day-thu.fc-non-working-day")
      expect(page).to have_no_css(".fc-day-fri.fc-non-working-day")
    end
  end
end

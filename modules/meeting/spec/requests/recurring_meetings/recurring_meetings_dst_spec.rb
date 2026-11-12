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
require_relative "../../support/pages/recurring_meeting/show"

RSpec.describe "Recurring meetings show DST",
               :skip_csrf,
               freeze_time: DateTime.parse("2025-03-04T9:00:00Z"),
               type: :rails_request do
  include Redmine::I18n

  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:berlin_user) do
    create(:user,
           preferences: { time_zone: "Europe/Berlin" },
           member_with_permissions: { project => %i[view_meetings] })
  end
  shared_let(:tokyo_user) do
    create(:user,
           preferences: { time_zone: "Asia/Tokyo" },
           member_with_permissions: { project => %i[view_meetings] })
  end

  shared_let(:recurring_meeting) do
    create :recurring_meeting,
           project:,
           author: berlin_user,
           time_zone: "Europe/Berlin",
           start_time: DateTime.iso8601("2025-03-05T10:00:00+01:00"),
           frequency: "weekly",
           end_after: "iterations",
           iterations: 10
  end

  let(:current_user) { user }
  let(:request) { get project_recurring_meeting_path(project, recurring_meeting) }
  let(:show_page) { Pages::RecurringMeeting::Show.new(recurring_meeting) }

  before do
    login_as(current_user)
  end

  context "with berlin user and DST approaching" do
    let(:current_user) { berlin_user }

    it "shows a stable 10AM schedule time" do
      request

      timezone = friendly_timezone_name(berlin_user.time_zone)
      expect(page).to have_text "Every week on Wednesday at 10:00 AM (#{timezone}), ends on 05/07/2025"
      expect(page).to have_text "March 5, 2025 10:00"
      expect(page).to have_text "March 12, 2025 10:00"
      expect(page).to have_text "March 19, 2025 10:00"
      expect(page).to have_text "March 26, 2025 10:00"
      expect(page).to have_text "April 2, 2025 10:00"
    end
  end

  context "with tokyo user that doesn't have DST" do
    let(:current_user) { tokyo_user }

    it "changes times according to the CET DST, but keeps the heading" do
      request

      timezone = friendly_timezone_name(berlin_user.time_zone)
      expect(page).to have_text "Every week on Wednesday at 10:00 AM (#{timezone}), ends on 05/07/2025"
      expect(page).to have_text "March 5, 2025 18:00"
      expect(page).to have_text "March 12, 2025 18:00"
      expect(page).to have_text "March 19, 2025 18:00"
      expect(page).to have_text "March 26, 2025 18:00"
      expect(page).to have_text "April 2, 2025 17:00"
    end
  end
end

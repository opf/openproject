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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Recurring meetings creation",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) do
    create(:user,
           preferences: { time_zone: "UTC" },
           member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings] })
  end

  let(:start_date) { Date.current.next_month.beginning_of_month.to_s }
  let(:meeting_params) do
    {
      title: "Monthly series",
      location: "https://example.com/meet/monthly",
      start_date:,
      start_time_hour: "10:00",
      duration: "1.5",
      interval: "1",
      end_after: "never",
      frequency:
    }.merge(monthly_params)
  end
  let(:monthly_params) { {} }

  subject(:perform_request) do
    post project_recurring_meetings_path(project), params: { meeting: meeting_params }
  end

  before do
    login_as(user)
  end

  describe "monthly by day of month" do
    let(:frequency) { "monthly_day_of_month" }
    let(:monthly_params) { { monthly_day: "16" } }

    it "creates the recurring meeting with day-of-month settings", :aggregate_failures do
      expect { perform_request }.to change(RecurringMeeting, :count).by(1)

      recurring_meeting = RecurringMeeting.last
      expect(response).to redirect_to(project_meeting_path(project, recurring_meeting.template))
      expect(recurring_meeting.frequency).to eq("monthly_day_of_month")
      expect(recurring_meeting.monthly_day).to eq(16)
      expect(recurring_meeting.first_occurrence.day).to eq(16)
    end
  end

  describe "monthly by first weekday" do
    let(:frequency) { "monthly_nth_weekday" }
    let(:monthly_params) { { monthly_ordinal: "1", monthly_weekday: "monday" } }

    it "creates the recurring meeting with first-weekday settings", :aggregate_failures do
      expect { perform_request }.to change(RecurringMeeting, :count).by(1)

      recurring_meeting = RecurringMeeting.last
      expect(response).to redirect_to(project_meeting_path(project, recurring_meeting.template))
      expect(recurring_meeting.frequency).to eq("monthly_nth_weekday")
      expect(recurring_meeting.monthly_ordinal).to eq(1)
      expect(recurring_meeting.monthly_weekday).to eq("monday")
      expect(recurring_meeting.first_occurrence.to_date.wday).to eq(1)
      expect(recurring_meeting.first_occurrence.day).to be <= 7
    end
  end

  describe "monthly by last weekday" do
    let(:frequency) { "monthly_nth_weekday" }
    let(:monthly_params) { { monthly_ordinal: "-1", monthly_weekday: "friday" } }

    it "creates the recurring meeting with last-weekday settings", :aggregate_failures do
      expect { perform_request }.to change(RecurringMeeting, :count).by(1)

      recurring_meeting = RecurringMeeting.last
      expect(response).to redirect_to(project_meeting_path(project, recurring_meeting.template))
      expect(recurring_meeting.frequency).to eq("monthly_nth_weekday")
      expect(recurring_meeting.monthly_ordinal).to eq(-1)
      expect(recurring_meeting.monthly_weekday).to eq("friday")
      expect(recurring_meeting.first_occurrence.to_date.wday).to eq(5)
      expect((recurring_meeting.first_occurrence.to_date + 7.days).month)
        .not_to eq(recurring_meeting.first_occurrence.month)
    end
  end
end

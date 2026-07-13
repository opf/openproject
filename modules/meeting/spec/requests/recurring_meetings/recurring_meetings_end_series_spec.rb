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
require_relative "../../support/pages/recurring_meeting/show"

RSpec.describe "Recurring meetings complete template",
               :skip_csrf,
               type: :rails_request,
               with_settings: { date_format: "%Y-%m-%d" } do
  include Redmine::I18n

  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings] }) }
  shared_let(:recurring_meeting) do
    create :recurring_meeting,
           project:,
           author: user,
           start_time: DateTime.parse("2024-12-03T10:00:00Z"),
           frequency: "daily"
  end

  let(:current_user) { user }
  let(:show_page) { Pages::RecurringMeeting::Show.new(recurring_meeting).with_capybara_page(page) }
  let(:request) do
    post end_series_project_recurring_meeting_path(project, recurring_meeting)
  end

  subject do
    Timecop.freeze("2025-01-29T10:00:00Z".to_datetime) { request }
  end

  before do
    login_as(current_user)
  end

  def occurrence_count
    recurring_meeting.meetings.not_templated.count
  end

  context "when past occurrence is already created" do
    let!(:meeting) do
      create(:meeting,
             recurring_meeting:,
             start_time: recurring_meeting.start_time,
             recurrence_start_time: recurring_meeting.start_time)
    end

    it "does not delete that one" do
      expect { subject }.not_to change { occurrence_count }
      expect(response).to be_redirect

      expect(occurrence_count).to eq(1)
      expect(recurring_meeting.meetings.not_templated.first).to eq(meeting)
    end
  end

  context "when start_time < current time" do
    let!(:meeting) do
      create(:meeting,
             recurring_meeting:,
             start_time: recurring_meeting.start_time,
             recurrence_start_time: recurring_meeting.start_time)
    end

    subject do
      Timecop.freeze("2024-12-03T10:00:00Z".to_datetime) { request }
    end

    it "returns an error" do
      expect { subject }.not_to change { recurring_meeting.reload.updated_at }
      expect(response).to be_redirect
      expect(flash[:error]).to include "End date must be after 2024-12-03."
    end
  end

  context "when first occurrence is cancelled" do
    let!(:cancelled_occurrence) do
      create(:meeting,
             recurring_meeting:,
             start_time: recurring_meeting.start_time,
             recurrence_start_time: recurring_meeting.start_time,
             state: :cancelled)
    end

    it "does not delete this occurrence" do
      expect { subject }.not_to change { occurrence_count }
      expect(response).to be_redirect

      recurring_meeting.reload
      expect(recurring_meeting.end_date).to eq Date.parse("2025-01-28")

      expect(occurrence_count).to eq(1)
      expect(recurring_meeting.meetings.not_templated.first).to be_cancelled
    end
  end

  context "when todays occurrence is present, but we're later" do
    let!(:occurrence) do
      create(:meeting,
             recurring_meeting:,
             start_time: DateTime.parse("2024-12-05T10:00:00Z"),
             recurrence_start_time: DateTime.parse("2024-12-05T10:00:00Z"))
    end

    subject do
      Timecop.freeze("2024-12-05T10:01:00Z".to_datetime) { request }
    end

    it "does not delete this occurrence" do
      expect { subject }.not_to change { occurrence_count }
      expect(response).to be_redirect

      recurring_meeting.reload
      expect(recurring_meeting.end_date).to eq Date.parse("2024-12-04")
      expect(occurrence_count).to eq(1)
    end
  end

  context "when todays occurrence is present, but we're sooner" do
    let!(:occurrence) do
      create(:meeting,
             recurring_meeting:,
             start_time: DateTime.parse("2024-12-05T10:00:00Z"),
             recurrence_start_time: DateTime.parse("2024-12-05T10:00:00Z"))
    end

    subject do
      Timecop.freeze("2024-12-05T09:59:00Z".to_datetime) { request }
    end

    it "does delete this occurrence" do
      expect { subject }.to change { occurrence_count }.by(-1)
      expect(response).to be_redirect

      recurring_meeting.reload
      expect(recurring_meeting.end_date).to eq Date.parse("2024-12-04")
    end
  end

  context "when there is a scheduled instance for today and tomorrow" do
    let!(:today) do
      create(:meeting,
             recurring_meeting:,
             start_time: DateTime.parse("2024-12-05T10:00:00Z"),
             recurrence_start_time: DateTime.parse("2024-12-05T10:00:00Z"))
    end
    let!(:tomorrow) do
      create(:meeting,
             recurring_meeting:,
             start_time: DateTime.parse("2024-12-06T10:00:00Z"),
             recurrence_start_time: DateTime.parse("2024-12-06T10:00:00Z"))
    end

    subject do
      Timecop.freeze("2024-12-05T09:59:00Z".to_datetime) { request }
    end

    it "does delete both occurrences" do
      expect { subject }.to change { occurrence_count }.by(-2)
      expect(response).to be_redirect

      recurring_meeting.reload
      expect(recurring_meeting.end_date).to eq Date.parse("2024-12-04")
    end
  end

  context "when next occurrence is present" do
    let!(:occurrence) do
      create(:meeting,
             recurring_meeting:,
             start_time: DateTime.parse("2024-12-06T10:00:00Z"),
             recurrence_start_time: DateTime.parse("2024-12-06T10:00:00Z"))
    end

    subject do
      Timecop.freeze("2024-12-05T10:00:00Z".to_datetime) { request }
    end

    it "does delete this occurrence" do
      expect { subject }.to change { occurrence_count }.by(-1)
      expect(response).to be_redirect

      recurring_meeting.reload
      expect(recurring_meeting.end_date).to eq Date.parse("2024-12-04")
      expect(occurrence_count).to eq(0)
      expect { occurrence.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when user has no permissions to access" do
    let(:current_user) { create(:user) }

    it "does not authorize" do
      subject
      expect(response).to have_http_status(:forbidden)
    end
  end
end

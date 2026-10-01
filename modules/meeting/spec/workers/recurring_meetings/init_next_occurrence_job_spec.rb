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
require_module_spec_helper

RSpec.describe RecurringMeetings::InitNextOccurrenceJob, type: :model do
  shared_let(:series) do
    create(:recurring_meeting,
           start_time: Time.zone.tomorrow + 10.hours,
           frequency: "daily",
           interval: 1,
           end_after: "specific_date",
           end_date: 1.month.from_now)
  end

  let(:scheduled_time) { series.first_occurrence.to_time }
  let(:next_occurrence) { Time.zone.tomorrow + 1.day + 10.hours }

  subject { described_class.perform_now(series, scheduled_time) }

  context "when the template is still in draft mode" do
    before do
      series.template.update!(state: :draft)
    end

    it "does not schedule or instantiate occurrences" do
      result = nil

      expect { result = subject }
        .not_to change { series.meetings.not_templated.count }
      expect(result).to be_nil
      expect(described_class).not_to have_been_enqueued
    end
  end

  it "schedules the first occurrence" do
    expect { subject }.to change(Meeting, :count).by(1)
    expect(subject).to be_success

    created_meeting = subject.result
    expect(created_meeting.start_time).to eq(Time.zone.tomorrow + 10.hours)
  end

  context "when next occurrence is cancelled" do
    let!(:cancelled_occurrence) do
      create(:meeting,
             recurring_meeting: series,
             start_time: Time.zone.tomorrow + 10.hours,
             recurrence_start_time: Time.zone.tomorrow + 10.hours,
             state: :cancelled)
    end

    it "does not instantiate anything, but schedules the next job" do
      expect { subject }.not_to change(Meeting, :count)
      expect(subject).to be_nil

      expect(described_class)
        .to have_been_enqueued.with(series, next_occurrence)
                              .at(cancelled_occurrence.recurrence_start_time)
    end
  end

  context "when next occurrence is already instantiated" do
    let!(:instance) do
      create(:meeting,
             recurring_meeting: series,
             start_time: Time.zone.tomorrow + 10.hours,
             recurrence_start_time: Time.zone.tomorrow + 10.hours)
    end

    let(:next_occurrence) { Time.zone.tomorrow + 1.day + 10.hours }

    it "does not instantiate anything, but schedules the next job" do
      expect { subject }.not_to change(Meeting, :count)
      expect(subject).to be_nil

      expect(described_class)
        .to have_been_enqueued.with(series, next_occurrence)
                              .at(instance.recurrence_start_time)
    end
  end

  context "when next occurrence is already instantiated, and moved" do
    let!(:instance) do
      create(:meeting,
             recurring_meeting: series,
             start_time: Time.zone.tomorrow + 1.day + 10.hours,
             recurrence_start_time: Time.zone.tomorrow + 10.hours)
    end

    let(:next_occurrence) { Time.zone.tomorrow + 1.day + 10.hours }

    it "does not instantiate anything, but schedules the next one" do
      expect { subject }.not_to change(Meeting, :count)
      expect(subject).to be_nil
      expect(described_class)
        .to have_been_enqueued.with(series, next_occurrence)
                              .at(instance.recurrence_start_time)
    end
  end

  context "when later occurrence is already instantiated" do
    let!(:instance) do
      create(:meeting,
             recurring_meeting: series,
             start_time: Time.zone.tomorrow + 1.day + 10.hours,
             recurrence_start_time: Time.zone.tomorrow + 1.day + 10.hours)
    end

    let(:next_occurrence) { Time.zone.tomorrow + 1.day + 10.hours }

    it "schedules the one for tomorrow" do
      expect { subject }.to change(Meeting, :count).by(1)
      expect(subject).to be_success

      created_meeting = subject.result
      expect(created_meeting.start_time).to eq(Time.zone.tomorrow + 10.hours)

      expect(described_class)
        .to have_been_enqueued.with(series, next_occurrence)
                              .at(Time.zone.tomorrow + 10.hours)
    end
  end

  context "when called after end_date" do
    let(:scheduled_time) { series.end_date + 1.day }

    it "does not create a meeting nor schedule a job the next occurrence" do
      expect { subject }.not_to enqueue_job(described_class)

      expect(subject).to be_nil
    end
  end

  context "when called on last occurrence" do
    let(:scheduled_time) { series.last_occurrence }

    it "does not schedule the next occurrence" do
      expect { subject }.not_to enqueue_job(described_class)
      expect(subject).to be_success

      created_meeting = subject.result
      expect(created_meeting.start_time).to eq(scheduled_time)
    end
  end
end

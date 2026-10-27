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

RSpec.describe Sprints::Timeframe do
  subject(:timeframe) { described_class.new(sprint) }

  context "when the sprint has been started but not completed, before the planned finish" do
    let(:sprint) do
      build_stubbed(:sprint,
                    start_date: 10.days.ago.to_date,
                    finish_date: 4.days.from_now.to_date,
                    started_at: 7.days.ago)
    end

    it "starts at the actual start timestamp" do
      expect(timeframe.effective_start).to eq sprint.started_at
    end

    it "finishes at the planned finish date" do
      expect(timeframe.effective_finish).to eq sprint.finish_date.in_time_zone.end_of_day
    end

    it "reports the planned start" do
      expect(timeframe.planned_start).to eq sprint.start_date.in_time_zone.beginning_of_day
    end

    it "has been measured only up to now, the finish still being ahead" do
      expect(timeframe.measured_until).to be_within(1.second).of(Time.zone.now)
    end
  end

  context "when the sprint has been started but not completed, after the planned finish has passed" do
    let(:sprint) do
      build_stubbed(:sprint,
                    start_date: 20.days.ago.to_date,
                    finish_date: 5.days.ago.to_date,
                    started_at: 20.days.ago)
    end

    it "runs up to now rather than the stale planned finish date" do
      expect(timeframe.effective_finish).to be_within(1.second).of(Time.zone.now)
    end

    it "still reports the planned finish" do
      expect(timeframe.planned_finish).to eq sprint.finish_date.in_time_zone.end_of_day
    end
  end

  context "when the sprint was completed before its finish date" do
    let(:sprint) do
      build_stubbed(:sprint,
                    start_date: 20.days.ago.to_date,
                    finish_date: 5.days.from_now.to_date,
                    started_at: 20.days.ago,
                    completed_at: 1.day.ago)
    end

    it "finishes at the completion timestamp rather than the current time" do
      expect(timeframe.effective_finish).to eq sprint.completed_at
    end

    it "has been measured only up to the completion, which is already past" do
      expect(timeframe.measured_until).to eq sprint.completed_at
    end
  end

  context "when the sprint was completed after its finish date" do
    let(:sprint) do
      build_stubbed(:sprint,
                    start_date: 20.days.ago.to_date,
                    finish_date: 5.days.ago.to_date,
                    started_at: 20.days.ago,
                    completed_at: 1.day.ago)
    end

    it "finishes at the completion timestamp rather than the current time" do
      expect(timeframe.effective_finish).to eq sprint.completed_at
    end
  end

  # A sprint is planned in dates, so where its days begin is whatever the caller's zone says.
  context "with a zone of its own" do
    subject(:timeframe) { described_class.new(sprint, zone: ActiveSupport::TimeZone["Asia/Kolkata"]) }

    let(:sprint) do
      build_stubbed(:sprint,
                    start_date: Date.new(2026, 10, 12),
                    finish_date: Date.new(2026, 10, 23),
                    started_at: Time.utc(2026, 10, 12, 20))
    end

    it "opens the planned start on that zone's midnight, not the application's" do
      expect(timeframe.planned_start).to eq Time.utc(2026, 10, 11, 18, 30)
    end

    it "closes the planned finish on that zone's midnight" do
      expect(timeframe.planned_finish.utc.strftime("%Y-%m-%d %H:%M")).to eq "2026-10-23 18:29"
    end

    # The instant is the same either way; what changes is the day it is taken to fall on, which
    # is what the series are sampled and declined over.
    it "hands an actual start back in that zone, so its date reads as the viewer's" do
      expect(timeframe.effective_start).to eq sprint.started_at
      expect(timeframe.effective_start.to_date).to eq Date.new(2026, 10, 13)
      expect(sprint.started_at.to_date).to eq Date.new(2026, 10, 12)
    end
  end

  context "when the sprint has not started yet" do
    let(:sprint) do
      build_stubbed(:sprint, start_date: 3.days.from_now.to_date, finish_date: 10.days.from_now.to_date)
    end

    it "falls back to the beginning of the planned start date" do
      expect(timeframe.effective_start).to eq sprint.start_date.in_time_zone.beginning_of_day
    end

    it "falls back to the end of the planned finish date" do
      expect(timeframe.effective_finish).to eq sprint.finish_date.in_time_zone.end_of_day
    end

    it "has measured nothing, there being nothing yet to measure" do
      expect(timeframe.measured_until).to be_nil
    end
  end
end

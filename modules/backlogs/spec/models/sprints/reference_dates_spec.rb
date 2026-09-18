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

RSpec.describe Sprints::ReferenceDates do
  subject(:reference_dates) { described_class.new(sprint) }

  context "when the sprint has been started but not completed, before the scheduled finish" do
    let(:sprint) do
      build_stubbed(:sprint,
                    start_date: 10.days.ago.to_date,
                    finish_date: 4.days.from_now.to_date,
                    started_at: 7.days.ago)
    end

    it "starts at the actual start timestamp" do
      expect(reference_dates.start).to eq sprint.started_at
    end

    it "finishes at the scheduled finish date" do
      expect(reference_dates.finish).to eq sprint.finish_date.in_time_zone.end_of_day
    end
  end

  context "when the sprint has been started but not completed, after the scheduled finish has passed" do
    let(:sprint) do
      build_stubbed(:sprint,
                    start_date: 20.days.ago.to_date,
                    finish_date: 5.days.ago.to_date,
                    started_at: 20.days.ago)
    end

    it "runs up to now rather than the stale planned finish date" do
      expect(reference_dates.finish).to be_within(1.second).of(Time.zone.now)
    end

    it "still reports the planned date as the scheduled finish" do
      expect(reference_dates.scheduled_finish).to eq sprint.finish_date.in_time_zone.end_of_day
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
      expect(reference_dates.finish).to eq sprint.completed_at
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
      expect(reference_dates.finish).to eq sprint.completed_at
    end
  end

  context "when the sprint has not started yet" do
    let(:sprint) do
      build_stubbed(:sprint, start_date: 3.days.from_now.to_date, finish_date: 10.days.from_now.to_date)
    end

    it "falls back to the beginning of the planned start date" do
      expect(reference_dates.start).to eq sprint.start_date.in_time_zone.beginning_of_day
    end

    it "falls back to the end of the planned finish date" do
      expect(reference_dates.finish).to eq sprint.finish_date.in_time_zone.end_of_day
    end
  end
end

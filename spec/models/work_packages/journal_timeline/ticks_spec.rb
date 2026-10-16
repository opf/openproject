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

RSpec.describe WorkPackages::JournalTimeline::Ticks do
  subject(:ticks) { described_class.build(from:, to:, step:, zone:) }

  let(:zone) { ActiveSupport::TimeZone["UTC"] }
  let(:step) { :hour }

  describe "the interval bounds" do
    let(:from) { Time.utc(2026, 10, 12, 9, 15) }
    let(:to) { Time.utc(2026, 10, 12, 12, 30) }

    it "starts at from and ends at to, with the period ends in between" do
      expect(ticks).to eq [
        from,
        Time.utc(2026, 10, 12, 9).end_of_hour,
        Time.utc(2026, 10, 12, 10).end_of_hour,
        Time.utc(2026, 10, 12, 11).end_of_hour,
        to
      ]
    end

    context "when from equals to" do
      let(:to) { from }

      it "yields that single instant, which is the frozen snapshot case" do
        expect(ticks).to eq [from]
      end
    end

    context "when from is after to" do
      let(:to) { from - 1.hour }

      it { is_expected.to eq [] }
    end

    context "when from already sits exactly on a period end" do
      let(:from) { Time.utc(2026, 10, 12, 9).end_of_hour }
      let(:to) { Time.utc(2026, 10, 12, 11, 30) }

      it "does not repeat it" do
        expect(ticks).to eq [
          from,
          Time.utc(2026, 10, 12, 10).end_of_hour,
          to
        ]
      end
    end
  end

  describe "a day step" do
    let(:step) { :day }
    let(:from) { Time.utc(2026, 10, 12) }
    let(:to) { Time.utc(2026, 10, 14).end_of_day }

    it "samples at the end of each day" do
      expect(ticks).to eq [
        from,
        Time.utc(2026, 10, 12).end_of_day,
        Time.utc(2026, 10, 13).end_of_day,
        to
      ]
    end
  end

  describe "deriving boundaries in the given zone rather than UTC" do
    let(:zone) { ActiveSupport::TimeZone["Europe/Berlin"] }
    let(:step) { :day }
    let(:from) { Date.new(2026, 10, 12) }
    let(:to) { Date.new(2026, 10, 13) }

    it "ends the day at local midnight, not UTC midnight" do
      expect(ticks.second).to eq zone.parse("2026-10-12").end_of_day
    end

    context "with a half-hour offset zone" do
      let(:zone) { ActiveSupport::TimeZone["Asia/Kolkata"] }
      let(:step) { :hour }

      it "places hour ends off the UTC hour" do
        expect(ticks.second).to eq zone.parse("2026-10-12 00:00").end_of_hour
        expect(ticks.second.utc.min).to eq 29
      end
    end
  end

  describe "daylight saving transitions" do
    let(:zone) { ActiveSupport::TimeZone["Europe/Berlin"] }

    def hourly_tick_count_for(date)
      described_class.build(from: date, to: zone.parse(date.to_s).end_of_day, step: :hour, zone:).size
    end

    it "yields one fewer tick on the short day and one more on the long day" do
      regular = hourly_tick_count_for(Date.new(2026, 10, 12))

      expect(hourly_tick_count_for(Date.new(2026, 3, 29))).to eq(regular - 1)
      expect(hourly_tick_count_for(Date.new(2026, 10, 25))).to eq(regular + 1)
    end
  end

  describe "an unsupported step" do
    let(:from) { Time.utc(2026, 10, 12) }
    let(:to) { Time.utc(2026, 10, 13) }
    let(:step) { :week }

    it "raises rather than silently sampling at the wrong resolution" do
      expect { ticks }.to raise_error(ArgumentError, /step/)
    end
  end
end

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

RSpec.describe Sprints::ChartWindow do
  subject(:window) { described_class.new(sprint) }

  shared_let(:project) { create(:project) }

  let(:monday) { Date.new(2026, 10, 12) }
  let(:second_friday) { Date.new(2026, 10, 23) }
  let(:now) { monday.in_time_zone + 3.days + 12.hours }

  let(:started_at) { monday.in_time_zone + 9.hours }
  let(:start_date) { monday }
  let(:finish_date) { second_friday }

  let(:sprint) do
    build_stubbed(:sprint, project:, start_date:, finish_date:, started_at:)
  end

  def preceding_sprint(start_date, finish_date)
    build_stubbed(:sprint, project:, start_date:, finish_date:,
                           started_at: start_date.in_time_zone + 9.hours)
  end

  around do |example|
    travel_to(now) { example.run }
  end

  describe "#measured_until" do
    it "reaches up to now while the sprint is still running" do
      expect(window.measured_until).to eq now
    end

    context "when the sprint has been completed" do
      let(:sprint) do
        build_stubbed(:sprint, project:, start_date:, finish_date:, started_at:,
                               completed_at: second_friday.in_time_zone + 17.hours)
      end
      let(:now) { second_friday.in_time_zone + 3.days }

      it "stops where the sprint did rather than running on" do
        expect(window.measured_until).to eq sprint.completed_at
      end
    end

    context "when the sprint has not begun" do
      let(:started_at) { nil }
      let(:now) { monday.in_time_zone - 3.days }

      it "has measured nothing, there being nothing yet to measure" do
        expect(window.measured_until).to be_nil
      end

      # The window opens with the preceding sprint, which has been running all along.
      it "measures up to now once a preceding sprint opens the window" do
        opening = preceding_sprint(monday - 14.days, monday - 4.days)

        expect(described_class.new(sprint, opening_sprint: opening).measured_until).to eq now
      end
    end
  end

  describe "an opening sprint of its own" do
    let(:opening) { preceding_sprint(monday - 42.days, monday - 32.days) }

    subject(:window) { described_class.new(sprint, opening_sprint: opening) }

    it "opens where that sprint began" do
      expect(window.charted_from).to eq opening.started_at
    end

    it "still closes where the sprint being reported on does" do
      expect(window.charted_until).to eq second_friday.in_time_zone.end_of_day
    end

    # Over that many days an hourly series says more about rendering cost than about progress.
    it "falls to daily sampling over the longer span" do
      expect(window.step).to eq :day
      expect(described_class.new(sprint).step).to eq :hour
    end
  end

  describe ".spanning" do
    let(:earliest) { preceding_sprint(monday - 28.days, monday - 18.days) }
    let(:nearest) { preceding_sprint(monday - 14.days, monday - 4.days) }

    it "opens with the earliest sprint it is given and closes with the last" do
      window = described_class.spanning([earliest, nearest, sprint])

      expect(window.charted_from).to eq earliest.started_at
      expect(window.charted_until).to eq second_friday.in_time_zone.end_of_day
    end

    # Sprints are listed by the moment they actually started, which places one that never did
    # behind every sprint that ran, however early it was planned for.
    it "opens with the earliest of them however they are listed" do
      only_planned = build_stubbed(:sprint, project:, start_date: monday - 56.days, finish_date: monday - 46.days)
      window = described_class.spanning([nearest, only_planned, sprint])

      expect(window.charted_from).to eq (monday - 56.days).in_time_zone
    end

    it "spans the one sprint it is given" do
      expect(described_class.spanning([sprint]).charted_from).to eq started_at
    end

    # Opening later costs history, which is less than the whole chart: past a year nothing is
    # drawn at all.
    it "gives up the sprints that do not fit rather than the chart" do
      ancient = preceding_sprint(monday - 400.days, monday - 380.days)
      window = described_class.spanning([ancient, nearest, sprint])

      expect(window).not_to be_too_long_to_chart
      expect(window.charted_from).to eq nearest.started_at
    end

    it "keeps the last sprint even when it does not fit on its own" do
      let_alone = build_stubbed(:sprint, project:, start_date: monday, finish_date: monday + 400.days, started_at:)
      window = described_class.spanning([nearest, let_alone])

      expect(window).to be_too_long_to_chart
      expect(window.charted_from).to eq started_at
    end
  end

  describe "#ticks" do
    it "samples from the opening of the window up to where it has measured" do
      expect(window.ticks.first).to eq started_at
      expect(window.ticks.last).to eq now
    end

    context "when the sprint has not begun" do
      let(:started_at) { nil }
      let(:now) { monday.in_time_zone - 3.days }

      it { expect(window.ticks).to be_empty }
    end
  end
end

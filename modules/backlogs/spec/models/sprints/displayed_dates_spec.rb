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

RSpec.describe Sprints::DisplayedDates do
  subject(:displayed_dates) { described_class.new(sprint) }

  let(:start_date) { Date.new(2025, 1, 15) }
  let(:finish_date) { Date.new(2025, 1, 29) }
  let(:started_at) { Time.utc(2025, 1, 16, 9, 30) }
  let(:completed_at) { Time.utc(2025, 1, 30, 17, 45) }

  shared_examples "displays" do |start:, finish:|
    it "displays the #{start} start" do
      expect(displayed_dates.start).to eq(start == :planned ? start_date : started_at)
      expect(displayed_dates.start_planned?).to be(start == :planned)
    end

    it "displays the #{finish} finish" do
      expect(displayed_dates.finish).to eq(finish == :planned ? finish_date : completed_at)
      expect(displayed_dates.finish_planned?).to be(finish == :planned)
    end
  end

  context "when the sprint is in planning" do
    let(:sprint) { build_stubbed(:sprint, status: :in_planning, start_date:, finish_date:) }

    it_behaves_like "displays", start: :planned, finish: :planned

    it "has no actual dates" do
      expect(displayed_dates).not_to be_actual
      expect(displayed_dates.actual_range).to eq [nil, nil]
    end

    it "has a planned range" do
      expect(displayed_dates).to be_planned
      expect(displayed_dates.planned_range).to eq [start_date, finish_date]
    end
  end

  context "when the sprint is in planning with only a start date" do
    let(:sprint) { build_stubbed(:sprint, status: :in_planning, start_date:, finish_date: nil) }

    it "has a planned range that is still open" do
      expect(displayed_dates).to be_planned
      expect(displayed_dates.planned_range).to eq [start_date, nil]
    end
  end

  context "when the sprint is in planning but carries a start timestamp" do
    let(:sprint) { build_stubbed(:sprint, status: :in_planning, start_date:, finish_date:, started_at:) }

    it_behaves_like "displays", start: :planned, finish: :planned
  end

  context "when the sprint is in planning without dates" do
    let(:sprint) { build_stubbed(:sprint, status: :in_planning, start_date: nil, finish_date: nil) }

    it "has nothing to display" do
      expect(displayed_dates).not_to be_any
      expect(displayed_dates).not_to be_planned
    end
  end

  context "when the sprint is active" do
    let(:sprint) { build_stubbed(:sprint, status: :active, start_date:, finish_date:, started_at:) }

    it_behaves_like "displays", start: :actual, finish: :planned

    it "has an actual range that is still open" do
      expect(displayed_dates).to be_actual
      expect(displayed_dates.actual_range).to eq [started_at, nil]
    end

    it "pairs the actual start with the planned finish" do
      expect(displayed_dates.range).to eq [started_at, finish_date]
    end
  end

  context "when the sprint is active without a start timestamp" do
    let(:sprint) { build_stubbed(:sprint, status: :active, start_date:, finish_date:, started_at: nil) }

    it_behaves_like "displays", start: :planned, finish: :planned
  end

  context "when the sprint is completed" do
    let(:sprint) do
      build_stubbed(:sprint, status: :completed, start_date:, finish_date:, started_at:, completed_at:)
    end

    it_behaves_like "displays", start: :actual, finish: :actual

    it "has a closed actual range" do
      expect(displayed_dates.actual_range).to eq [started_at, completed_at]
    end
  end

  context "when the sprint is completed without a completion timestamp" do
    let(:sprint) do
      build_stubbed(:sprint, status: :completed, start_date:, finish_date:, started_at:, completed_at: nil)
    end

    it_behaves_like "displays", start: :actual, finish: :planned
  end

  context "when the sprint is completed without planned dates" do
    let(:sprint) do
      build_stubbed(:sprint, status: :completed, start_date: nil, finish_date: nil, started_at:, completed_at:)
    end

    it "still has dates to display" do
      expect(displayed_dates).to be_any
    end

    it "has no planned range" do
      expect(displayed_dates).not_to be_planned
    end
  end
end

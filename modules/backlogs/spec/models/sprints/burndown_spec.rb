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

RSpec.describe Sprints::Burndown do
  subject(:burndown) { described_class.new(sprint:, project:) }

  shared_let(:project) { create(:project) }
  shared_let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
  shared_let(:open_status) { create(:status, name: "Open", is_default: true) }
  shared_let(:closed_status) { create(:status, name: "Closed", is_closed: true) }

  # A sprint from one Monday to the Friday of the following week: 10 working days
  # around a single weekend.
  let(:first_monday) { Date.new(2026, 10, 12) }
  let(:first_tuesday) { Date.new(2026, 10, 13) }
  let(:first_wednesday) { Date.new(2026, 10, 14) }
  let(:first_friday) { Date.new(2026, 10, 16) }
  let(:saturday) { Date.new(2026, 10, 17) }
  let(:sunday) { Date.new(2026, 10, 18) }
  let(:second_friday) { Date.new(2026, 10, 23) }
  let(:next_saturday) { Date.new(2026, 10, 24) }
  let(:next_sunday) { Date.new(2026, 10, 25) }

  let(:sprint_start) { at_hour(first_monday, 9) }
  let(:now) { at_hour(first_wednesday, 12) }

  let(:started_at) { sprint_start }
  let(:completed_at) { nil }
  let(:finish_date) { second_friday }

  let(:sprint) do
    create(:sprint, project:, start_date: first_monday, finish_date:, started_at:, completed_at:)
  end

  current_user { create(:user, member_with_roles: { project => role }) }

  def at_hour(date, hour)
    date.in_time_zone + hour.hours
  end

  def story_pointed(journals)
    create(:work_package, project:, sprint:, status: open_status, journals:)
  end

  # A day's value is what it leaves behind, recorded at the moment it ends.
  def day_end_values(series, dates)
    dates.index_with { |date| series.find { it.at == date.in_time_zone.end_of_day }&.value }
  end

  # The outermost gaps are partial, running from the series' origin and up to where it stops.
  def interior_gaps(series)
    series.map(&:at).each_cons(2).map { |earlier, later| later - earlier }[1..-2]
  end

  before { week_with_saturday_and_sunday_as_weekend }

  around do |example|
    travel_to(now) { example.run }
  end

  describe "#remaining" do
    before { story_pointed(sprint_start => { story_points: 10 }) }

    it "starts at the points open when the sprint started" do
      expect(burndown.remaining.first.value).to eq 10.0
    end

    it "stops at the current time rather than the sprint's finish date" do
      expect(burndown.remaining.last.at).to eq now
    end

    it "samples every hour" do
      expect(interior_gaps(burndown.remaining)).to all(eq 1.hour)
    end

    context "with a sprint running longer than a month" do
      let(:finish_date) { first_monday + 60.days }

      it "falls back to sampling every day" do
        expect(interior_gaps(burndown.remaining)).to all(eq 1.day)
      end
    end

    context "when story points are reduced mid-sprint" do
      before { story_pointed(sprint_start => { story_points: 4 }, at_hour(first_tuesday, 15) => { story_points: 1 }) }

      it "carries each value until the moment it changes" do
        expect(burndown.remaining.map(&:value).uniq).to eq [14.0, 11.0]
      end
    end

    context "when a work package is closed mid-sprint" do
      before { story_pointed(sprint_start => { story_points: 4, status_id: closed_status.id }) }

      it "leaves closed work out" do
        expect(burndown.remaining.map(&:value).uniq).to eq [10.0]
      end
    end

    context "when the sprint has not started yet" do
      let(:started_at) { nil }
      let(:now) { at_hour(first_monday - 7.days, 12) }

      it { expect(burndown.remaining).to be_empty }
    end
  end

  describe "#guideline" do
    before { story_pointed(sprint_start => { story_points: 10 }) }

    it "declines by an equal share of the starting points on each working day" do
      expect(day_end_values(burndown.guideline, [first_monday, first_tuesday, first_friday]))
        .to eq(first_monday => 9.0, first_tuesday => 8.0, first_friday => 5.0)
    end

    it "stays flat across non-working days" do
      expect(day_end_values(burndown.guideline, [first_friday, saturday, sunday]).values).to all(eq 5.0)
    end

    it "samples every day rather than every hour" do
      expect(interior_gaps(burndown.guideline)).to all(eq 1.day)
    end

    it "reaches zero at the end of the planned finish date" do
      expect(burndown.guideline.last.value).to eq 0.0
      expect(burndown.guideline.last.at).to eq second_friday.in_time_zone.end_of_day
    end

    context "with a sprint sampled daily rather than hourly" do
      let(:finish_date) { first_monday + 60.days }

      it "still ends on the finish date, so the step does not move the series" do
        expect(burndown.guideline.last.at).to eq finish_date.in_time_zone.end_of_day
      end
    end

    context "when story points change after the sprint started" do
      before { story_pointed(at_hour(first_tuesday, 15) => { story_points: 90 }) }

      it "still starts from what the sprint began with" do
        expect(burndown.guideline.first.value).to eq 10.0
      end
    end

    context "when the sprint has overrun its finish date" do
      let(:now) { at_hour(second_friday + 5.days, 12) }

      it "still reaches zero on the planned date rather than today" do
        expect(burndown.guideline.last.at).to eq second_friday.in_time_zone.end_of_day
        expect(burndown.guideline.last.value).to eq 0.0
      end
    end

    context "with a sprint spanning a single working day" do
      let(:finish_date) { first_monday }

      it "spends everything on that day" do
        expect(burndown.guideline.map(&:value)).to eq [10.0, 0.0]
      end
    end

    context "with a sprint spanning only non-working days" do
      let(:sprint) do
        create(:sprint, project:, start_date: saturday, finish_date: saturday, started_at: at_hour(saturday, 0))
      end

      it "declines nowhere rather than dividing by zero" do
        expect(burndown.guideline.map(&:value)).to eq [10.0]
      end
    end
  end

  describe "#projection" do
    before { story_pointed(sprint_start => { story_points: 8 }) }

    it "carries the current points to zero on the planned finish date" do
      expect(burndown.projection.first.value).to eq 8.0
      expect(burndown.projection.last.value).to eq 0.0
      expect(burndown.projection.last.at).to eq second_friday.in_time_zone.end_of_day
    end

    it "stays flat across non-working days" do
      expect(day_end_values(burndown.projection, [saturday, sunday]).values.uniq.size).to eq 1
    end

    context "when the sprint has not started" do
      let(:started_at) { nil }

      it { expect(burndown.projection).to be_empty }
    end

    context "when the sprint has been completed" do
      let(:completed_at) { at_hour(first_tuesday, 17) }

      it { expect(burndown.projection).to be_empty }
    end

    context "when the planned finish date has passed" do
      let(:now) { at_hour(second_friday + 5.days, 12) }

      it { expect(burndown.projection).to be_empty }
    end
  end

  describe "#too_long_to_chart?" do
    context "with a sprint running longer than a year" do
      let(:finish_date) { first_monday + 1.year + 1.day }

      it { expect(burndown).to be_too_long_to_chart }

      it "draws nothing rather than a series nobody could read" do
        expect(burndown.remaining).to be_empty
        expect(burndown.guideline).to be_empty
        expect(burndown.projection).to be_empty
        expect(burndown.non_working_intervals).to be_empty
      end
    end

    context "with a sprint running exactly a year" do
      let(:finish_date) { first_monday + 1.year }

      before { story_pointed(sprint_start => { story_points: 10 }) }

      it { expect(burndown).not_to be_too_long_to_chart }

      it "still draws" do
        expect(burndown.guideline).not_to be_empty
      end
    end

    context "when an unfinished sprint has overrun by more than a year" do
      let(:now) { at_hour(second_friday + 1.year, 12) }

      it { expect(burndown).to be_too_long_to_chart }
    end
  end

  describe "#non_working_intervals" do
    it "covers the whole charted range" do
      expect(burndown.non_working_intervals).to eq [saturday..sunday]
    end

    context "when the sprint has overrun" do
      let(:now) { at_hour(second_friday + 5.days, 12) }

      it "extends past the planned finish date" do
        expect(burndown.non_working_intervals.last).to eq next_saturday..next_sunday
      end
    end
  end

  describe "#story_points?" do
    it { expect(burndown.story_points?).to be false }

    context "with a story pointed work package" do
      before { story_pointed(sprint_start => { story_points: 3 }) }

      it { expect(burndown.story_points?).to be true }
    end

    context "with a work package left unestimated" do
      before { story_pointed(sprint_start => { story_points: nil }) }

      it { expect(burndown.story_points?).to be false }
    end
  end
end

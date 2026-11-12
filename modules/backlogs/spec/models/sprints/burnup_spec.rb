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

RSpec.describe Sprints::Burnup do
  subject(:burnup) { described_class.new(sprint:, project:) }

  shared_let(:project) { create(:project) }
  shared_let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
  shared_let(:open_status) { create(:status, name: "Open", is_default: true) }
  shared_let(:closed_status) { create(:status, name: "Closed", category: "closed") }
  shared_let(:done_status) { create(:status, name: "Done") }

  # A sprint from one Monday to the Friday of the following week: 10 working days
  # around a single weekend.
  let(:first_monday) { Date.new(2026, 10, 12) }
  let(:first_tuesday) { Date.new(2026, 10, 13) }
  let(:first_wednesday) { Date.new(2026, 10, 14) }
  let(:first_thursday) { Date.new(2026, 10, 15) }
  let(:first_friday) { Date.new(2026, 10, 16) }
  let(:saturday) { Date.new(2026, 10, 17) }
  let(:sunday) { Date.new(2026, 10, 18) }
  let(:second_friday) { Date.new(2026, 10, 23) }

  let(:sprint_start) { at_hour(first_monday, 9) }
  let(:mid_sprint) { at_hour(first_tuesday, 15) }
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

  # Each journal stands on its own, so every one states the points and status it has.
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

  describe "#scope" do
    before { story_pointed(sprint_start => { story_points: 10 }) }

    it "stops at the current time rather than the sprint's finish date" do
      expect(burnup.scope.last.at).to eq now
    end

    context "with closed work in the sprint" do
      before { story_pointed(sprint_start => { story_points: 4, status_id: closed_status.id }) }

      it "counts it alongside the open work" do
        expect(burnup.scope.map(&:value).uniq).to eq [14.0]
      end
    end

    context "when work is added to the sprint" do
      before { story_pointed(sprint_start => { story_points: 3, sprint_id: nil }, mid_sprint => { story_points: 3 }) }

      it "goes up" do
        expect(burnup.scope.map(&:value).uniq).to eq [10.0, 13.0]
      end
    end

    context "when work is removed from the sprint" do
      before { story_pointed(sprint_start => { story_points: 3 }, mid_sprint => { story_points: 3, sprint_id: nil }) }

      it "goes down" do
        expect(burnup.scope.map(&:value).uniq).to eq [13.0, 10.0]
      end
    end

    context "when the sprint has not started yet" do
      let(:started_at) { nil }
      let(:now) { at_hour(first_monday - 7.days, 12) }

      it { expect(burnup.scope).to be_empty }
    end

    context "with the estimation unit feature active", with_flag: { project_settings_estimation_unit: true } do
      before do
        project.estimation_unit = estimation_unit
        story_pointed(sprint_start => { story_points: 3, estimated_hours: 2.5, status_id: closed_status.id })
      end

      context "when estimation unit is story points" do
        let(:estimation_unit) { "story_points" }

        it "sums the story points" do
          expect(burnup.scope.first).to have_attributes(value: 13.0)
        end
      end

      context "when estimation unit is time" do
        let(:estimation_unit) { "time" }

        it "sums the estimated hours" do
          expect(burnup.scope.first).to have_attributes(value: 2.5)
        end
      end

      context "when estimation unit is none" do
        let(:estimation_unit) { "none" }

        it "counts the work packages" do
          expect(burnup.scope.first).to have_attributes(value: 2.0)
        end
      end
    end
  end

  describe "#completed" do
    before { story_pointed(sprint_start => { story_points: 10 }) }

    it "leaves open work out" do
      expect(burnup.completed.map(&:value).uniq).to eq [0.0]
    end

    context "when work is closed mid-sprint" do
      before do
        story_pointed(sprint_start => { story_points: 4 }, mid_sprint => { story_points: 4, status_id: closed_status.id })
      end

      it "goes up" do
        expect(burnup.completed.map(&:value).uniq).to eq [0.0, 4.0]
      end
    end

    context "when work reaches a status the project counts as done" do
      before do
        project.done_statuses << done_status
        story_pointed(sprint_start => { story_points: 4 }, mid_sprint => { story_points: 4, status_id: done_status.id })
      end

      it "goes up" do
        expect(burnup.completed.map(&:value).uniq).to eq [0.0, 4.0]
      end
    end

    context "when closed work is reopened" do
      before do
        story_pointed(sprint_start => { story_points: 4, status_id: closed_status.id },
                      mid_sprint => { story_points: 4, status_id: open_status.id })
      end

      it "goes down" do
        expect(burnup.completed.map(&:value).uniq).to eq [4.0, 0.0]
      end
    end

    context "when closed work is removed from the sprint" do
      before do
        story_pointed(sprint_start => { story_points: 4, status_id: closed_status.id },
                      mid_sprint => { story_points: 4, status_id: closed_status.id, sprint_id: nil })
      end

      it "goes down" do
        expect(burnup.completed.map(&:value).uniq).to eq [4.0, 0.0]
      end
    end

    context "with the estimation unit feature active", with_flag: { project_settings_estimation_unit: true } do
      before do
        project.estimation_unit = estimation_unit
        story_pointed(sprint_start => { story_points: 3, estimated_hours: 2.5, status_id: closed_status.id })
      end

      context "when estimation unit is story points" do
        let(:estimation_unit) { "story_points" }

        it "sums the story points" do
          expect(burnup.completed.first).to have_attributes(value: 3.0)
        end
      end

      context "when estimation unit is time" do
        let(:estimation_unit) { "time" }

        it "sums the estimated hours" do
          expect(burnup.completed.first).to have_attributes(value: 2.5)
        end
      end

      context "when estimation unit is none" do
        let(:estimation_unit) { "none" }

        it "counts the work packages" do
          expect(burnup.completed.first).to have_attributes(value: 1.0)
        end
      end
    end
  end

  describe "#scope_projection" do
    before { story_pointed(sprint_start => { story_points: 10 }) }

    it "holds the current scope from now to the end of the planned finish date" do
      expect(burnup.scope_projection.map(&:value).uniq).to eq [10.0]
      expect(burnup.scope_projection.first.at).to eq now
      expect(burnup.scope_projection.last.at).to eq second_friday.in_time_zone.end_of_day
    end

    it "is sampled on the same days as the guideline" do
      expect(burnup.scope_projection.drop(1).map(&:at)).to eq(burnup.guideline.map(&:at).select { it > now })
    end

    context "when the sprint has not started" do
      let(:started_at) { nil }

      it { expect(burnup.scope_projection).to be_empty }
    end

    context "when the sprint has been completed" do
      let(:completed_at) { at_hour(first_tuesday, 17) }

      it { expect(burnup.scope_projection).to be_empty }
    end

    context "when the planned finish date has passed" do
      let(:now) { at_hour(second_friday + 5.days, 12) }

      it { expect(burnup.scope_projection).to be_empty }
    end
  end

  describe "#guideline" do
    before { story_pointed(sprint_start => { story_points: 10 }) }

    it "starts at the sprint's start from the work completed by then" do
      expect(burnup.guideline.first.at).to eq sprint_start
      expect(burnup.guideline.first.value).to eq 0.0
    end

    # Started at 09:00, so the first Monday is worth 0.625 of a day and the sprint has 9.625
    # days of capacity rather than 10, putting every whole day's share at 10 / 9.625 = 1.039.
    it "rises by an equal share of the scope on each working day" do
      expect(day_end_values(burnup.guideline, [first_monday, first_tuesday, first_friday])
               .transform_values { it.round(3) })
        .to eq(first_monday => 0.649, first_tuesday => 1.688, first_friday => 4.805)
    end

    it "stays flat across non-working days" do
      expect(day_end_values(burnup.guideline, [first_friday, saturday, sunday]).values.uniq.size).to eq 1
    end

    it "samples every day rather than every hour" do
      expect(interior_gaps(burnup.guideline)).to all(eq 1.day)
    end

    it "meets the scope projection at the end of the planned finish date" do
      expect(burnup.guideline.last).to eq burnup.scope_projection.last
    end

    context "with work already completed when the sprint started" do
      before { story_pointed(sprint_start => { story_points: 4, status_id: closed_status.id }) }

      it "starts from that work and rises to the whole scope" do
        expect(burnup.guideline.first.value).to eq 4.0
        expect(burnup.guideline.last.value).to eq 14.0
      end
    end

    context "when the scope grows after the sprint started" do
      before { story_pointed(sprint_start => { story_points: 5, sprint_id: nil }, mid_sprint => { story_points: 5 }) }

      it "rises to the current scope in one straight line from the start" do
        expect(burnup.guideline.last.value).to eq 15.0
        expect(day_end_values(burnup.guideline, [first_monday])[first_monday].round(3)).to eq 0.974
      end
    end

    context "when the sprint has overrun its finish date" do
      let(:now) { at_hour(second_friday + 5.days, 12) }

      it "stretches to now and meets the scope there" do
        expect(burnup.guideline.last.at).to eq now
        expect(burnup.guideline.last.value).to eq 10.0
      end

      # Two and a half more working days stretch the capacity to 12.125.
      it "rises more slowly than the plan would have" do
        expect(day_end_values(burnup.guideline, [first_monday])[first_monday].round(3)).to eq 0.515
      end
    end

    context "when the sprint was completed before its planned finish date" do
      let(:completed_at) { at_hour(first_thursday, 17) }

      it "meets the scope where the sprint closed" do
        expect(burnup.guideline.last.at).to eq completed_at
        expect(burnup.guideline.last.value).to eq 10.0
      end

      # The capacity shrinks to 0.625 + 2 + 17 / 24 = 3.333 days.
      it "rises more steeply than the plan would have" do
        expect(day_end_values(burnup.guideline, [first_monday])[first_monday].round(3)).to eq 1.875
      end

      context "when the sprint was completed on a non-working day" do
        let(:completed_at) { at_hour(saturday, 11) }

        it "has met the scope on the last working day and arrives flat" do
          expect(day_end_values(burnup.guideline, [first_friday])[first_friday]).to eq 10.0
          expect(burnup.guideline.last.at).to eq completed_at
          expect(burnup.guideline.last.value).to eq 10.0
        end
      end
    end

    context "with a sprint spanning only non-working days" do
      let(:now) { at_hour(saturday, 12) }
      let(:sprint) do
        create(:sprint, project:, start_date: saturday, finish_date: saturday, started_at: at_hour(saturday, 0))
      end

      it "rises nowhere rather than dividing by zero" do
        expect(burnup.guideline.map(&:value)).to eq [0.0]
      end
    end

    context "when the sprint has not started yet" do
      let(:started_at) { nil }
      let(:now) { at_hour(first_monday - 7.days, 12) }

      it { expect(burnup.guideline).to be_empty }
    end
  end

  describe "#anything_to_chart?" do
    it "is true when story points were in the sprint within the window" do
      story_pointed(sprint_start => { story_points: 10 })

      expect(burnup).to be_anything_to_chart
    end

    it "is true when the story points in the sprint were closed throughout the window" do
      story_pointed(sprint_start => { story_points: 5, status_id: closed_status.id })

      expect(burnup).to be_anything_to_chart
    end

    it "is false when the work packages in the sprint have no story points" do
      story_pointed(sprint_start => { story_points: nil })

      expect(burnup).not_to be_anything_to_chart
    end

    context "when the sprint has not started yet" do
      let(:started_at) { nil }
      let(:now) { at_hour(first_monday - 7.days, 12) }

      it "is false, as there is nothing measured yet" do
        story_pointed(now - 1.hour => { story_points: 10 })

        expect(burnup).not_to be_anything_to_chart
      end
    end
  end
end

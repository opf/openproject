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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe My::TimeTracking::StackEntriesComponent, type: :component do
  let(:user) { create(:user) }
  let(:project) { create(:project, name: "Demo project") }
  let(:work_package) { create(:work_package, project:, subject: "Some work") }
  let(:date) { Date.civil(2022, 5, 4) }

  let!(:time_entry) do
    create(:time_entry, user:, project:, entity: work_package, spent_on: date, hours: 2.5)
  end

  subject(:rendered_component) do
    render_inline(described_class.new(time_entries: [time_entry], mode: :week, date:))
  end

  before do
    login_as user
  end

  def stack_entries
    JSON.parse(rendered_component.css("[data-controller='my--time-tracking-stack']")
                 .attr("data-my--time-tracking-stack-time-entries-value").value)
  end

  it "mounts the stack controller with a target to render into" do
    expect(rendered_component).to have_css(
      "[data-controller='my--time-tracking-stack'] [data-my--time-tracking-stack-target='stack']"
    )
  end

  it "exposes the requested date and mode" do
    wrapper = rendered_component.css("[data-controller='my--time-tracking-stack']")

    expect(wrapper.attr("data-my--time-tracking-stack-initial-date-value").value).to eq("2022-05-04")
    expect(wrapper.attr("data-my--time-tracking-stack-mode-value").value).to eq("week")
  end

  it "serializes the time entries the same way the calendar view does" do
    expect(stack_entries).to eq(
      JSON.parse([FullCalendar::TimeEntryEvent.from_time_entry(time_entry)].to_json)
    )
  end

  it "serializes what the stack positions and labels its bars with" do
    expect(stack_entries).to contain_exactly(
      hash_including(
        "id" => time_entry.id.to_s,
        "start" => "2022-05-04",
        "hours" => 2.5,
        "title" => "Demo project: #{work_package.formatted_id} Some work",
        "typeId" => work_package.type_id
      )
    )
  end

  context "when the entry has a start time in a foreign time zone" do
    let!(:time_entry) do
      create(:time_entry, :with_start_and_end_time, user:, project:, entity: work_package, spent_on: date)
    end

    it "keeps the spent on date in the serialized start" do
      expect(stack_entries.first["start"]).to start_with("2022-05-04")
    end
  end

  describe "the scheduled working hours", with_settings: { start_of_week: 1 } do
    def working_hours
      JSON.parse(rendered_component.css("[data-controller='my--time-tracking-stack']")
                   .attr("data-my--time-tracking-stack-working-hours-value").value)
    end

    # 2022-05-04 is a Wednesday, so the week runs from Monday the 2nd to Sunday the 8th.
    before do
      create(:user_working_hours, user:, valid_from: Date.civil(2022, 4, 1), monday: 480, tuesday: 480,
                                  wednesday: 480, thursday: 480, friday: 480, saturday: 0, sunday: 0)
    end

    it "covers the whole week the view lays out, not only the days that are worked" do
      expect(working_hours.keys).to eq(%w[2022-05-02 2022-05-03 2022-05-04 2022-05-05 2022-05-06 2022-05-07 2022-05-08])
    end

    it "reports the scheduled hours per day and none on the weekend" do
      expect(working_hours).to include("2022-05-04" => 8.0, "2022-05-07" => 0.0, "2022-05-08" => 0.0)
    end

    context "when a new schedule starts in the middle of the week" do
      before do
        create(:user_working_hours, user:, valid_from: Date.civil(2022, 5, 5), monday: 240, tuesday: 240,
                                    wednesday: 240, thursday: 240, friday: 240, saturday: 0, sunday: 0)
      end

      it "uses the schedule valid on each day, switching on the day it starts" do
        expect(working_hours).to include(
          "2022-05-04" => 8.0,
          "2022-05-05" => 4.0,
          "2022-05-06" => 4.0
        )
      end
    end

    context "when the user is only scheduled for part of the day" do
      before { UserWorkingHours.for_user(user).update_all(availability_factor: 50) }

      it "scales the hours by the availability factor" do
        expect(working_hours).to include("2022-05-04" => 4.0)
      end
    end
  end
end

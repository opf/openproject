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

RSpec.describe My::TimeTracking::ChartEntriesComponent, type: :component do
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

  def chart_entries
    JSON.parse(rendered_component.css("[data-controller='my--time-tracking-chart']")
                 .attr("data-my--time-tracking-chart-time-entries-value").value)
  end

  it "mounts the chart controller with a target to render into" do
    expect(rendered_component).to have_css(
      "[data-controller='my--time-tracking-chart'] [data-my--time-tracking-chart-target='chart']"
    )
  end

  it "exposes the requested date and mode" do
    wrapper = rendered_component.css("[data-controller='my--time-tracking-chart']")

    expect(wrapper.attr("data-my--time-tracking-chart-initial-date-value").value).to eq("2022-05-04")
    expect(wrapper.attr("data-my--time-tracking-chart-mode-value").value).to eq("week")
  end

  it "serializes the time entries the same way the calendar view does" do
    expect(chart_entries).to eq(
      JSON.parse([FullCalendar::TimeEntryEvent.from_time_entry(time_entry)].to_json)
    )
  end

  it "serializes what the chart positions and labels its bars with" do
    expect(chart_entries).to contain_exactly(
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
      expect(chart_entries.first["start"]).to start_with("2022-05-04")
    end
  end
end

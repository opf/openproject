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
# modify it under the terms of the GNU General Public License version 3
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

RSpec.describe "Meetings demo data seeding", type: :model do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }

  let(:seed_data) do
    seed_data = Source::SeedData.new(data_hash)
    seed_data.store_reference(:openproject_admin, admin)
    seed_data
  end
  # Mirrors the demo-data seeder list in DemoData::ProjectSeeder for meetings.
  let(:seeder_classes) do
    [
      Meetings::DemoData::MeetingSeriesSeeder,
      Meetings::DemoData::MeetingAgendaItemsSeeder,
      Meetings::DemoData::MeetingSeriesFinalizerSeeder
    ]
  end

  let(:data_hash) do
    YAML.load <<~YAML
      meeting_series:
      - reference: :weekly_meeting
        title: Weekly
        duration: 60
        interval: 1
        frequency: :weekly
        time_zone: "Europe/Berlin"
        author: :openproject_admin
      meeting_agenda_items:
      - title: Discussion topic
        notes: "Something to discuss"
        meeting: :weekly_meeting_template
        author: :openproject_admin
        duration: 5
    YAML
  end

  def run_seeders
    seeder_classes.each { |klass| klass.new(project, seed_data).seed! }
    perform_enqueued_jobs
  end

  it "leaves the template open so a user can use the series without 'Open first meeting'" do
    seeder_classes.each { |klass| klass.new(project, seed_data).seed! }

    series = RecurringMeeting.find_by!(project: project, title: "Weekly")
    expect(series.template).not_to be_draft
  end

  it "instantiates the first occurrence with the seeded agenda items copied over" do
    seeder_classes.each { |klass| klass.new(project, seed_data).seed! }
    perform_enqueued_jobs

    series = RecurringMeeting.find_by!(project: project, title: "Weekly")
    first_meeting = series.meetings.find_by(template: false)

    expect(first_meeting).to be_present
    expect(first_meeting.start_time).to eq(series.first_occurrence)
    expect(first_meeting.agenda_items.pluck(:title)).to include("Discussion topic")
  end
end

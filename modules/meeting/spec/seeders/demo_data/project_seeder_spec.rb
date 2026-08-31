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

RSpec.describe DemoData::ProjectSeeder do
  include_context "with basic seed data"

  subject(:project_seeder) { described_class.new(seed_data.lookup("projects.my-project")) }

  let(:work_package) { create(:work_package) }
  let(:user) { create(:admin) }
  let(:seed_data) do
    data = basic_seed_data.merge(
      Source::SeedData.new(
        "projects" => {
          "my-project" => project_data
        }
      )
    )

    data.store_reference(:openproject_user, user)
    data.store_reference(:work_package_foo, work_package)

    data
  end

  let(:project_data) do
    YAML.load <<~SEEDING_DATA_YAML
      name: 'Some project'
      meeting_series:
        - title: Weekly
          reference: :weekly_meeting
          duration: 30
          frequency: :weekly
          interval: 1
          author: :openproject_user
          time_zone: "Etc/UTC"
      meeting_agenda_items:
        - title: First topic
          meeting: :weekly_meeting_template
          duration: 10
          author: :openproject_user
          notes: Some **markdown**
        - title: Reference
          meeting: :weekly_meeting_template
          duration: 5
          author: :openproject_user
          notes: Some **markdown**
          work_package: :work_package_foo
    SEEDING_DATA_YAML
  end

  before do
    project_seeder.seed!
  end

  it "creates an associated series and template" do
    series = RecurringMeeting.find_by(title: "Weekly")
    expect(series.author).to eq user

    template = series.template
    expect(template.duration).to eq 0.5
    expect(template.agenda_items.count).to eq 2

    first = template.agenda_items.find_by(title: "First topic")
    expect(first.duration_in_minutes).to eq 10
    expect(first.author).to eq user
    expect(first.notes).to eq "Some **markdown**"

    second = template.agenda_items.find_by(work_package:)
    expect(second.title).to be_nil
    expect(second.duration_in_minutes).to eq 5
    expect(second.author).to eq user
    expect(second.notes).to eq "Some **markdown**"
  end

  it "instantiates the first occurrence with the template's agenda items" do
    series = RecurringMeeting.find_by(title: "Weekly")
    expect(series.template).not_to be_draft
    # The finalizer creates the first occurrence; the MeetingOccurrencesSeeder fills up the next few.
    expect(series.scheduled_instances.count).to eq(5)
    instance = series.scheduled_instances.order(:start_time).first
    expect(instance.duration).to eq 0.5
    expect(instance.agenda_items.count).to eq 2

    first = instance.agenda_items.find_by(title: "First topic")
    expect(first.duration_in_minutes).to eq 10
    expect(first.author).to eq user
    expect(first.notes).to eq "Some **markdown**"

    second = instance.agenda_items.find_by(work_package:)
    expect(second.title).to be_nil
    expect(second.duration_in_minutes).to eq 5
    expect(second.author).to eq user
    expect(second.notes).to eq "Some **markdown**"
  end
end

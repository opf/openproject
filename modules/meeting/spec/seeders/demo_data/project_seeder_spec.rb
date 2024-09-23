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
  let(:user) { create(:user) }
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
      meetings:
        - title: Weekly
          reference: :weekly_meeting
          duration: 30
          author: :openproject_user
        - title: Implicit 1h duration
          author: :openproject_user
      meeting_agenda_items:
        - title: First topic
          meeting: :weekly_meeting
          duration: 10
          author: :openproject_user
          notes: Some **markdown**
        - title: Reference
          meeting: :weekly_meeting
          duration: 5
          author: :openproject_user
          notes: Some **markdown**
          work_package: :work_package_foo
    SEEDING_DATA_YAML
  end

  before do
    project_seeder.seed!
  end

  it "creates an associated meeting" do
    meeting = Meeting.find_by(title: "Weekly")
    expect(meeting.author).to eq user
    expect(meeting.duration).to eq 0.5

    expect(meeting.agenda_items.count).to eq 2

    first = meeting.agenda_items.find_by(title: "First topic")
    expect(first.duration_in_minutes).to eq 10
    expect(first.author).to eq user
    expect(first.notes).to eq "Some **markdown**"

    second = meeting.agenda_items.find_by(work_package:)
    expect(second.title).to be_nil
    expect(second.duration_in_minutes).to eq 5
    expect(second.author).to eq user
    expect(second.notes).to eq "Some **markdown**"
  end

  it "uses default duration of 1h if not specified" do
    meeting = Meeting.find_by(title: "Implicit 1h duration")
    expect(meeting.duration).to eq 1
  end
end

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

RSpec.describe Meetings::DemoData::MeetingAgendaItemsSeeder do
  include_context "with basic seed data"

  shared_let(:alice) { create(:user, firstname: "Alice") }
  shared_let(:bob) { create(:user, firstname: "Bob") }
  shared_let(:meeting) { create(:structured_meeting, title: "Weekly meeting") }
  shared_let(:work_package) { create(:work_package, subject: "Some important task") }

  subject(:seeder) { described_class.new("_project", seed_data) }

  let(:seed_data) do
    seed_data = basic_seed_data.merge(Source::SeedData.new(data_hash))
    seed_data.store_reference(:user_alice, alice)
    seed_data.store_reference(:user_bob, bob)
    seed_data.store_reference(:weekly_meeting, meeting)
    seed_data.store_reference(:work_package_some_important_task, work_package)
    seed_data
  end

  before do
    seeder.seed!
  end

  context "with some meeting agenda items defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        meeting_agenda_items:
        - title: Good news
          notes: "What went well this week?"
          meeting: :weekly_meeting
          author: :user_alice
          duration: 5
        - work_package: :work_package_some_important_task
          title: "Important task"
          notes: "We should discuss this..."
          meeting: :weekly_meeting
          author: :user_bob
          presenter: :user_bob
      SEEDING_DATA_YAML
    end

    it "creates the corresponding statuses with the given attributes" do
      expect(MeetingAgendaItem.count).to eq(2)
      expect(MeetingAgendaItem.find_by(title: "Good news")).to have_attributes(
        notes: "What went well this week?",
        meeting:,
        author: alice,
        presenter: nil,
        duration_in_minutes: 5
      )
      expect(MeetingAgendaItem.find_by(work_package_id: work_package.id)).to have_attributes(
        notes: "We should discuss this...",
        meeting:,
        author: bob,
        presenter: bob,
        duration_in_minutes: nil
      )
    end

    it "sets item type to simple if title is set and work_package is not set" do
      expect(MeetingAgendaItem.find_by(title: "Good news")).to have_attributes(
        item_type: "simple"
      )
    end

    it "sets item type to work_package and set title to nil if work_package is set" do
      expect(MeetingAgendaItem.find_by(work_package_id: work_package.id)).to have_attributes(
        item_type: "work_package",
        title: nil
      )
    end
  end
end

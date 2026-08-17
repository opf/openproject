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

RSpec.describe API::V3::TimeEntries::TimeEntryRepresenter, "parsing" do
  include API::V3::Utilities::PathHelper

  let(:time_entry) do
    build_stubbed(:time_entry,
                  comments: "blubs",
                  spent_on: Date.current - 3.days,
                  created_at: DateTime.now - 6.hours,
                  updated_at: DateTime.now - 3.hours,
                  activity:,
                  project:,
                  user:)
  end
  let(:project) { build_stubbed(:project) }
  let(:project2) { build_stubbed(:project) }
  let(:work_package) { time_entry.entity }
  let(:work_package2) { build_stubbed(:work_package, project: project2) }
  let(:meeting) { build_stubbed(:meeting, project: project2) }
  let(:activity) { build_stubbed(:time_entry_activity) }
  let(:activity2) { build_stubbed(:time_entry_activity) }
  let(:user) { build_stubbed(:user) }
  let(:user2) { build_stubbed(:user) }
  let(:representer) do
    described_class.create(time_entry, current_user: user, embed_links: true)
  end
  let(:user_custom_field) do
    build_stubbed(:time_entry_custom_field, :user)
  end
  let(:text_custom_field) do
    build_stubbed(:time_entry_custom_field)
  end

  let(:entity_link) do
    api_v3_paths.work_package(work_package2.id)
  end

  let(:hash) do
    {
      "_links" => {
        "project" => {
          "href" => api_v3_paths.project(project2.id)
        },
        "activity" => {
          "href" => api_v3_paths.time_entries_activity(activity2.id)
        },
        "entity" => {
          "href" => entity_link
        },
        user_custom_field.attribute_name(:camel_case) => {
          "href" => api_v3_paths.user(user2.id)
        }
      },
      "hours" => "PT5H",
      "comment" => {
        "raw" => "some comment"
      },
      "spentOn" => "2017-07-28",
      "startTime" => "2017-07-28T12:30:00Z",
      text_custom_field.attribute_name(:camel_case) => {
        "raw" => "some text"
      }
    }
  end

  before do
    allow(time_entry)
      .to receive(:available_custom_fields)
      .and_return([text_custom_field, user_custom_field])
  end

  describe "_links" do
    context "activity" do
      it "updates the activity" do
        time_entry = representer.from_hash(hash)
        expect(time_entry.activity_id)
          .to eql(activity2.id)
      end
    end

    context "project" do
      it "updates the project" do
        time_entry = representer.from_hash(hash)
        expect(time_entry.project_id)
          .to eql(project2.id)
      end
    end

    context "entity" do
      it "updates the work_package" do
        time_entry = representer.from_hash(hash)
        expect(time_entry.entity_id).to eql(work_package2.id)
        expect(time_entry.entity_type).to eql("WorkPackage")
      end
    end

    context "linked custom field" do
      it "updates the custom value" do
        time_entry = representer.from_hash(hash)

        expect(time_entry.custom_field_values.detect { |cv| cv.custom_field_id == user_custom_field.id }.value)
          .to eql(user2.id.to_s)
      end
    end

    context "assigning a meeting as entity" do
      let(:entity_link) do
        api_v3_paths.meeting(meeting.id)
      end

      context "entity" do
        it "updates the meeting" do
          time_entry = representer.from_hash(hash)
          expect(time_entry.entity_id).to eql(meeting.id)
          expect(time_entry.entity_type).to eql("Meeting")
        end
      end
    end
  end

  describe "properties" do
    describe "spentOn" do
      it "updates spent_on" do
        time_entry = representer.from_hash(hash)
        expect(time_entry.spent_on)
          .to eql(Date.parse("2017-07-28"))
      end
    end

    describe "startTime" do
      context "when not tracking start and end time" do
        before do
          allow(TimeEntry).to receive_messages(
            can_track_start_and_end_time?: false,
            must_track_start_and_end_time?: false
          )
        end

        it "does not set start_time" do
          time_entry = representer.from_hash(hash)
          expect(time_entry.start_time).to be_nil
        end
      end

      context "when tracking start and end time" do
        before do
          allow(TimeEntry).to receive_messages(
            can_track_start_and_end_time?: true,
            must_track_start_and_end_time?: false
          )
        end

        context "when spent_on != start_time date" do
          before do
            hash["startTime"] = "1980-12-22T12:00:00Z"
          end

          it "raises an error" do
            expect do
              representer.from_hash(hash)
            end.to raise_error(API::Errors::Validation)
          end
        end

        it "sets start_time" do
          user.pref[:time_zone] = "Asia/Tokyo"

          time_entry = representer.from_hash(hash)

          # timezone on the TimeEntry would be set to the user's TimeZone via the SetAttribute service, so we need to
          # manually set it here
          time_entry.time_zone = "Asia/Tokyo"

          # We are sending in 12:30:00 UTC as the start time, in Tokyo time (for 2017-07-28) that equals
          # 21:30:00 in Japan Standard Time (JST), so the time should be set to 21:30

          expect(time_entry.start_time).to eq((21 * 60) + 30) # 21:30

          expect(time_entry.start_timestamp).to eq(DateTime.parse("2017-07-28T12:30:00Z"))
          expect(time_entry.end_timestamp).to eq(DateTime.parse("2017-07-28T17:30:00Z"))
        end
      end
    end

    describe "endTime" do
      context "when tracking start and end time" do
        before do
          allow(TimeEntry).to receive_messages(
            can_track_start_and_end_time?: true,
            must_track_start_and_end_time?: false
          )

          # Different from the start_time + hours derived value (17:30), so a match would
          # prove the sent endTime was actually ignored, not coincidentally equal.
          hash["endTime"] = "2017-07-28T23:00:00Z"
        end

        it "does not raise and ignores the sent endTime, keeping the derived value" do
          parsed = nil
          expect { parsed = representer.from_hash(hash) }.not_to raise_error

          # Normally set via the SetAttribute service; set manually here so end_timestamp
          # can be computed, same as the analogous startTime spec above.
          parsed.time_zone = "UTC"

          expect(parsed.end_timestamp).to eq(DateTime.parse("2017-07-28T17:30:00Z"))
        end
      end
    end

    describe "hours" do
      it "updates hours" do
        time_entry = representer.from_hash(hash)
        expect(time_entry.hours)
          .to be(5.0)
      end

      context "with null value" do
        let(:hash) do
          {
            "hours" => nil
          }
        end

        it "updates hours" do
          time_entry = representer.from_hash(hash)
          expect(time_entry.hours)
            .to be_nil
        end
      end
    end

    describe "comment" do
      it "updates comment" do
        time_entry = representer.from_hash(hash)
        expect(time_entry.comments)
          .to eql("some comment")
      end
    end

    describe "property custom field" do
      it "updates the custom value" do
        time_entry = representer.from_hash(hash)

        expect(time_entry.custom_field_values.detect { |cv| cv.custom_field_id == text_custom_field.id }.value)
          .to eql("some text")
      end
    end
  end
end

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
                  spent_on: Date.today - 3.days,
                  created_at: DateTime.now - 6.hours,
                  updated_at: DateTime.now - 3.hours,
                  activity:,
                  project:,
                  user:)
  end
  let(:project) { build_stubbed(:project) }
  let(:project2) { build_stubbed(:project) }
  let(:work_package) { time_entry.work_package }
  let(:work_package2) { build_stubbed(:work_package) }
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

  let(:hash) do
    {
      "_links" => {
        "project" => {
          "href" => api_v3_paths.project(project2.id)
        },
        "activity" => {
          "href" => api_v3_paths.time_entries_activity(activity2.id)
        },
        "workPackage" => {
          "href" => api_v3_paths.work_package(work_package2.id)

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

    context "workPackage" do
      it "updates the work_package" do
        time_entry = representer.from_hash(hash)
        expect(time_entry.work_package_id)
          .to eql(work_package2.id)
      end
    end

    context "linked custom field" do
      it "updates the custom value" do
        time_entry = representer.from_hash(hash)

        expect(time_entry.custom_field_values.detect { |cv| cv.custom_field_id == user_custom_field.id }.value)
          .to eql(user2.id.to_s)
      end
    end
  end

  describe "properties" do
    context "spentOn" do
      it "updates spent_on" do
        time_entry = representer.from_hash(hash)
        expect(time_entry.spent_on)
          .to eql(Date.parse("2017-07-28"))
      end
    end

    context "hours" do
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

    context "comment" do
      it "updates comment" do
        time_entry = representer.from_hash(hash)
        expect(time_entry.comments)
          .to eql("some comment")
      end
    end

    context "property custom field" do
      it "updates the custom value" do
        time_entry = representer.from_hash(hash)

        expect(time_entry.custom_field_values.detect { |cv| cv.custom_field_id == text_custom_field.id }.value)
          .to eql("some text")
      end
    end
  end
end

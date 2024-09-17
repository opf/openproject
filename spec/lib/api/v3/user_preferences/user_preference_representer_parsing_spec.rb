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

RSpec.describe API::V3::UserPreferences::UserPreferenceRepresenter,
               "parsing" do
  subject(:parsed) { representer.from_hash request_body }

  include API::V3::Utilities::PathHelper

  let(:preference) { OpenStruct.new }
  let(:user) { build_stubbed(:user) }
  let(:representer) { described_class.new(preference, current_user: user) }

  describe "notification_settings" do
    let(:request_body) do
      {
        "notifications" => [
          {
            "assignee" => true,
            "responsible" => true,
            "_links" => {
              "project" => {
                "href" => "/api/v3/projects/1"
              }
            }
          },
          {
            "assignee" => false,
            "responsible" => false,
            "mentioned" => true,
            "_links" => {
              "project" => {
                "href" => nil
              }
            }
          }
        ]
      }
    end

    it "parses them into an array of structs" do
      expect(subject.notification_settings).to be_a Array
      expect(subject.notification_settings.length).to eq 2
      in_project, global = subject.notification_settings

      expect(in_project[:project_id]).to eq "1"
      expect(in_project[:assignee]).to be_truthy
      expect(in_project[:responsible]).to be_truthy
      expect(in_project[:mentioned]).to be_nil

      expect(global[:project_id]).to be_nil
      expect(global[:assignee]).to be_falsey
      expect(global[:responsible]).to be_falsey
      expect(global[:mentioned]).to be true
    end
  end

  describe "daily_reminders" do
    let(:request_body) do
      {
        "dailyReminders" => {
          "enabled" => true,
          "times" => %w[07:00 15:00 18:00:00+00:00]
        }
      }
    end

    it "parses the times into full iso8601 time format" do
      expect(parsed.daily_reminders)
        .to eql({
                  "enabled" => true,
                  "times" => %w[07:00:00+00:00 15:00:00+00:00 18:00:00+00:00]
                })
    end
  end

  describe "pause_reminders" do
    let(:request_body) do
      {
        "pauseReminders" => {
          "enabled" => true,
          "firstDay" => first_day,
          "lastDay" => last_day
        }
      }
    end

    context "with all set" do
      let(:first_day) { "2021-10-10" }
      let(:last_day) { "2021-10-20" }

      it "sets both dates" do
        expect(parsed.pause_reminders)
          .to eql({
                    "enabled" => true,
                    "first_day" => first_day,
                    "last_day" => last_day
                  })
      end
    end

    context "with first only set" do
      let(:first_day) { "2021-10-10" }
      let(:last_day) { nil }

      it "uses the first day for the last day" do
        expect(parsed.pause_reminders)
          .to eql({
                    "enabled" => true,
                    "first_day" => first_day,
                    "last_day" => first_day
                  })
      end
    end

    context "with last only set" do
      let(:first_day) { nil }
      let(:last_day) { "2021-10-10" }

      it "uses the first day for the last day" do
        expect(parsed.pause_reminders)
          .to eql({
                    "enabled" => true,
                    "first_day" => nil,
                    "last_day" => last_day
                  })
      end
    end
  end
end

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
               "rendering" do
  include API::V3::Utilities::PathHelper

  let(:preference) do
    build_stubbed(:user_preference,
                  settings: {
                    "daily_reminders" => {
                      "enabled" => true,
                      "times" => %w[07:00:00+00:00 15:00:00+00:00]
                    }
                  })
  end
  let(:notification_setting) { build(:notification_setting, start_date: 3, due_date: 3, overdue: 3) }
  let(:user) { build_stubbed(:user, preference:) }
  let(:representer) { described_class.new(preference, current_user: user) }

  before do
    allow(preference).to receive(:user).and_return(user)
    allow(preference).to receive(:notification_settings).and_return([notification_setting])
  end

  subject(:generated) { representer.to_json }

  it { expect(subject).to have_json_path("hideMail") }
  it { expect(subject).to have_json_path("timeZone") }
  it { expect(subject).to have_json_path("commentSortDescending") }
  it { expect(subject).to have_json_path("warnOnLeavingUnsaved") }
  it { expect(subject).to have_json_path("autoHidePopups") }

  describe "timeZone" do
    context "without a timezone set" do
      let(:preference) { build(:user_preference, time_zone: "") }

      it "shows the timeZone as nil" do
        expect(subject).to be_json_eql(nil.to_json).at_path("timeZone")
      end
    end

    context "with a timezone set" do
      let(:preference) { build(:user_preference, time_zone: "Europe/Paris") }

      it "shows the canonical time zone" do
        expect(subject).to be_json_eql("Europe/Paris".to_json).at_path("timeZone")
      end
    end
  end

  describe "notification_settings", with_ee: %i[date_alerts] do
    it "renders them as a nested array" do
      expect(subject).to have_json_type(Array).at_path("notifications")
      expect(subject).to be_json_eql(nil.to_json).at_path("notifications/0/_links/project/href")
      date_keys = [NotificationSetting::START_DATE, NotificationSetting::DUE_DATE, NotificationSetting::OVERDUE]

      NotificationSetting.all_settings.each do |key|
        if date_keys.include?(key)
          expect(subject).to be_json_eql("P3D".to_json)
                         .at_path("notifications/0/#{key.to_s.camelize(:lower)}")
        else
          expect(subject)
                .to be_json_eql(notification_setting.send(key).to_json)
                      .at_path("notifications/0/#{key.to_s.camelize(:lower)}")
        end
      end
    end
  end

  describe "properties" do
    describe "_type" do
      it_behaves_like "property", :_type do
        let(:value) { "UserPreferences" }
      end
    end

    describe "dailyReminders" do
      it_behaves_like "property", :dailyReminders do
        let(:value) do
          {
            "enabled" => true,
            "times" => %w[07:00 15:00]
          }
        end
      end
    end
  end

  describe "_links" do
    it_behaves_like "has an untitled link" do
      let(:link) { "self" }
      let(:href) { api_v3_paths.user_preferences(user.id) }
    end

    it_behaves_like "has a titled link" do
      let(:link) { "user" }
      let(:title) { user.name }
      let(:href) { api_v3_paths.user(user.id) }
    end

    describe "immediate update" do
      it_behaves_like "has an untitled link" do
        let(:link) { "updateImmediately" }
        let(:href) { api_v3_paths.user_preferences(user.id) }
      end

      it "is a patch link" do
        expect(subject).to be_json_eql("patch".to_json).at_path("_links/updateImmediately/method")
      end
    end
  end
end

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

RSpec.describe Users::Scopes::WithTimeZone do
  shared_let(:user_besancon) do
    create(
      :user,
      firstname: "Besançon",
      preferences: { time_zone: "Europe/Paris" }
    )
  end
  shared_let(:user_kathmandu) do
    create(
      :user,
      firstname: "Kathmandu",
      preferences: { time_zone: "Asia/Kathmandu" }
    )
  end
  shared_let(:user_new_york) do
    create(
      :user,
      firstname: "New York",
      preferences: { time_zone: "America/New_York" }
    )
  end
  shared_let(:user_paris) do
    create(
      :user,
      firstname: "Paris",
      preferences: { time_zone: "Europe/Paris" }
    )
  end
  shared_let(:user_without_preferences) do
    create(
      :user,
      firstname: "no preference",
      preferences: nil
    )
  end
  shared_let(:user_without_time_zone) do
    create(
      :user,
      firstname: "no preference",
      preferences: {}
    )
  end
  shared_let(:user_with_empty_time_zone) do
    create(
      :user,
      firstname: "no preference",
      preferences: { time_zone: "" }
    )
  end
  shared_let(:anonymous) { User.anonymous }

  describe ".with_time_zone" do
    it "returns user having set a time zone in their preference matching the specified time zone(s)" do
      expect(User.with_time_zone("Europe/Paris"))
        .to contain_exactly(user_paris, user_besancon)

      expect(User.with_time_zone([]))
        .to eq([])

      expect(User.with_time_zone(["America/New_York", "Asia/Kathmandu"]))
        .to contain_exactly(user_new_york, user_kathmandu)
    end

    context "when users have no preferences" do
      it "uses the default time zone returned by Setting.user_default_timezone",
         with_settings: { user_default_timezone: "Europe/Berlin" } do
        expect(User.with_time_zone("Europe/Berlin"))
          .to include(user_without_preferences)
      end
    end

    context "when users have preferences without time zone set" do
      it "uses the default time zone returned by Setting.user_default_timezone",
         with_settings: { user_default_timezone: "Europe/Berlin" } do
        expect(User.with_time_zone("Europe/Berlin"))
          .to include(user_without_time_zone)
      end
    end

    context "when users have preferences with time zone set to empty string" do
      it "uses the default time zone returned by Setting.user_default_timezone",
         with_settings: { user_default_timezone: "Europe/Berlin" } do
        expect(User.with_time_zone("Europe/Berlin"))
          .to include(user_with_empty_time_zone)
      end
    end

    context "when users have no time zone and default user time zone is not set" do
      it "assumes Etc/UTC as default time zone",
         with_settings: { user_default_timezone: nil } do
        expect(User.with_time_zone("Etc/UTC"))
          .to contain_exactly(
            user_without_preferences,
            user_without_time_zone,
            user_with_empty_time_zone,
            anonymous
          )
      end
    end
  end
end

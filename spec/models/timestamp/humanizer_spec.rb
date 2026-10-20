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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Timestamp::Humanizer do
  {
    "PT0S" => "current",
    "P1W" => "1 week ago",
    "P2DT3H" => "2 days and 3 hours ago",
    "invalid" => nil
  }.each do |value, expected|
    it "describes #{value} without resolving relative dates" do
      expect(described_class.new(Timestamp.new(value)).text).to eq(expected)
    end
  end

  context "with localized duration units" do
    include_context "with locale for testing"

    let(:translations) do
      {
        datetime: { distance_in_words: { x_days: { one: "%<count>s Tag", other: "%<count>s Tage" } } },
        time: { relative_ago: "vor %<time>s" }
      }
    end

    it "uses the existing unit keys and locale's phrase order" do
      expect(described_class.new(Timestamp.new("P2D")).text).to eq("vor 2 Tage")
    end
  end

  context "with personal date and time preferences" do
    current_user do
      build_stubbed(:user, preferences: { time_zone: "Europe/Berlin", date_format: "%d.%m.%Y", time_format: "%H:%M" })
    end

    it "uses the same date and time formats as filter values" do
      timestamp = Timestamp.new("2026-09-30T22:00:00Z")
      expect(described_class.new(timestamp).text).to eq("01.10.2026 00:00")
    end

    it "keeps the relative keyword with only its localized time" do
      travel_to(Time.utc(2026, 10, 2, 12)) do
        timestamp = Timestamp.new("oneDayAgo@23:00-04:00")
        expect(described_class.new(timestamp).text).to eq("yesterday at 05:00")
      end
    end
  end
end

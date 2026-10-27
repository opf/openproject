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

require "rails_helper"

RSpec.describe My::Reminders::DailyTimesComponent, type: :component do
  let(:user) { build_stubbed(:user, preferences:) }
  let(:preferences) { { "time_zone" => "Europe/Hamburg" } }

  before do
    login_as(user)

    render_inline(described_class.new(times: ["10:00:00+00:00"], scope: "settings"))
  end

  context "when user has time format preference" do
    let(:preferences) { { **super(), "time_format" => "%H:%M" } }

    it "labels the options in the preferred format" do
      expect(page).to have_element :option, value: "10:00:00+00:00", text: "10:00"
      expect(page).to have_element :option, value: "22:00:00+00:00", text: "22:00"
    end
  end

  context "with a global setting", with_settings: { time_format: "%H.%M" } do
    it "labels the options with that format" do
      expect(page).to have_element :option, value: "10:00:00+00:00", text: "10.00"
      expect(page).to have_element :option, value: "22:00:00+00:00", text: "22.00"
    end
  end

  context "without global setting" do
    it "labels the options with the locale format" do
      expect(page).to have_element :option, value: "10:00:00+00:00", text: "10:00 AM"
      expect(page).to have_element :option, value: "22:00:00+00:00", text: "10:00 PM"
    end
  end
end

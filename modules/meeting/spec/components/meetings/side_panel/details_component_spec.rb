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

RSpec.describe Meetings::SidePanel::DetailsComponent,
               type: :component,
               with_settings: { date_format: "%Y-%m-%d" } do
  let(:user) { build_stubbed(:user) }

  subject do
    render_inline(described_class.new(meeting:))
    page
  end

  before do
    login_as(user)
  end

  context "with templated meeting and working_days frequency" do
    let(:series) do
      build_stubbed(:recurring_meeting,
                    start_time: DateTime.parse("2024-12-04T10:00:00Z"),
                    frequency: "working_days")
    end
    let(:meeting) do
      build_stubbed(:meeting_template,
                    recurring_meeting: series)
    end

    it "doesn't show the weekday" do
      expect(subject).to have_no_text("Wednesday")
    end
  end

  context "with templated meeting and weekly frequency" do
    let(:series) do
      build_stubbed(:recurring_meeting,
                    start_time: DateTime.parse("2024-12-04T10:00:00Z"),
                    frequency: "weekly")
    end
    let(:meeting) do
      build_stubbed(:meeting_template,
                    recurring_meeting: series)
    end

    it "shows the weekday" do
      expect(subject).to have_text("Wednesday")
    end
  end

  context "with a meeting date on the day border" do
    let(:meeting) do
      build_stubbed(:meeting, start_time: DateTime.parse("2025-05-09T22:00:00Z"))
    end

    context "with a user in a +3 time zone" do
      let(:user) { build_stubbed(:user, preferences: { time_zone: "Africa/Nairobi" }) }

      it "formats the date for the current user" do
        expect(subject).to have_text("2025-05-10")
        expect(subject).to have_text("01:00 AM - 02:00 AM")
      end
    end

    context "with a user in a UTC time zone" do
      let(:user) { build_stubbed(:user, preferences: { time_zone: "Etc/UTC" }) }

      it "formats the date for the current user" do
        expect(subject).to have_text("2025-05-09")
        expect(subject).to have_text("10:00 PM - 11:00 PM")
      end
    end
  end
end

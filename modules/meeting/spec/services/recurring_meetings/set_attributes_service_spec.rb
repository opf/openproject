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

RSpec.describe RecurringMeetings::SetAttributesService, type: :model do
  let(:current_user) { build_stubbed(:user) }

  let(:instance) do
    described_class.new(user: current_user, model: model_instance, contract_class: RecurringMeetings::CreateContract)
  end
  let(:model_instance) { RecurringMeeting.new }

  let(:params) { {} }

  subject { instance.call(params) }

  context "with attributes without any special behavior" do
    let(:start_time) { Time.current.change(usec: 0) }
    let(:params) do
      {
        title: "A title",
        start_time: Time.current.iso8601,
        frequency: "daily"
      }
    end

    it "sets the attributes on the model" do
      subject

      expect(model_instance.title).to eq "A title"
      expect(model_instance.start_time).to eq(start_time)
      expect(model_instance).to be_frequency_daily
    end
  end

  context "when setting frequency to working_days" do
    let(:params) do
      {
        frequency: "working_days"
      }
    end

    it "sets the interval to 1" do
      subject

      expect(model_instance).to be_frequency_working_days
      expect(model_instance.interval).to eq 1
    end
  end

  context "when updating schedule related attributes" do
    let(:params) do
      {
        start_time: "2026-01-01T10:00:00Z",
        frequency: "weekly",
        interval: 2,
        end_after: "specific_date",
        end_date: "2026-12-31"
      }
    end

    it "sets the current_schedule_start to the next occurrence from now" do
      travel_to Time.utc(2026, 6, 15, 9, 0, 0) do
        subject

        # Meeting runs from 01.01.2026 10:00 UTC, every 2 weeks and ends at 31.12.2026
        # The next occurrence from 15.06.2026 09:00 UTC is 18.06.2026 10:00 UTC
        expect(model_instance.current_schedule_start).to eq("2026-06-18 10:00:00 UTC")
      end
    end

    it "sets the current_schedule_start to the start_time if there is no next occurrence" do
      travel_to Time.utc(2027, 1, 1, 9, 0, 0) do
        subject

        # Meeting runs from 01.01.2026 10:00 UTC, every 2 weeks and ends at 31.12.2026
        # There is no next occurrence from 01.01.2027 09:00 UTC, so we set it to start_time
        expect(model_instance.current_schedule_start).to eq(model_instance.start_time)
      end
    end
  end

  context "when updating a persisted series" do
    let(:current_user) { create(:user) }
    let(:model_instance) do
      create(:recurring_meeting,
             author: current_user,
             start_time: Time.utc(2026, 1, 7, 10, 0, 0),
             frequency: "weekly",
             interval: 1,
             end_after: "never",
             end_date: nil,
             time_zone: "UTC")
    end
    let(:instance) do
      described_class.new(user: current_user, model: model_instance, contract_class: RecurringMeetings::UpdateContract)
    end

    around do |example|
      travel_to(Time.utc(2026, 6, 15, 9, 0, 0)) { example.run }
    end

    context "with a schedule change" do
      let(:params) { { start_time_hour: "14:00" } }

      it "moves the anchor to the next occurrence of the new schedule" do
        subject

        expect(model_instance.current_schedule_start).to eq("2026-06-17 14:00:00 UTC")
      end
    end

    context "without a schedule change" do
      let(:params) { { title: "A new title" } }

      it "leaves the anchor untouched" do
        expect { subject }.not_to change(model_instance, :current_schedule_start)
      end

      it "still applies the other attributes" do
        subject

        expect(model_instance.title).to eq "A new title"
      end
    end
  end

  context "when calling without params to set default attributes" do
    let(:params) { {} }

    it "sets the time zone from the user" do
      subject

      expect(model_instance.time_zone).to eq current_user.time_zone
    end

    it "sets the author to the user" do
      subject

      expect(model_instance.author).to eq current_user
    end

    it "sets a default duration" do
      subject

      expect(model_instance.duration).to eq 1
    end
  end
end

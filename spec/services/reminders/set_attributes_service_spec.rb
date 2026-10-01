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

RSpec.describe Reminders::SetAttributesService do
  let(:business_day_at_noon) { Time.zone.local(2025, 1, 8, 12, 0, 0) }
  let(:user) { build_stubbed(:user) }
  let(:model_instance) { Reminder.new }
  let(:remindable) { build_stubbed(:work_package) }
  let(:contract_class) { EmptyContract }

  current_user { user }

  subject(:service) do
    described_class.new(user: user,
                        model: model_instance,
                        contract_class:)
  end

  before do
    travel_to(business_day_at_noon)
  end

  after do
    travel_back
  end

  describe "building remind_at timestamp" do
    it "sets the remind_at attribute from date and time params" do
      params = {
        remind_at_date: "2023-10-01",
        remind_at_time: "12:00",
        note: "Some notes",
        remindable:,
        creator: user
      }

      service.call(params)

      expect(model_instance).to have_attributes(
        remind_at: current_user.time_zone.parse("2023-10-01 12:00"),
        note: "Some notes",
        remindable:,
        creator: user
      )
    end

    context "when the `remind_at` attribute is specified" do
      it "does not override the remind_at attribute", :freeze_time do
        params = {
          remind_at: current_user.time_zone.parse("2027-10-01 08:00"),
          remind_at_date: "2023-10-01",
          remind_at_time: "12:00",
          note: "Some notes",
          remindable:,
          creator: user
        }

        model_result = service.call(params).result

        expect(model_result).to have_attributes(
          remind_at: current_user.time_zone.parse("2027-10-01 08:00"),
          note: "Some notes",
          remindable:,
          creator: user
        )
      end
    end

    context "when remind_at_date or remind_at_time is not provided" do
      it "does not set the remind_at attribute" do
        aggregate_failures "one is nil" do
          service.call(remind_at_date: nil, remind_at_time: "12:00")
          expect(model_instance.remind_at).to be_nil
        end

        aggregate_failures "both are nil" do
          service.call(remind_at_date: nil, remind_at_time: nil)
          expect(model_instance.remind_at).to be_nil
        end

        aggregate_failures "none provided" do
          service.call({})
          expect(model_instance.remind_at).to be_nil
        end
      end
    end

    context "when the model instance already has a remind_at set" do
      let(:model_instance) { build_stubbed(:reminder, remind_at: 1.day.from_now) }

      context "and neither remind_at, remind_at_date nor remind_at_time are provided" do
        it "does not change the remind_at attribute" do
          contract_call = service.call({})

          model_result = contract_call.result
          expect(model_result.remind_at).to eq(model_instance.remind_at)
          expect(model_result.remind_at).to be_present
        end
      end
    end
  end

  describe "Error results handling" do
    let(:contract_class) { Reminders::BaseContract }

    context "with remind_at blank active model error" do
      it "adds blank errors for `remind_at_date` and `remind_at_time` attributes" do
        result = service.call({})

        expect(result).to be_failure
        expect(result.errors.messages).to include(
          remind_at_date: ["can't be blank."],
          remind_at_time: ["can't be blank."]
        )
      end
    end

    context "with remind_at in the past active model error" do
      let(:remind_at_date) { 1.day.ago.to_date }
      let(:remind_at_time) { 1.hour.ago.strftime("%H:%M") }

      it "adds errors for `remind_at_date` and `remind_at_time` attributes" do
        result = service.call(remind_at_date:, remind_at_time:)

        expect(result).to be_failure
        expect(result.errors.messages).to include(
          remind_at_date: ["must be in the future."],
          remind_at_time: ["must be in the future."]
        )
      end
    end
  end
end

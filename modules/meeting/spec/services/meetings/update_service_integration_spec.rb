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

RSpec.describe Meetings::UpdateService, "integration", type: :model do
  include Redmine::I18n

  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i(view_meetings edit_meetings) })
  end

  let(:instance) { described_class.new(model: meeting, user:) }
  let(:attributes) { {} }
  let(:params) { {} }

  let(:service_result) { instance.call(attributes:, **params) }
  let(:updated_meeting) { service_result.result }

  context "when meeting is in a series and scheduled to the future" do
    shared_let(:recurring_meeting, refind: true) { create(:recurring_meeting, project:, frequency: "daily") }
    shared_let(:meeting, refind: true) do
      create(:meeting,
             recurring_meeting:,
             project:,
             start_time: Time.zone.today + 2.days + 10.hours,
             recurrence_start_time: Time.zone.today + 2.days + 10.hours)
    end

    context "when scheduled meeting is the first occurrence" do
      before do
        recurring_meeting.update!(start_time: Time.zone.today + 2.days + 10.hours)
      end

      context "when moving it before the start_time of the series" do
        let(:params) do
          { start_time: Time.zone.tomorrow + 10.hours }
        end

        it "is not valid" do
          expect(service_result).not_to be_success
          expect(service_result.errors[:start_date])
            .to include("must be after #{format_time(Time.zone.today + 2.days + 10.hours)}.")
        end
      end

      context "when moving it later" do
        let(:params) do
          { start_time: Time.zone.today + 20.days + 10.hours }
        end

        it "is not valid because needs to be before next occurrence" do
          expect(service_result).not_to be_success
          expect(service_result.errors[:start_date])
              .to include("must be before #{format_time(Time.zone.today + 3.days + 10.hours)}.")
        end
      end

      context "when moving it later than the start time, then moving only start_time_hour" do
        let(:params) do
          { start_time_hour: "09:00" }
        end

        before do
          meeting.update_column(:start_time, Time.zone.tomorrow + 11.hours)
        end

        it "is not valid because needs to be before next occurrence" do
          expect(service_result).not_to be_success
          expect(service_result.errors[:start_date])
            .to include("must be after #{format_time(Time.zone.today + 2.days + 10.hours)}.")
        end
      end
    end

    context "when moving it to the date of the previous schedule" do
      let(:params) do
        { start_time: Time.zone.today + 1.day + 10.hours }
      end

      it "is not valid" do
        expect(service_result).not_to be_success
        expect(service_result.errors[:start_date]).to include("must be after #{format_time(Time.zone.tomorrow + 10.hours)}.")
      end
    end

    context "when moving it to earlier than the date of the previous schedule" do
      let(:params) do
        { start_time: Time.zone.today + 1.day + 8.hours }
      end

      it "is not valid" do
        expect(service_result).not_to be_success
        expect(service_result.errors[:start_date]).to include("must be after #{format_time(Time.zone.tomorrow + 10.hours)}.")
      end
    end

    context "when moving it to after the date of the previous schedule" do
      let(:params) do
        { start_time: Time.zone.today + 1.day + 12.hours }
      end

      it "is valid" do
        expect(service_result).to be_success
      end
    end

    context "when previous schedule exists tomorrow at 10:00" do
      shared_let(:previous_meeting) do
        create(:meeting,
               recurring_meeting:,
               project:,
               start_time: Time.zone.tomorrow + 10.hours,
               recurrence_start_time: Time.zone.tomorrow + 10.hours)
      end

      context "and we try to move it to that date" do
        let(:params) do
          { start_time: Time.zone.tomorrow + 10.hours }
        end

        it "is not valid" do
          expect(service_result).not_to be_success
          expect(service_result.errors[:start_date]).to include("must be after #{format_time(Time.zone.tomorrow + 10.hours)}.")
        end
      end

      context "and we try to move it to before that date" do
        let(:params) do
          { start_time: Time.zone.tomorrow + 9.hours }
        end

        it "is not valid" do
          expect(service_result).not_to be_success
          expect(service_result.errors[:start_date]).to include("must be after #{format_time(Time.zone.tomorrow + 10.hours)}.")
        end
      end

      context "and we try to move it to after that date" do
        let(:params) do
          { start_time: Time.zone.tomorrow + 12.hours }
        end

        it "is valid" do
          expect(service_result).to be_success
        end
      end
    end

    context "when trying to move it to before the start time" do
      let(:params) do
        { start_time: Time.zone.yesterday + 10.hours }
      end

      it "is not valid" do
        expect(service_result).not_to be_success
        expect(service_result.errors[:start_date]).to include("must be in the future.")
      end
    end

    context "when trying to move it to before today" do
      let(:params) do
        { start_time: Time.zone.yesterday + 10.hours }
      end

      it "does not be valid" do
        expect(service_result).not_to be_success
        expect(service_result.errors[:start_date]).to include("must be in the future.")
      end
    end
  end
end

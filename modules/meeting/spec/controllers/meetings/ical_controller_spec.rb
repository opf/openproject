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

RSpec.describe Meetings::ICalController do
  shared_let(:user) { create(:user) }
  shared_let(:project) { create(:project) }
  shared_let(:ical_token) { create(:ical_meeting_token, user:) }
  shared_let(:token) { ical_token.plain_value }

  describe "GET index" do
    context "with valid token" do
      let(:ical_token) { create(:ical_meeting_token, user:) }
      let(:token) { ical_token.plain_value }
      let(:ical_data) { "BEGIN:VCALENDAR\nVERSION:2.0\nEND:VCALENDAR" }

      before do
        service_double = instance_double(AllMeetings::ICalService)
        allow(AllMeetings::ICalService).to receive(:new)
          .with(user:)
          .and_return(service_double)
        allow(service_double).to receive(:call)
          .and_return(ServiceResult.success(result: ical_data))
      end

      it "returns iCalendar data with correct headers" do
        get :index, params: { token: token }, format: :ics

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("text/calendar")
        expect(response.headers["Content-Disposition"]).to include("inline; filename=openproject-meetings.ics")
        expect(response.body).to eq(ical_data)
      end

      it "calls AllMeetings::ICalService with the correct user" do
        service_double = instance_double(AllMeetings::ICalService)
        allow(AllMeetings::ICalService).to receive(:new)
          .with(user:)
          .and_return(service_double)
        allow(service_double).to receive(:call)
          .and_return(ServiceResult.success(result: ical_data))

        get :index, params: { token: token }, format: :ics

        expect(AllMeetings::ICalService).to have_received(:new).with(user:)
        expect(service_double).to have_received(:call)
      end
    end

    context "with invalid token" do
      let(:invalid_token_value) { "invalid_token_456" }

      it "raises an error when token is not found" do
        get :index, params: { token: invalid_token_value }, format: :ics
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when service call fails" do
      before do
        service_double = instance_double(AllMeetings::ICalService)
        allow(AllMeetings::ICalService).to receive(:new)
          .with(user:)
          .and_return(service_double)
        allow(service_double).to receive(:call)
          .and_return(ServiceResult.failure(message: "Service failed"))
      end

      it "logs an error" do
        expect(Rails.logger).to receive(:error).with("Could not generate ICS feed: Service failed")
        get :index, params: { token: token }, format: :ics
      end

      it "returns an empty ICS file" do
        get :index, params: { token: token }, format: :ics

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("text/calendar")
        expect(response.body).to eq(described_class::EMPTY_ICS)
      end
    end

    context "when requesting non-ics format" do
      it "does not respond to other formats" do
        expect do
          get :index, params: { token: token }, format: :json
        end.to raise_error(ActionController::UnknownFormat)
      end
    end
  end
end

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
require "rack/test"

RSpec.describe "API v3 Recurring Meeting Occurrences", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }

  let(:permissions) { %i[view_meetings edit_meetings create_meetings] }
  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:recurring_meeting) { create(:recurring_meeting, project:, author: current_user) }

  before do
    login_as current_user
  end

  describe "GET .../occurrences/upcoming" do
    let(:path) { api_v3_paths.recurring_meeting_occurrences_upcoming(recurring_meeting.id) }

    before { get path }

    it "returns 200 and a collection" do
      expect(last_response).to have_http_status(:ok)

      expect(last_response.body)
        .to be_json_eql("Collection".to_json)
        .at_path("_type")
    end

    it "includes occurrences with state" do
      elements = JSON.parse(last_response.body).dig("_embedded", "elements")
      expect(elements).to be_present
      expect(elements.first).to have_key("state")
      expect(elements.first).to have_key("startTime")
    end
  end

  describe "GET .../occurrences/past" do
    let(:path) { api_v3_paths.recurring_meeting_occurrences_past(recurring_meeting.id) }

    before { get path }

    it "returns 200 and a collection" do
      expect(last_response).to have_http_status(:ok)

      expect(last_response.body)
        .to be_json_eql("Collection".to_json)
        .at_path("_type")
    end
  end

  describe "GET .../occurrences/cancelled" do
    let(:path) { api_v3_paths.recurring_meeting_occurrences_cancelled(recurring_meeting.id) }
    let!(:cancelled_occurrence) do
      create(:meeting,
             project:,
             author: current_user,
             recurring_meeting:,
             start_time: recurring_meeting.first_occurrence,
             recurrence_start_time: recurring_meeting.first_occurrence,
             state: :cancelled)
    end

    before { get path }

    it "returns 200 with cancelled occurrences" do
      expect(last_response).to have_http_status(:ok)

      expect(last_response.body)
        .to have_json_size(1)
        .at_path("_embedded/elements")
    end
  end

  describe "GET .../occurrences/open" do
    let(:path) { api_v3_paths.recurring_meeting_occurrences_open(recurring_meeting.id) }

    before { get path }

    it "returns 200 and a collection" do
      expect(last_response).to have_http_status(:ok)

      expect(last_response.body)
        .to be_json_eql("Collection".to_json)
        .at_path("_type")
    end
  end

  describe "POST .../occurrences/:start_time/init" do
    let(:start_time) { recurring_meeting.first_occurrence }
    let(:path) do
      "#{api_v3_paths.recurring_meeting_occurrence(recurring_meeting.id, start_time.utc.iso8601)}/init"
    end

    subject(:response) { post path }

    it "responds with 201 and creates a meeting" do
      expect(response).to have_http_status(:created)

      expect(response.body)
        .to be_json_eql("Meeting".to_json)
        .at_path("_type")
    end

    it "creates an occurrence meeting" do
      response
      expect(recurring_meeting.meetings.not_templated.where(recurrence_start_time: start_time)).to exist
    end

    context "without create_meetings permission" do
      let(:permissions) { %i[view_meetings] }

      before { response }

      it_behaves_like "unauthorized access"
    end

    context "when restoring a cancelled occurrence with only view_meetings permission" do
      let(:permissions) { %i[view_meetings] }
      let!(:cancelled_occurrence) do
        create(:meeting,
               project:,
               author: current_user,
               recurring_meeting:,
               start_time:,
               recurrence_start_time: start_time,
               state: :cancelled)
      end

      before { response }

      it_behaves_like "unauthorized access"

      it "does not restore the cancelled occurrence" do
        expect(cancelled_occurrence.reload).to be_cancelled
      end
    end
  end

  describe "DELETE .../occurrences/:start_time" do
    let(:start_time) { recurring_meeting.first_occurrence }
    let(:path) { api_v3_paths.recurring_meeting_occurrence(recurring_meeting.id, start_time.utc.iso8601) }

    before { delete path }

    subject { last_response }

    it "responds with 204" do
      expect(subject.status).to eq 204
    end

    it "creates a cancelled occurrence" do
      occurrence = recurring_meeting.meetings.not_templated.find_by(recurrence_start_time: start_time)
      expect(occurrence).to be_present
      expect(occurrence).to be_cancelled
    end

    context "without edit_meetings permission" do
      let(:permissions) { %i[view_meetings] }

      it_behaves_like "unauthorized access"
    end
  end
end

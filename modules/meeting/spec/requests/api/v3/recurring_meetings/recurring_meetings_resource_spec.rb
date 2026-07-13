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

RSpec.describe "API v3 Recurring Meeting resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }

  let(:permissions) { %i[view_meetings create_meetings edit_meetings delete_meetings] }
  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end

  before do
    login_as current_user
  end

  describe "GET /api/v3/recurring_meetings" do
    let!(:recurring_meeting) { create(:recurring_meeting, project:, author: current_user) }
    let(:path) { api_v3_paths.recurring_meetings }

    before { get path }

    it "returns 200 and a collection" do
      expect(last_response).to have_http_status(:ok)

      expect(last_response.body)
        .to be_json_eql("Collection".to_json)
        .at_path("_type")
    end

    context "without view_meetings permission" do
      let(:permissions) { [] }

      it "returns an empty collection" do
        expect(last_response).to have_http_status(:ok)
        expect(last_response.body).to have_json_size(0).at_path("_embedded/elements")
      end
    end
  end

  describe "GET /api/v3/recurring_meetings/:id" do
    let(:recurring_meeting) { create(:recurring_meeting, project:, author: current_user) }
    let(:path) { api_v3_paths.recurring_meeting(recurring_meeting.id) }

    before { get path }

    it "returns 200 and the recurring meeting" do
      expect(last_response).to have_http_status(:ok)

      expect(last_response.body)
        .to be_json_eql("RecurringMeeting".to_json)
        .at_path("_type")

      expect(last_response.body)
        .to be_json_eql(recurring_meeting.id.to_json)
        .at_path("id")
    end

    it "includes occurrence links", :aggregate_failures do
      expect(last_response.body).to have_json_path("_links/occurrencesUpcoming/href")
      expect(last_response.body).to have_json_path("_links/occurrencesPast/href")
      expect(last_response.body).to have_json_path("_links/occurrencesCancelled/href")
      expect(last_response.body).to have_json_path("_links/occurrencesOpen/href")
      expect(last_response.body).to have_json_path("_links/template/href")
    end

    context "when the meeting is monthly by pattern" do
      let(:recurring_meeting) do
        create(:recurring_meeting,
               project:,
               author: current_user,
               frequency: "monthly_nth_weekday",
               monthly_ordinal: -1,
               monthly_weekday: "friday",
               interval: 2)
      end

      it "returns monthly recurrence fields" do
        expect(last_response.body).to be_json_eql(-1.to_json).at_path("monthlyOrdinal")
        expect(last_response.body).to be_json_eql("friday".to_json).at_path("monthlyWeekday")
        expect(last_response.body).to be_json_eql(2.to_json).at_path("interval")
      end
    end

    context "without view_meetings permission" do
      let(:permissions) { [] }

      it "returns 404" do
        expect(last_response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v3/recurring_meetings" do
    let(:path) { api_v3_paths.recurring_meetings }
    let(:body) do
      {
        title: "Weekly Standup Series",
        frequency: "weekly",
        interval: 1,
        endAfter: "specific_date",
        endDate: 6.months.from_now.to_date.iso8601,
        startTime: (Date.tomorrow + 10.hours).iso8601,
        duration: "PT1H",
        location: "Room A",
        _links: {
          project: {
            href: api_v3_paths.project(project.id)
          }
        }
      }.to_json
    end

    subject(:response) { post path, body }

    it "responds with 201" do
      expect(response).to have_http_status(:created)
    end

    it "creates the recurring meeting with a template" do
      response
      rm = RecurringMeeting.find_by(title: "Weekly Standup Series")
      expect(rm).to be_present
      expect(rm.template).to be_present
      expect(rm.frequency).to eq("weekly")
    end

    it "returns the created recurring meeting" do
      expect(response.body)
        .to be_json_eql("RecurringMeeting".to_json)
        .at_path("_type")

      expect(response.body)
        .to be_json_eql("Weekly Standup Series".to_json)
        .at_path("title")
    end

    context "without create_meetings permission" do
      let(:permissions) { %i[view_meetings] }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /api/v3/recurring_meetings/:id" do
    let(:recurring_meeting) { create(:recurring_meeting, project:, author: current_user) }
    let(:path) { api_v3_paths.recurring_meeting(recurring_meeting.id) }
    let(:body) do
      {
        title: "Updated Series Title"
      }.to_json
    end

    subject(:response) { patch path, body }

    it "responds with 200" do
      expect(response).to have_http_status(:ok)
    end

    it "updates the recurring meeting" do
      response
      expect(recurring_meeting.reload.title).to eq("Updated Series Title")
    end

    context "without edit_meetings permission" do
      let(:permissions) { %i[view_meetings] }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /api/v3/recurring_meetings/:id" do
    let(:recurring_meeting) { create(:recurring_meeting, project:, author: current_user) }
    let(:path) { api_v3_paths.recurring_meeting(recurring_meeting.id) }

    before { delete path }

    subject { last_response }

    context "with required permissions" do
      it "responds with 204" do
        expect(subject.status).to eq 204
      end

      it "deletes the recurring meeting" do
        expect(RecurringMeeting).not_to exist(recurring_meeting.id)
      end
    end

    context "without permission" do
      let(:permissions) { %i[view_meetings] }

      it_behaves_like "unauthorized access"
    end
  end
end

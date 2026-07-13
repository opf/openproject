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

RSpec.describe "API v3 Meeting resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %w[meetings]) }

  let(:permissions) { %i[view_meetings create_meetings edit_meetings delete_meetings] }
  let(:current_user) do
    create(:user,
           member_with_permissions: { project => permissions })
  end

  before do
    login_as current_user
  end

  describe "GET /api/v3/meetings/:id" do
    let(:meeting) { create(:meeting, project:, author: current_user) }
    let(:get_path) { api_v3_paths.meeting meeting.id }

    before do
      get get_path
    end

    context "with valid id" do
      it "returns HTTP 200" do
        expect(last_response).to have_http_status :ok
      end

      it "returns the meeting" do
        expect(last_response.body)
          .to be_json_eql("Meeting".to_json)
          .at_path("_type")

        expect(last_response.body)
          .to be_json_eql(meeting.id.to_json)
          .at_path("id")
      end
    end

    context "with multiple participants" do
      let(:other_user) do
        create(:user, member_with_permissions: { project => [:view_meetings] })
      end

      before do
        create(:meeting_participant, meeting:, user: current_user, invited: true)
        create(:meeting_participant, meeting:, user: other_user, invited: true)
        get get_path
      end

      it "_links.participants count matches _embedded.participants count" do
        expect(last_response.body)
          .to have_json_size(2)
          .at_path("_links/participants")

        expect(last_response.body)
          .to have_json_size(2)
          .at_path("_embedded/participants")
      end

      context "when a further participant is added after the response is cached" do
        let(:third_user) do
          create(:user, member_with_permissions: { project => [:view_meetings] })
        end

        it "returns updated _links.participants consistent with _embedded.participants" do
          create(:meeting_participant, meeting:, user: third_user, invited: true)

          get get_path

          expect(last_response.body)
            .to have_json_size(3)
            .at_path("_links/participants")

          expect(last_response.body)
            .to have_json_size(3)
            .at_path("_embedded/participants")
        end
      end
    end

    context "without view_meetings permission" do
      let(:permissions) { [] }

      it "returns HTTP 404" do
        expect(last_response).to have_http_status :not_found
      end
    end

    context "with invalid id" do
      let(:get_path) { api_v3_paths.meeting 0 }

      it_behaves_like "not found"
    end
  end

  describe "POST /api/v3/meetings" do
    let(:path) { api_v3_paths.meetings }
    let(:body) do
      {
        title: "New API Meeting",
        location: "Conference Room A",
        startTime: "2026-06-01T10:00:00Z",
        duration: "PT1H",
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

    it "creates the meeting" do
      response
      expect(Meeting.find_by(title: "New API Meeting"))
        .to be_present
    end

    it "returns the newly created meeting", :aggregate_failures do
      expect(response.body)
        .to be_json_eql("Meeting".to_json)
        .at_path("_type")

      expect(response.body)
        .to be_json_eql("New API Meeting".to_json)
        .at_path("title")

      expect(response.body)
        .to be_json_eql("Conference Room A".to_json)
        .at_path("location")
    end

    context "without create_meetings permission" do
      let(:permissions) { %i[view_meetings] }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without title" do
      let(:body) do
        {
          location: "Room B",
          _links: {
            project: {
              href: api_v3_paths.project(project.id)
            }
          }
        }.to_json
      end

      it "returns 422" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "without project link" do
      let(:body) do
        {
          title: "Meeting without project"
        }.to_json
      end

      it "returns 422" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with participants" do
      let(:other_user) do
        create(:user, member_with_permissions: { project => [:view_meetings] })
      end
      let(:body) do
        {
          title: "Meeting with participants",
          startTime: "2026-06-01T10:00:00Z",
          duration: "PT1H",
          _links: {
            project: {
              href: api_v3_paths.project(project.id)
            },
            participants: [
              { href: api_v3_paths.user(current_user.id) },
              { href: api_v3_paths.user(other_user.id) }
            ]
          }
        }.to_json
      end

      it "responds with 201" do
        expect(response).to have_http_status(:created)
      end

      it "creates the meeting with participants" do
        response
        meeting = Meeting.find_by(title: "Meeting with participants")
        expect(meeting.participants.count).to eq(2)
        expect(meeting.participants.map(&:user_id)).to contain_exactly(current_user.id, other_user.id)
      end

      it "returns the participants in the response" do
        expect(response.body)
          .to have_json_size(2)
          .at_path("_links/participants")
      end
    end
  end

  describe "PATCH /api/v3/meetings/:id" do
    let(:meeting) { create(:meeting, project:, author: current_user) }
    let(:path) { api_v3_paths.meeting(meeting.id) }
    let(:body) do
      {
        title: "Updated Title",
        lockVersion: meeting.lock_version
      }.to_json
    end

    subject(:response) { patch path, body }

    it "responds with 200" do
      expect(response).to have_http_status(:ok)
    end

    it "updates the meeting" do
      response
      expect(meeting.reload.title).to eq("Updated Title")
    end

    it "returns the updated meeting" do
      expect(response.body)
        .to be_json_eql("Updated Title".to_json)
        .at_path("title")
    end

    context "when PATCHing the same participants multiple times" do
      let(:participant_user) do
        create(:user, member_with_permissions: { project => [:view_meetings] })
      end
      let(:body_with_participants) do
        {
          lockVersion: meeting.lock_version,
          _links: {
            participants: [{ href: api_v3_paths.user(participant_user.id) }]
          }
        }.to_json
      end

      it "does not create duplicate participant records" do
        patch path, body_with_participants
        expect(last_response).to have_http_status(:ok)

        updated_lock = JSON.parse(last_response.body)["lockVersion"]
        second_body = { lockVersion: updated_lock,
                        _links: { participants: [{ href: api_v3_paths.user(participant_user.id) }] } }.to_json
        patch path, second_body
        expect(last_response).to have_http_status(:ok)

        expect(meeting.participants.reload.where(user_id: participant_user.id).count).to eq(1)
        expect(last_response.body).to have_json_size(1).at_path("_embedded/participants")
      end
    end

    context "when sending a smaller list of participants to _links.participants" do
      let(:participant_user) do
        create(:user, member_with_permissions: { project => [:view_meetings] })
      end
      let(:other_participant_user) do
        create(:user, member_with_permissions: { project => [:view_meetings] })
      end

      before do
        create(:meeting_participant, meeting:, user: participant_user, invited: true)
        create(:meeting_participant, meeting:, user: other_participant_user, invited: true)
      end

      it "removes unlisted participants" do
        expect(meeting.participants.count).to eq(2)

        body = {
          lockVersion: meeting.lock_version,
          _links: {
            participants: [{ href: api_v3_paths.user(participant_user.id) }]
          }
        }.to_json

        patch path, body

        expect(last_response).to have_http_status(:ok)
        expect(meeting.participants.reload.map(&:user_id)).to contain_exactly(participant_user.id)
        expect(last_response.body).to have_json_size(1).at_path("_embedded/participants")
      end
    end

    context "without edit_meetings permission" do
      let(:permissions) { %i[view_meetings] }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with stale lock version" do
      let(:body) do
        {
          title: "Stale update",
          lockVersion: meeting.lock_version - 1
        }.to_json
      end

      it "returns 409 Conflict" do
        expect(response).to have_http_status(:conflict)
      end
    end

    context "when meeting is not visible" do
      let(:meeting) { create(:meeting, project: other_project) }

      it_behaves_like "not found" do
        before do
          response
        end

        subject { last_response }
      end
    end
  end

  describe "DELETE /api/v3/meetings/:id" do
    let(:meeting) { create(:meeting, project:, author: current_user) }
    let(:path) { api_v3_paths.meeting(meeting.id) }

    before do
      delete path
    end

    subject { last_response }

    context "with required permissions" do
      it "responds with HTTP No Content" do
        expect(subject.status).to eq 204
      end

      it "deletes the meeting" do
        expect(Meeting).not_to exist(meeting.id)
      end

      context "for a non-existent meeting" do
        let(:path) { api_v3_paths.meeting 0 }

        it_behaves_like "not found"
      end
    end

    context "without permission to see meetings" do
      let(:permissions) { [] }

      it_behaves_like "not found"
    end

    context "without permission to delete meetings" do
      let(:permissions) { %i[view_meetings] }

      it_behaves_like "unauthorized access"

      it "does not delete the meeting" do
        expect(Meeting).to exist(meeting.id)
      end
    end
  end
end

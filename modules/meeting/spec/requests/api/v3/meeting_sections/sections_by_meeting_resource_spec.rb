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

RSpec.describe "API v3 Meeting Sections sub-resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:author) { create(:user) }

  let(:permissions) { %i[view_meetings manage_agendas] }
  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:meeting) { create(:meeting, project:, author:) }
  let!(:section) { create(:meeting_section, meeting:, title: "First Section") }

  before do
    login_as current_user
  end

  shared_examples "not found without meeting visibility" do
    context "without view_meetings permission" do
      let(:permissions) { [] }

      it "returns 404" do
        expect(last_response).to have_http_status(:not_found)
      end
    end

    context "with view_meetings permission in another project" do
      let(:current_user) do
        create(:user, member_with_permissions: { other_project => %i[view_meetings manage_agendas] })
      end

      it "returns 404" do
        expect(last_response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /api/v3/meetings/:meeting_id/sections" do
    let(:path) { api_v3_paths.meeting_sections(meeting_id: meeting.id) }

    before { get path }

    it "returns 200 and lists sections" do
      expect(last_response).to have_http_status(:ok)

      expect(last_response.body)
        .to be_json_eql("Collection".to_json)
        .at_path("_type")

      expect(last_response.body)
        .to be_json_eql(api_v3_paths.meeting_section(section.id).to_json)
        .at_path("_embedded/elements/0/_links/self/href")
    end

    it_behaves_like "not found without meeting visibility"
  end

  describe "POST /api/v3/meeting_sections" do
    let(:path) { api_v3_paths.meeting_sections }
    let(:body) do
      {
        title: "New Section",
        _links: {
          meeting: {
            href: api_v3_paths.meeting(meeting.id)
          }
        }
      }.to_json
    end

    subject(:response) { post path, body }

    it "responds with 201" do
      expect(response).to have_http_status(:created)
    end

    it "creates the section" do
      response
      expect(meeting.sections.find_by(title: "New Section")).to be_present
    end

    it "returns the created section" do
      expect(response.body)
        .to be_json_eql("MeetingSection".to_json)
        .at_path("_type")

      expect(response.body)
        .to be_json_eql("New Section".to_json)
        .at_path("title")
    end

    context "without manage_agendas permission" do
      let(:permissions) { %i[view_meetings] }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without any permissions" do
      let(:permissions) { [] }

      it "returns 422 and does not create a section" do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(meeting.sections.find_by(title: "New Section")).to be_nil
      end
    end

    context "with manage_agendas permission in another project" do
      let(:current_user) do
        create(:user, member_with_permissions: { other_project => %i[view_meetings manage_agendas] })
      end

      it "returns 422 and does not create a section" do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(meeting.sections.find_by(title: "New Section")).to be_nil
      end
    end
  end

  describe "GET /api/v3/meetings/:meeting_id/sections/:id" do
    let(:path) { api_v3_paths.meeting_section(section.id, meeting_id: meeting.id) }

    before { get path }

    it "returns 200 and the section" do
      expect(last_response).to have_http_status(:ok)

      expect(last_response.body)
        .to be_json_eql("MeetingSection".to_json)
        .at_path("_type")

      expect(last_response.body)
        .to be_json_eql(section.id.to_json)
        .at_path("id")
    end

    context "with a section from another meeting" do
      let(:other_meeting) { create(:meeting, project:, author:) }
      let(:path) { api_v3_paths.meeting_section(section.id, meeting_id: other_meeting.id) }

      it "returns 404" do
        expect(last_response).to have_http_status(:not_found)
      end
    end

    it_behaves_like "not found without meeting visibility"
  end

  describe "GET /api/v3/meeting_sections/:id" do
    let(:path) { api_v3_paths.meeting_section(section.id) }

    before { get path }

    it "returns 200 and the section" do
      expect(last_response).to have_http_status(:ok)

      expect(last_response.body)
        .to be_json_eql("MeetingSection".to_json)
        .at_path("_type")

      expect(last_response.body)
        .to be_json_eql(api_v3_paths.meeting_section(section.id).to_json)
        .at_path("_links/self/href")
    end

    it_behaves_like "not found without meeting visibility"
  end

  describe "PATCH /api/v3/meeting_sections/:id" do
    let(:path) { api_v3_paths.meeting_section(section.id) }
    let(:body) do
      {
        title: "Updated Section Title"
      }.to_json
    end

    subject(:response) { patch path, body }

    it "responds with 200" do
      expect(response).to have_http_status(:ok)
    end

    it "updates the section" do
      response
      expect(section.reload.title).to eq("Updated Section Title")
    end

    context "without manage_agendas permission" do
      let(:permissions) { %i[view_meetings] }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without any permissions" do
      let(:permissions) { [] }

      it "returns 404 and does not update the section" do
        expect(response).to have_http_status(:not_found)
        expect(section.reload.title).to eq("First Section")
      end
    end

    context "with manage_agendas permission in another project" do
      let(:current_user) do
        create(:user, member_with_permissions: { other_project => %i[view_meetings manage_agendas] })
      end

      it "returns 404 and does not update the section" do
        expect(response).to have_http_status(:not_found)
        expect(section.reload.title).to eq("First Section")
      end
    end
  end

  describe "DELETE /api/v3/meeting_sections/:id" do
    let(:path) { api_v3_paths.meeting_section(section.id) }

    before { delete path }

    subject { last_response }

    context "with required permissions" do
      it "responds with 204" do
        expect(subject.status).to eq 204
      end

      it "deletes the section" do
        expect(MeetingSection).not_to exist(section.id)
      end
    end

    context "without manage_agendas permission" do
      let(:permissions) { %i[view_meetings] }

      it_behaves_like "unauthorized access"
    end

    context "without any permissions" do
      let(:permissions) { [] }

      it "returns 404 and does not delete the section" do
        expect(subject).to have_http_status(:not_found)
        expect(MeetingSection).to exist(section.id)
      end
    end

    context "with manage_agendas permission in another project" do
      let(:current_user) do
        create(:user, member_with_permissions: { other_project => %i[view_meetings manage_agendas] })
      end

      it "returns 404 and does not delete the section" do
        expect(subject).to have_http_status(:not_found)
        expect(MeetingSection).to exist(section.id)
      end
    end
  end
end

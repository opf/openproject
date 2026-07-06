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

RSpec.describe "API v3 Meeting Agenda Items sub-resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }

  let(:permissions) { %i[view_meetings manage_agendas] }
  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:meeting) { create(:meeting, project:, author: current_user) }
  let!(:section) { create(:meeting_section, meeting:) }
  let!(:agenda_item) { create(:meeting_agenda_item, meeting:, meeting_section: section, author: current_user) }
  let!(:outcome) { create(:meeting_outcome, meeting_agenda_item: agenda_item, author: current_user, notes: "Embedded outcome") }

  before do
    login_as current_user
  end

  describe "GET /api/v3/meetings/:meeting_id/agenda_items" do
    let(:path) { api_v3_paths.meeting_agenda_items(meeting_id: meeting.id) }

    before { get path }

    it "returns 200 and lists agenda items" do
      expect(last_response).to have_http_status(:ok)

      expect(last_response.body)
        .to be_json_eql("Collection".to_json)
        .at_path("_type")

      expect(last_response.body)
        .to have_json_size(1)
        .at_path("_embedded/elements")

      expect(last_response.body)
        .to have_json_size(1)
        .at_path("_embedded/elements/0/_embedded/outcomes")

      expect(last_response.body)
        .to be_json_eql(api_v3_paths.meeting_outcome(outcome.id).to_json)
        .at_path("_embedded/elements/0/_links/outcomes/0/href")

      expect(last_response.body)
        .to be_json_eql(api_v3_paths.meeting_agenda_item(agenda_item.id).to_json)
        .at_path("_embedded/elements/0/_links/self/href")

      expect(last_response.body)
        .to be_json_eql(api_v3_paths.meeting_section(section.id).to_json)
        .at_path("_embedded/elements/0/_links/section/href")
    end

    it "only embeds outcomes and sections for the agenda items" do
      expect(last_response.body)
        .to have_json_path("_embedded/elements/0/_embedded/outcomes")

      expect(last_response.body)
        .to be_json_eql(section.id.to_json)
        .at_path("_embedded/elements/0/_embedded/section/id")

      expect(last_response.body)
        .not_to have_json_path("_embedded/elements/0/_embedded/meeting")

      expect(last_response.body)
        .not_to have_json_path("_embedded/elements/0/_embedded/author")
    end

    context "with an agenda item in the meeting backlog" do
      let(:backlog) { meeting.backlog }
      let!(:backlog_agenda_item) do
        create(:meeting_agenda_item,
               meeting:,
               meeting_section: backlog,
               author: current_user,
               title: "Backlog agenda item")
      end

      before do
        get path
      end

      it "embeds and links the backlog section" do
        elements = JSON.parse(last_response.body).dig("_embedded", "elements")
        element = elements.find { |item| item["id"] == backlog_agenda_item.id }
        embedded_section = element.dig("_embedded", "section")

        expect(element.dig("_links", "section", "href"))
          .to eq(api_v3_paths.meeting_section(backlog.id))
        expect(element.dig("_links", "section", "title")).to eq(backlog.title)
        expect(embedded_section["id"]).to eq(backlog.id)
        expect(embedded_section["backlog"]).to be(true)
      end

      it "uses a retrievable backlog section link with canonical meeting ownership" do
        elements = JSON.parse(last_response.body).dig("_embedded", "elements")
        backlog_section_href = elements
          .find { |item| item["id"] == backlog_agenda_item.id }
          .dig("_links", "section", "href")

        get backlog_section_href

        expect(last_response).to have_http_status(:ok)
        expect(last_response.body).to be_json_eql(backlog.id.to_json).at_path("id")
        expect(last_response.body).to be_json_eql(true.to_json).at_path("backlog")
        expect(last_response.body)
          .to be_json_eql(api_v3_paths.meeting(meeting.id).to_json)
          .at_path("_links/meeting/href")
      end
    end

    context "with a recurring meeting occurrence whose backlog is owned by the series template" do
      let(:recurring_meeting) { create(:recurring_meeting, project:, author: current_user) }
      let(:template) { recurring_meeting.template }
      let(:occurrence) do
        create(:recurring_meeting_occurrence,
               recurring_meeting:,
               start_time: recurring_meeting.start_time + 1.week)
      end
      let!(:series_backlog_item) do
        create(:meeting_agenda_item,
               meeting: template,
               meeting_section: template.backlog,
               author: current_user,
               title: "Series backlog item")
      end
      let(:path) { api_v3_paths.meeting_agenda_items(meeting_id: occurrence.id) }

      before { get path }

      it "includes the series backlog item in the occurrence's agenda items" do
        elements = JSON.parse(last_response.body).dig("_embedded", "elements")
        ids = elements.pluck("id")

        expect(ids).to include(series_backlog_item.id)
      end
    end

    context "without view_meetings permission" do
      let(:permissions) { [] }

      it "returns 404" do
        expect(last_response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v3/meeting_agenda_items" do
    let(:path) { api_v3_paths.meeting_agenda_items }
    let(:body) do
      {
        title: "New agenda item",
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

    it "creates the agenda item" do
      response
      expect(meeting.agenda_items.find_by(title: "New agenda item")).to be_present
    end

    it "returns the created item" do
      expect(response.body)
        .to be_json_eql("MeetingAgendaItem".to_json)
        .at_path("_type")

      expect(response.body)
        .to be_json_eql("New agenda item".to_json)
        .at_path("title")
    end

    context "with a section href returned by the section collection" do
      let!(:target_section) { create(:meeting_section, meeting:) }
      let(:target_section_href) do
        get api_v3_paths.meeting_sections(meeting_id: meeting.id)

        JSON
          .parse(last_response.body)
          .dig("_embedded", "elements")
          .find { |item| item["id"] == target_section.id }
          .dig("_links", "self", "href")
      end
      let(:body) do
        {
          title: "New agenda item in target section",
          _links: {
            meeting: {
              href: api_v3_paths.meeting(meeting.id)
            },
            section: {
              href: target_section_href
            }
          }
        }.to_json
      end

      it "responds with 201" do
        expect(target_section_href).to eq(api_v3_paths.meeting_section(target_section.id))
        expect(response).to have_http_status(:created)
      end

      it "creates the agenda item in that section" do
        response

        expect(meeting.agenda_items.find_by(title: "New agenda item in target section").meeting_section)
          .to eq(target_section)
      end
    end

    context "without manage_agendas permission" do
      let(:permissions) { %i[view_meetings] }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /api/v3/meetings/:meeting_id/agenda_items/:id" do
    let(:path) { api_v3_paths.meeting_agenda_item(agenda_item.id, meeting_id: meeting.id) }

    before { get path }

    it "returns 200 and the agenda item" do
      expect(last_response).to have_http_status(:ok)

      expect(last_response.body)
        .to be_json_eql("MeetingAgendaItem".to_json)
        .at_path("_type")

      expect(last_response.body)
        .to be_json_eql(agenda_item.id.to_json)
        .at_path("id")

      expect(last_response.body)
        .to have_json_size(1)
        .at_path("_embedded/outcomes")
    end

    context "with an item from another meeting" do
      let(:other_meeting) { create(:meeting, project:, author: current_user) }
      let(:path) { api_v3_paths.meeting_agenda_item(agenda_item.id, meeting_id: other_meeting.id) }

      it "returns 404" do
        expect(last_response).to have_http_status(:not_found)
      end
    end

    context "when the agenda item is part of the backlog" do
      let(:backlog) { meeting.backlog }
      let!(:backlog_agenda_item) do
        create(:meeting_agenda_item,
               meeting:,
               meeting_section: backlog,
               author: current_user,
               title: "Backlog agenda item")
      end
      let(:path) { api_v3_paths.meeting_agenda_item(backlog_agenda_item.id, meeting_id: meeting.id) }

      it "renders the backlog section correctly" do
        expect(last_response).to have_http_status(:ok)

        expect(last_response.body)
          .to be_json_eql(api_v3_paths.meeting_section(backlog.id).to_json)
          .at_path("_links/section/href")

        expect(last_response.body)
          .to be_json_eql(backlog.title.to_json)
          .at_path("_links/section/title")

        expect(last_response.body)
          .to be_json_eql(backlog.id.to_json)
          .at_path("_embedded/section/id")

        expect(last_response.body)
          .to be_json_eql(true.to_json)
          .at_path("_embedded/section/backlog")

        expect(last_response.body)
          .to be_json_eql(api_v3_paths.meeting(meeting.id).to_json)
          .at_path("_embedded/section/_links/meeting/href")
      end
    end

    context "when the agenda item is in the backlog of a recurring series, fetched via an occurrence" do
      let(:recurring_meeting) { create(:recurring_meeting, project:, author: current_user) }
      let(:template) { recurring_meeting.template }
      let(:occurrence) do
        create(:recurring_meeting_occurrence,
               recurring_meeting:,
               start_time: recurring_meeting.start_time + 1.week)
      end
      let!(:series_backlog_item) do
        create(:meeting_agenda_item,
               meeting: template,
               meeting_section: template.backlog,
               author: current_user,
               title: "Series backlog item")
      end
      let(:path) { api_v3_paths.meeting_agenda_item(series_backlog_item.id, meeting_id: occurrence.id) }

      it "returns 200 and the backlog agenda item" do
        expect(last_response).to have_http_status(:ok)

        expect(last_response.body)
          .to be_json_eql(series_backlog_item.id.to_json)
          .at_path("id")
      end
    end

    context "when the agenda item is linked to a work package in an inaccessible project" do
      let(:private_project) { create(:project, public: false) }
      let(:private_work_package) { create(:work_package, project: private_project) }
      let!(:wp_agenda_item) do
        create(:wp_meeting_agenda_item, meeting:, meeting_section: section, work_package: private_work_package,
                                        author: current_user)
      end
      let(:path) { api_v3_paths.meeting_agenda_item(wp_agenda_item.id, meeting_id: meeting.id) }

      it "returns 200" do
        expect(last_response).to have_http_status(:ok)
      end

      it "does not embed the inaccessible work package" do
        expect(last_response.body).not_to have_json_path("_embedded/workPackage")
      end

      it "renders the work package link as undisclosed" do
        expect(last_response.body)
          .to be_json_eql(API::V3::URN_UNDISCLOSED.to_json)
          .at_path("_links/workPackage/href")
      end
    end
  end

  describe "GET /api/v3/meeting_agenda_items/:id" do
    let(:path) { api_v3_paths.meeting_agenda_item(agenda_item.id) }

    before { get path }

    it "returns 200 and the agenda item" do
      expect(last_response).to have_http_status(:ok)

      expect(last_response.body)
        .to be_json_eql("MeetingAgendaItem".to_json)
        .at_path("_type")

      expect(last_response.body)
        .to be_json_eql(api_v3_paths.meeting_agenda_item(agenda_item.id).to_json)
        .at_path("_links/self/href")
    end

    context "without view_meetings permission" do
      let(:permissions) { [] }

      it "returns 404" do
        expect(last_response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /api/v3/meeting_agenda_items/:id" do
    let(:path) { api_v3_paths.meeting_agenda_item(agenda_item.id) }
    let(:body) do
      {
        title: "Updated title",
        lockVersion: agenda_item.lock_version
      }.to_json
    end

    subject(:response) { patch path, body }

    it "responds with 200" do
      expect(response).to have_http_status(:ok)
    end

    it "updates the agenda item" do
      response
      expect(agenda_item.reload.title).to eq("Updated title")
    end

    context "with a section href returned by the agenda item collection" do
      let(:target_section) { create(:meeting_section, meeting:) }
      let!(:target_agenda_item) do
        create(:meeting_agenda_item, meeting:, meeting_section: target_section, author: current_user)
      end
      let(:target_section_href) do
        get api_v3_paths.meeting_agenda_items(meeting_id: meeting.id)

        JSON
          .parse(last_response.body)
          .dig("_embedded", "elements")
          .find { |item| item["id"] == target_agenda_item.id }
          .dig("_links", "section", "href")
      end
      let(:body) do
        {
          lockVersion: agenda_item.lock_version,
          _links: {
            section: {
              href: target_section_href
            }
          }
        }.to_json
      end

      it "responds with 200" do
        expect(target_section_href).to eq(api_v3_paths.meeting_section(target_section.id))
        expect(response).to have_http_status(:ok)
      end

      it "moves the agenda item to that section" do
        response
        expect(agenda_item.reload.meeting_section).to eq(target_section)
      end
    end

    context "without manage_agendas permission" do
      let(:permissions) { %i[view_meetings] }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /api/v3/meeting_agenda_items/:id" do
    let(:path) { api_v3_paths.meeting_agenda_item(agenda_item.id) }

    before { delete path }

    subject { last_response }

    context "with required permissions" do
      it "responds with 204" do
        expect(subject.status).to eq 204
      end

      it "deletes the agenda item" do
        expect(MeetingAgendaItem).not_to exist(agenda_item.id)
      end
    end

    context "without manage_agendas permission" do
      let(:permissions) { %i[view_meetings] }

      it_behaves_like "unauthorized access"
    end
  end
end

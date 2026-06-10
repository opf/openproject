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

RSpec.describe "API v3 Meeting Outcomes sub-resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings work_package_tracking]) }

  let(:permissions) { %i[view_meetings manage_outcomes] }
  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:meeting) { create(:meeting, project:, author: current_user, state: :in_progress) }
  let!(:section) { create(:meeting_section, meeting:) }
  let!(:agenda_item) { create(:meeting_agenda_item, meeting:, meeting_section: section, author: current_user) }
  let!(:outcome) { create(:meeting_outcome, meeting_agenda_item: agenda_item, author: current_user, notes: "Initial outcome") }

  before do
    login_as current_user
  end

  describe "GET /api/v3/meetings/:meeting_id/agenda_items/:agenda_item_id/outcomes" do
    let(:path) { api_v3_paths.meeting_agenda_item_outcomes(agenda_item.id, meeting_id: meeting.id) }

    before { get path }

    it "returns 200 and lists outcomes" do
      expect(last_response).to have_http_status(:ok)

      expect(last_response.body)
        .to be_json_eql("Collection".to_json)
        .at_path("_type")

      expect(last_response.body)
        .to have_json_size(1)
        .at_path("_embedded/elements")

      expect(last_response.body)
        .to be_json_eql(api_v3_paths.meeting_outcome(outcome.id).to_json)
        .at_path("_embedded/elements/0/_links/self/href")

      expect(last_response.body)
        .to be_json_eql(api_v3_paths.meeting_agenda_item(agenda_item.id).to_json)
        .at_path("_embedded/elements/0/_links/agendaItem/href")
    end

    context "with an agenda item from another meeting" do
      let(:other_meeting) { create(:meeting, project:, author: current_user) }
      let(:path) { api_v3_paths.meeting_agenda_item_outcomes(agenda_item.id, meeting_id: other_meeting.id) }

      it "returns 404" do
        expect(last_response).to have_http_status(:not_found)
      end
    end

    context "without view_meetings permission" do
      let(:permissions) { [] }

      it "returns 404" do
        expect(last_response).to have_http_status(:not_found)
      end
    end

    context "when an outcome is linked to a work package in an inaccessible project" do
      let(:private_project) { create(:project, public: false) }
      let(:private_work_package) { create(:work_package, project: private_project) }
      let!(:outcome) do
        create(:meeting_outcome,
               meeting_agenda_item: agenda_item,
               author: current_user,
               kind: :work_package,
               work_package: private_work_package,
               notes: nil)
      end

      it "does not embed the inaccessible work package" do
        expect(last_response.body).not_to have_json_path("_embedded/elements/0/_embedded/workPackage")
      end

      it "renders the work package link as undisclosed" do
        expect(last_response.body)
          .to be_json_eql(API::V3::URN_UNDISCLOSED.to_json)
          .at_path("_embedded/elements/0/_links/workPackage/href")
      end
    end
  end

  describe "POST /api/v3/meeting_outcomes" do
    let(:path) { api_v3_paths.meeting_outcomes }
    let(:body) do
      {
        kind: "information",
        notes: { raw: "Outcome created via API" },
        _links: {
          agendaItem: {
            href: api_v3_paths.meeting_agenda_item(agenda_item.id)
          }
        }
      }.to_json
    end

    subject(:response) { post path, body }

    it "responds with 201" do
      expect(response).to have_http_status(:created)
    end

    it "creates the outcome" do
      response
      expect(agenda_item.outcomes.find_by(notes: "Outcome created via API")).to be_present
    end

    it "returns the created outcome" do
      expect(response.body)
        .to be_json_eql("MeetingOutcome".to_json)
        .at_path("_type")

      expect(response.body)
        .to be_json_eql("Outcome created via API".to_json)
        .at_path("notes/raw")
    end

    context "without manage_outcomes permission" do
      let(:permissions) { %i[view_meetings] }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when creating a work package outcome" do
      let(:permissions) { %i[view_meetings manage_outcomes view_work_packages] }
      let(:work_package) { create(:work_package, project:) }
      let(:body) do
        {
          kind: "work_package",
          _links: {
            agendaItem: {
              href: api_v3_paths.meeting_agenda_item(agenda_item.id)
            },
            workPackage: {
              href: api_v3_paths.work_package(work_package.id)
            }
          }
        }.to_json
      end

      it "creates the linked outcome", :aggregate_failures do
        expect { response }.to change(agenda_item.outcomes, :count).by(1)
        expect(response).to have_http_status(:created)

        expect(response.body)
          .to be_json_eql(api_v3_paths.work_package(work_package.id).to_json)
                .at_path("_links/workPackage/href")

        created_outcome = agenda_item.outcomes.order(:id).last
        expect(created_outcome.kind).to eq("work_package")
        expect(created_outcome.work_package).to eq(work_package)
      end
    end

    context "when creating a work package outcome linked to an inaccessible work package" do
      let(:permissions) { %i[view_meetings manage_outcomes view_work_packages] }
      let(:private_project) { create(:project, public: false) }
      let(:private_work_package) { create(:work_package, project: private_project) }
      let(:body) do
        {
          kind: "work_package",
          _links: {
            agendaItem: {
              href: api_v3_paths.meeting_agenda_item(agenda_item.id)
            },
            workPackage: {
              href: api_v3_paths.work_package(private_work_package.id)
            }
          }
        }.to_json
      end

      it "does not create the outcome", :aggregate_failures do
        expect { response }.not_to change(agenda_item.outcomes, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /api/v3/meetings/:meeting_id/agenda_items/:agenda_item_id/outcomes/:id" do
    let(:path) do
      api_v3_paths.meeting_agenda_item_outcome(outcome.id,
                                               agenda_item_id: agenda_item.id,
                                               meeting_id: meeting.id)
    end

    before { get path }

    it "returns 200 and the outcome" do
      expect(last_response).to have_http_status(:ok)

      expect(last_response.body)
        .to be_json_eql("MeetingOutcome".to_json)
        .at_path("_type")

      expect(last_response.body)
        .to be_json_eql(outcome.id.to_json)
        .at_path("id")

      expect(last_response.body)
        .to be_json_eql(api_v3_paths.meeting_outcome(outcome.id).to_json)
        .at_path("_links/self/href")
    end

    context "with an outcome from another agenda item" do
      let(:other_agenda_item) { create(:meeting_agenda_item, meeting:, meeting_section: section, author: current_user) }
      let(:path) do
        api_v3_paths.meeting_agenda_item_outcome(outcome.id,
                                                 agenda_item_id: other_agenda_item.id,
                                                 meeting_id: meeting.id)
      end

      it "returns 404" do
        expect(last_response).to have_http_status(:not_found)
      end
    end

    context "when the outcome is linked to a work package in an inaccessible project" do
      let(:private_project) { create(:project, public: false) }
      let(:private_work_package) { create(:work_package, project: private_project) }
      let!(:outcome) do
        create(:meeting_outcome,
               meeting_agenda_item: agenda_item,
               author: current_user,
               kind: :work_package,
               work_package: private_work_package,
               notes: nil)
      end

      it "renders the work package link as undisclosed", :aggregate_failures do
        expect(last_response).to have_http_status(:ok)

        expect(last_response.body)
          .to be_json_eql(API::V3::URN_UNDISCLOSED.to_json)
          .at_path("_links/workPackage/href")

        expect(last_response.body).not_to have_json_path("_embedded/workPackage")
      end
    end
  end

  describe "GET /api/v3/meeting_outcomes/:id" do
    let(:path) { api_v3_paths.meeting_outcome(outcome.id) }

    before { get path }

    it "returns 200 and the outcome" do
      expect(last_response).to have_http_status(:ok)

      expect(last_response.body)
        .to be_json_eql("MeetingOutcome".to_json)
        .at_path("_type")

      expect(last_response.body)
        .to be_json_eql(api_v3_paths.meeting_outcome(outcome.id).to_json)
        .at_path("_links/self/href")
    end

    context "without view_meetings permission" do
      let(:permissions) { [] }

      it "returns 404" do
        expect(last_response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /api/v3/meeting_outcomes/:id" do
    let(:path) { api_v3_paths.meeting_outcome(outcome.id) }
    let(:body) do
      {
        notes: { raw: "Updated outcome" }
      }.to_json
    end

    subject(:response) { patch path, body }

    it "updates the outcome", :aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(outcome.reload.notes).to eq("Updated outcome")
    end

    context "without manage_outcomes permission" do
      let(:permissions) { %i[view_meetings] }

      it "returns 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /api/v3/meeting_outcomes/:id" do
    let(:path) { api_v3_paths.meeting_outcome(outcome.id) }

    before { delete path }

    subject { last_response }

    context "with required permissions" do
      it "deletes the outcome", :aggregate_failures do
        expect(subject.status).to eq 204
        expect(MeetingOutcome).not_to exist(outcome.id)
      end
    end

    context "without manage_outcomes permission" do
      let(:permissions) { %i[view_meetings] }

      it_behaves_like "unauthorized access"
    end
  end
end

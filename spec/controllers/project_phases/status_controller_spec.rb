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

require "rails_helper"

RSpec.describe ProjectPhases::StatusController do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:phase) { create(:project_phase, project:) }
  let(:params) { { status: "in_progress" } }
  let(:service_result) { ServiceResult.failure }
  let(:update_service) { instance_double(ProjectPhases::UpdateStatusService, call: service_result) }

  current_user { user }

  before do
    allow(ProjectPhases::UpdateStatusService)
      .to receive(:new)
            .with(user:, model: phase)
            .and_return(update_service)
  end

  describe "PUT #update" do
    let(:phase_id) { phase.id }

    before do
      put :update, params: { project_phase_id: phase_id, **params }, format: :turbo_stream
    end

    context "when the service call succeeds" do
      let(:service_result) { ServiceResult.success(result: phase) }

      it "passes the status on to the service" do
        expect(update_service).to have_received(:call).with(status: "in_progress")
      end

      it "reloads the sidebar frame and renders a flash", :aggregate_failures do
        expect(response).to be_successful
        expect(assigns(:project)).to eq project
        expect(response).to have_turbo_stream action: "turbo_frame_reload", target: "project-life-cycle-sidebar"
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
      end

      it "does not update individual components" do
        expect(response).not_to have_turbo_stream(action: "update")
      end
    end

    context "when the service call fails" do
      let(:service_result) { ServiceResult.failure(result: phase, message: "Not possible") }

      it "renders only a flash", :aggregate_failures do
        expect(response).not_to be_successful
        expect(response).to have_http_status :unprocessable_entity
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        expect(response).not_to have_turbo_stream(action: "turbo_frame_reload")
      end
    end

    context "without a status param" do
      let(:params) { {} }

      it "responds with 400 Bad Request without calling the service", :aggregate_failures do
        expect(response).to have_http_status :bad_request
        expect(update_service).not_to have_received(:call)
      end
    end

    context "with a phase that is not active in the project" do
      let(:phase) { create(:project_phase, :inactive, project:) }

      it "responds with 404 Not Found without calling the service", :aggregate_failures do
        expect(response).to have_http_status :not_found
        expect(update_service).not_to have_received(:call)
      end
    end

    context "with an unknown phase" do
      let(:phase_id) { 0 }

      it "responds with 404 Not Found" do
        expect(response).to have_http_status :not_found
      end
    end

    context "when the user may edit project phases" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i[view_project view_project_phases edit_project_phases] })
      end
      let(:service_result) { ServiceResult.success(result: phase) }

      it "is allowed" do
        expect(response).to be_successful
      end
    end

    context "when the user may only view project phases" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i[view_project view_project_phases] })
      end

      it "responds with 403 Forbidden without calling the service", :aggregate_failures do
        expect(response).to have_http_status :forbidden
        expect(update_service).not_to have_received(:call)
      end
    end

    context "when the user may edit the project but not its phases" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i[view_project view_project_phases edit_project] })
      end

      it "responds with 403 Forbidden without calling the service", :aggregate_failures do
        expect(response).to have_http_status :forbidden
        expect(update_service).not_to have_received(:call)
      end
    end
  end
end

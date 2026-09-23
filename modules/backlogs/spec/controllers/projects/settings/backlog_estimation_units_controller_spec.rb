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

RSpec.describe Projects::Settings::BacklogEstimationUnitsController do
  shared_let(:user) { create(:admin) }
  let(:project) { build_stubbed(:project, estimation_unit: "story_points") }

  current_user { user }

  before do
    visible_relation = instance_double(ActiveRecord::Relation)
    allow(Project).to receive(:visible).and_return(visible_relation)
    allow(visible_relation).to receive(:find).with(project.identifier).and_return(project)
  end

  context "when the feature flag is inactive", with_flag: { project_settings_estimation_unit: false } do
    describe "GET #show" do
      before { get :show, params: { project_id: project.identifier } }

      it "renders 404" do
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "PATCH #update" do
      before { patch :update, params: { project_id: project.identifier, project: { estimation_unit: "time" } } }

      it "renders 404" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "when the feature flag is active", with_flag: { project_settings_estimation_unit: true } do
    describe "GET #show" do
      before { get :show, params: { project_id: project.identifier } }

      it "renders successfully" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("projects/settings/backlog_estimation_units/show")
      end
    end

    describe "PATCH #update" do
      let(:service_result) { ServiceResult.success(result: project) }
      let(:update_service) { instance_double(Projects::UpdateService, call: service_result) }

      before do
        allow(Projects::UpdateService)
          .to receive(:new)
          .with(model: project, user:, contract_class: Backlogs::Projects::BacklogSettingsContract)
          .and_return(update_service)

        patch :update, params: { project_id: project.identifier, project: project_params }
      end

      context "when service call succeeds" do
        let(:project_params) { { estimation_unit: "time", name: "must_be_ignored" } }

        it "updates the estimation unit and redirects to show", :aggregate_failures do
          expect(update_service).to have_received(:call).with(
            ActionController::Parameters.new("estimation_unit" => "time").permit!
          )
          expect(response).to redirect_to(project_settings_backlog_estimation_unit_path(project))
          expect(flash[:notice]).to include I18n.t(:notice_successful_update)
        end
      end

      context "when service call fails" do
        let(:service_result) { ServiceResult.failure(result: project, message: "invalid setting") }
        let(:project_params) { { estimation_unit: "invalid_option" } }

        it "renders show with an error", :aggregate_failures do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template("projects/settings/backlog_estimation_units/show")
          expect(flash[:error]).to eq I18n.t(:notice_unsuccessful_update_with_reason, reason: "invalid setting")
        end
      end
    end
  end
end

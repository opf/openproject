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

RSpec.describe Projects::Settings::BacklogsController do
  shared_let(:user) { create(:admin) }

  current_user { user }

  before do
    visible_relation = instance_double(ActiveRecord::Relation)
    allow(Project).to receive(:visible).and_return(visible_relation)
    allow(visible_relation).to receive(:find).with(project.identifier).and_return(project)
  end

  describe "PATCH #update" do
    let(:project) { build_stubbed(:project) }
    let(:service_result) { ServiceResult.success(result: project) }
    let(:update_service) { instance_double(Projects::UpdateService, call: service_result) }

    before do
      allow(Projects::UpdateService)
        .to receive(:new)
        .with(model: project, user:, contract_class: Backlogs::Projects::BacklogsTypesAndStatusesContract)
        .and_return(update_service)

      patch :update, params: { project_id: project.identifier, project: project_params }
    end

    context "when service call succeeds" do
      let(:project_params) do
        {
          backlog_excluded_type_ids: ["3"],
          done_status_ids: %w[1 2],
          name: "must_be_ignored"
        }
      end

      it "updates backlogs type and status settings and redirects to show", :aggregate_failures do
        expect(update_service).to have_received(:call).with(
          ActionController::Parameters.new(
            "done_status_ids" => %w[1 2],
            "backlog_excluded_type_ids" => ["3"]
          ).permit!
        )

        expect(response).to redirect_to(project_settings_backlogs_path(project))
        expect(flash[:notice]).to include I18n.t(:notice_successful_update)
      end
    end

    context "when service call fails" do
      let(:service_result) { ServiceResult.failure(result: project, message: "invalid setting") }
      let(:project_params) do
        {
          backlog_excluded_type_ids: [],
          done_status_ids: ["999"]
        }
      end

      it "renders show with an error", :aggregate_failures do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template("projects/settings/backlogs/show")
        expect(flash[:error]).to eq I18n.t(:notice_unsuccessful_update_with_reason, reason: "invalid setting")
      end
    end

    context "when only hidden empty value is sent for an empty done_status_ids multi-select" do
      let(:project_params) do
        {
          done_status_ids: [""],
          backlog_excluded_type_ids: ["3"]
        }
      end

      it "passes through the Rails hidden-field payload", :aggregate_failures do
        expect(update_service).to have_received(:call).with(
          ActionController::Parameters.new(
            "done_status_ids" => [""],
            "backlog_excluded_type_ids" => ["3"]
          ).permit!
        )

        expect(response).to redirect_to(project_settings_backlogs_path(project))
        expect(flash[:notice]).to include I18n.t(:notice_successful_update)
      end
    end

    context "when duplicate ids are sent" do
      let(:project_params) do
        {
          backlog_excluded_type_ids: %w[3 3],
          done_status_ids: %w[2 2]
        }
      end

      it "deduplicates them before passing to the service", :aggregate_failures do
        expect(update_service).to have_received(:call).with(
          ActionController::Parameters.new(
            "done_status_ids" => ["2"],
            "backlog_excluded_type_ids" => ["3"]
          ).permit!
        )

        expect(response).to redirect_to(project_settings_backlogs_path(project))
        expect(flash[:notice]).to include I18n.t(:notice_successful_update)
      end
    end
  end
end

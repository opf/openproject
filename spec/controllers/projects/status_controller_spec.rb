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

require "rails_helper"

RSpec.describe Projects::StatusController do
  shared_let(:user) { create(:admin) }
  current_user { user }

  let(:project) { create(:project) }
  let(:service_result) { ServiceResult.failure }

  before do
    update_service = instance_double(Projects::UpdateService, call: service_result)

    allow(Projects::UpdateService)
      .to receive(:new)
            .with(user:, model: project)
            .and_return(update_service)
  end

  shared_examples_for "successful update" do
    context "with a text/html request" do
      let(:format) { nil }

      it "redirects back or to project show", :aggregate_failures do
        expect(response).to redirect_to project_path(project)
        expect(flash[:notice]).to eq I18n.t(:notice_successful_update)
      end
    end

    context "with a turbo stream request" do
      let(:format) { :turbo_stream }

      it "renders turbo streams updating Projects::StatusButtonComponent and flash action", :aggregate_failures do
        expect(response).to be_successful
        expect(assigns(:project)).to eq project
        expect(response).to have_turbo_stream action: "update", target: "projects-status-button-component-#{project.id}"
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
      end
    end
  end

  shared_examples_for "unsuccessful update" do
    context "with a text/html request" do
      let(:format) { nil }

      it "redirects back or to project show", :aggregate_failures do
        expect(response).to redirect_to project_path(project)
        expect(flash[:error]).to start_with I18n.t(:notice_unsuccessful_update_with_reason, reason: "")
      end
    end

    context "with a turbo stream request" do
      let(:format) { :turbo_stream }

      it "renders turbo stream flash action", :aggregate_failures do
        put :update, params: { project_id: project, status_code: :foo }, format: :turbo_stream

        expect(response).not_to be_successful
        expect(response).to have_http_status :unprocessable_entity
        expect(assigns(:project)).to eq project
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
      end
    end
  end

  describe "PUT #update" do
    before do
      put :update, params: { project_id: project, **params }, format:
    end

    context "with valid status_code param" do
      let(:params) { { status_code: :foo } }

      context "when service call succeeds" do
        let(:service_result) { ServiceResult.success(result: project) }

        it_behaves_like "successful update"

        context "when updating a status via turbo stream" do
          let(:format) { :turbo_stream }

          it "includes the default size of medium in the response by default" do
            parsed_response = Nokogiri::HTML.fragment(response.body)
            expect(parsed_response.css(".op-status-button .Button--medium")).to be_present
          end

          context "when a size parameter is given" do
            let(:params) { { status_code: :foo, status_size: "small" } }

            it "keeps the given size for the turbo stream update" do
              parsed_response = Nokogiri::HTML.fragment(response.body)
              expect(parsed_response.css(".op-status-button .Button--small")).to be_present
            end
          end
        end
      end

      context "when service call fails" do
        let(:service_result) { ServiceResult.failure(result: project, message: "") }

        it_behaves_like "unsuccessful update"
      end
    end

    context "with valid, empty status_code param" do
      let(:params) { { status_code: "" } }

      context "when service call succeeds" do
        let(:service_result) { ServiceResult.success(result: project) }

        it_behaves_like "successful update"
      end

      context "when service call fails" do
        let(:service_result) { ServiceResult.failure(result: project, message: "") }

        it_behaves_like "unsuccessful update"
      end
    end

    context "with invalid params" do
      let(:params) { { not_status_code: "something" } }

      context "with a text/html request" do
        let(:format) { nil }

        it "responds with 400 Bad Request status", :aggregate_failures do
          expect(response).not_to be_successful
          expect(response).to have_http_status :bad_request
        end
      end

      context "with a turbo stream request" do
        let(:format) { :turbo_stream }

        it "responds with 400 Bad Request status", :aggregate_failures do
          expect(response).not_to be_successful
          expect(response).to have_http_status :bad_request
        end
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      delete :destroy, params: { project_id: project }, format:
    end

    context "when service call succeeds" do
      let(:service_result) { ServiceResult.success(result: project) }

      it_behaves_like "successful update"
    end

    context "when service call fails" do
      let(:service_result) { ServiceResult.failure(result: project, message: "") }

      it_behaves_like "unsuccessful update"
    end
  end
end

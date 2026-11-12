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

require "spec_helper"

RSpec.describe "Enterprise Trials",
               :skip_csrf,
               type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:user) { create(:user) }

  subject do
    request
    response
  end

  before do
    login_as current_user
  end

  describe "GET /admin/enterprise_trial/trial_dialog" do
    let(:current_user) { admin }

    let(:request) { get trial_dialog_enterprise_trial_path, as: :turbo_stream }

    it "returns success" do
      expect(subject).to have_http_status(:ok)
    end

    context "when not logged in as admin" do
      let(:current_user) { user }

      it "returns forbidden" do
        expect(subject).to have_http_status(:forbidden)
      end
    end

    context "when not logged in" do
      let(:current_user) { User.anonymous }

      it "returns 401" do
        expect(subject).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /admin/enterprise_trial/request_resend" do
    let(:current_user) { admin }
    let!(:trial_key) { Token::EnterpriseTrialKey.create!(user: User.system) }

    let(:service_double) { instance_double(EnterpriseTrials::AugurResendConfirmationService) }
    let(:request) { post request_resend_enterprise_trial_path }

    before do
      allow(EnterpriseTrials::AugurResendConfirmationService)
        .to receive(:new)
        .with(trial_key)
        .and_return(service_double)
    end

    context "when resend service succeeds" do
      before do
        allow(service_double).to receive(:call)
      end

      it "calls the resend service and redirects to enterprise path" do
        expect(subject).to have_http_status(:see_other)
        expect(response).to redirect_to(enterprise_tokens_path)
        expect(service_double).to have_received(:call)
      end
    end

    context "when trial key does not exist" do
      before { trial_key.destroy! }

      it "renders an error" do
        expect(subject).to have_http_status(:not_found)
      end
    end

    context "when not logged in as admin" do
      let(:current_user) { user }

      it "returns forbidden" do
        expect(subject).to have_http_status(:forbidden)
      end
    end

    context "when not logged in" do
      let(:current_user) { User.anonymous }

      it "redirects to login" do
        expect(subject).to have_http_status(:found)
        expect(response).to redirect_to(signin_path(back_url: request_resend_enterprise_trial_url))
      end
    end
  end

  describe "POST /admin/enterprise_trial" do
    let(:current_user) { admin }
    let(:valid_params) do
      {
        enterprise_trial: {
          company: "Test Company",
          firstname: "John",
          lastname: "Doe",
          email: "john.doe@example.com",
          general_consent: "1",
          newsletter_consent: "1"
        }
      }
    end

    let(:request) { post enterprise_trial_path, as: :turbo_stream, params: params }

    context "with valid parameters" do
      let(:params) { valid_params }
      let(:service_result) { ServiceResult.success }
      let(:create_service) { instance_double(EnterpriseTrials::CreateService) }

      before do
        allow(EnterpriseTrials::CreateService)
          .to receive(:new)
          .with(user: admin)
          .and_return(create_service)
        allow(create_service).to receive(:call).and_return(service_result)
      end

      it "creates enterprise trial and redirects to enterprise path" do
        expect(subject).to have_http_status(:see_other)
        expect(response).to redirect_to(enterprise_tokens_path)
        expect(create_service).to have_received(:call).with(
          company: "Test Company",
          firstname: "John",
          lastname: "Doe",
          email: "john.doe@example.com",
          general_consent: "1",
          newsletter_consent: "1"
        )
      end
    end

    context "with invalid parameters" do
      let(:params) { valid_params }
      let(:trial_with_errors) { EnterpriseTrial.new(valid_params[:enterprise_trial]) }
      let(:service_result) { ServiceResult.failure(result: trial_with_errors) }
      let(:create_service) { instance_double(EnterpriseTrials::CreateService) }

      before do
        trial_with_errors.errors.add(:email, "is invalid")

        allow(EnterpriseTrials::CreateService)
          .to receive(:new)
          .with(user: admin)
          .and_return(create_service)
        allow(create_service).to receive(:call).and_return(service_result)
      end

      it "returns bad request and renders form with errors via turbo stream" do
        expect(subject).to have_http_status(:bad_request)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end

    context "with missing required parameters" do
      let(:params) do
        {
          enterprise_trial: {
            company: "Test Company"
          }
        }
      end

      it "handles the request without raising parameter errors" do
        expect { subject }.not_to raise_error
      end
    end

    context "when not logged in as admin" do
      let(:current_user) { user }
      let(:params) { valid_params }

      it "returns forbidden" do
        expect(subject).to have_http_status(:forbidden)
      end
    end

    context "when not logged in" do
      let(:params) { valid_params }
      let(:current_user) { User.anonymous }

      it "returns a 401" do
        expect(subject).to have_http_status(:unauthorized)
      end
    end
  end

  describe "parameter filtering" do
    let(:current_user) { admin }

    context "when unexpected parameters are provided" do
      let(:params) do
        {
          enterprise_trial: {
            company: "Test Company",
            firstname: "John",
            lastname: "Doe",
            email: "john.doe@example.com",
            general_consent: "1",
            newsletter_consent: "1",
            admin_flag: "true",
            sensitive_data: "should not be passed"
          }
        }
      end
      let(:service_result) { ServiceResult.success }
      let(:create_service) { instance_double(EnterpriseTrials::CreateService) }

      before do
        allow(EnterpriseTrials::CreateService)
          .to receive(:new)
          .with(user: admin)
          .and_return(create_service)
        allow(create_service).to receive(:call).and_return(service_result)
      end

      it "filters out unpermitted parameters" do
        post enterprise_trial_path, params: params

        expect(create_service).to have_received(:call).with(
          company: "Test Company",
          firstname: "John",
          lastname: "Doe",
          email: "john.doe@example.com",
          general_consent: "1",
          newsletter_consent: "1"
        )
      end
    end
  end
end

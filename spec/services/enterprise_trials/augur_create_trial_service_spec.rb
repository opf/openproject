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
require "webmock/rspec"

RSpec.describe EnterpriseTrials::AugurCreateTrialService, :webmock do
  let(:system_user) { User.system }
  let(:trial) { EnterpriseTrial.new(trial_attributes) }
  let(:trial_attributes) do
    {
      company: "Test Company",
      firstname: "John",
      lastname: "Doe",
      email: "john.doe@example.com",
      general_consent: true,
      newsletter_consent: false
    }
  end
  let(:service) { described_class.new(trial) }
  let(:augur_host) { "https://augur.example.org" }
  let(:trials_url) { "#{augur_host}/public/v1/trials" }

  before do
    allow(OpenProject::Configuration).to receive(:enterprise_trial_creation_host).and_return(augur_host)
  end

  context "when the request is successful" do
    let(:trial_id) { "1b6486b4-5a30-4042-8714-99d7c8e6b637" }
    let(:success_response) { { "id" => trial_id } }

    before do
      stub_request(:post, trials_url)
        .with(
          body: {
            company: "Test Company",
            first_name: "John",
            last_name: "Doe",
            email: "john.doe@example.com",
            newsletter_consent: false,
            general_consent: true,
            version: OpenProject::VERSION.to_semver,
            token_version: OpenProject::Token::VERSION,
            domain: Setting.host_name
          }.to_json
        )
        .to_return(status: 202, body: success_response.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "creates a trial key and returns success" do
      result = service.call

      expect(result).to be_success
      expect(result.result).to be_a(Token::EnterpriseTrialKey)
      expect(result.result.user_id).to eq(system_user.id)
      expect(result.result.value).to eq(trial_id)
      expect(result.result.data).to eq({ "email" => "john.doe@example.com" })

      expect(Token::EnterpriseTrialKey.count).to eq(1)
    end

    context "when the response is missing the trial ID" do
      let(:success_response) { { "id" => nil } }

      it "adds an error to the trial and returns failure" do
        result = service.call

        expect(result).to be_failure
        expect(result.result).to eq(trial)
        expect(trial.errors[:base]).to include("Trial could not be created (Missing trial ID)")
        expect(Token::EnterpriseTrialKey.count).to eq(0)
      end
    end

    context "when the response has an empty trial ID" do
      let(:success_response) { { "id" => "" } }

      it "adds an error to the trial and returns failure" do
        result = service.call

        expect(result).to be_failure
        expect(result.result).to eq(trial)
        expect(trial.errors[:base]).to include("Trial could not be created (Missing trial ID)")
        expect(Token::EnterpriseTrialKey.count).to eq(0)
      end
    end
  end

  context "when there are conflicts (422 status)" do
    context "when user already created a trial" do
      let(:conflict_response) do
        {
          "identifier" => "user_already_created_trial",
          "description" => "Each user can only create one trial."
        }
      end

      before do
        stub_request(:post, trials_url)
          .to_return(status: 422, body: conflict_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "adds an error to the email field and returns failure" do
        result = service.call

        expect(result).to be_failure
        expect(result.result).to eq(trial)
        expect(trial.errors[:email]).to be_present
        expect(Token::EnterpriseTrialKey.count).to eq(0)
      end
    end

    context "when domain is already taken" do
      let(:conflict_response) do
        {
          "identifier" => "domain_taken",
          "description" => "There can only be one active trial per domain."
        }
      end

      before do
        stub_request(:post, trials_url)
          .to_return(status: 422, body: conflict_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "adds an error to the domain field and returns failure" do
        result = service.call

        expect(result).to be_failure
        expect(result.result).to eq(trial)
        expect(trial.errors[:domain]).to be_present
        expect(Token::EnterpriseTrialKey.count).to eq(0)
      end
    end

    context "when email is invalid" do
      let(:conflict_response) do
        {
          "identifier" => "invalid_email",
          "description" => "The provided email address is invalid."
        }
      end

      before do
        stub_request(:post, trials_url)
          .to_return(status: 422, body: conflict_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "adds an error to the email field and returns failure" do
        result = service.call

        expect(result).to be_failure
        expect(result.result).to eq(trial)
        expect(trial.errors[:email]).to be_present
        expect(Token::EnterpriseTrialKey.count).to eq(0)
      end
    end

    context "when there's an unknown conflict" do
      let(:conflict_response) do
        {
          "identifier" => "unknown_error",
          "description" => "Some unknown error occurred."
        }
      end

      before do
        stub_request(:post, trials_url)
          .to_return(status: 422, body: conflict_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "adds a generic error and returns failure" do
        result = service.call

        expect(result).to be_failure
        expect(result.result).to eq(trial)
        expect(trial.errors[:base]).to include("Some unknown error occurred.")
        expect(Token::EnterpriseTrialKey.count).to eq(0)
      end
    end
  end

  context "when there are other errors" do
    context "when the response includes a description" do
      let(:error_response) do
        {
          "description" => "Token version is invalid"
        }
      end

      before do
        stub_request(:post, trials_url)
          .to_return(status: 409, body: error_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "adds the error description to the trial and returns failure" do
        result = service.call

        expect(result).to be_failure
        expect(result.result).to eq(trial)
        expect(trial.errors[:base]).to include("Token version is invalid")
        expect(Token::EnterpriseTrialKey.count).to eq(0)
      end
    end

    context "when there's a server error without description" do
      before do
        stub_request(:post, trials_url)
          .to_return(status: 500, body: "", headers: {})
      end

      it "adds a generic error with status and returns failure" do
        result = service.call

        expect(result).to be_failure
        expect(result.result).to eq(trial)
        expect(trial.errors[:base]).to be_present
        expect(Token::EnterpriseTrialKey.count).to eq(0)
      end
    end

    context "when the response is not valid JSON" do
      before do
        stub_request(:post, trials_url)
          .to_return(status: 400, body: "Invalid request", headers: {})
      end

      it "adds a generic error and returns failure" do
        result = service.call

        expect(result).to be_failure
        expect(result.result).to eq(trial)
        expect(trial.errors[:base]).to be_present
        expect(Token::EnterpriseTrialKey.count).to eq(0)
      end
    end
  end

  describe "request payload" do
    let(:trial_id) { "test-trial-id" }
    let(:success_response) { { "id" => trial_id } }

    it "sends the correct payload structure" do
      request_stub = stub_request(:post, trials_url)
        .with(
          body: {
            company: "Test Company",
            first_name: "John",
            last_name: "Doe",
            email: "john.doe@example.com",
            newsletter_consent: false,
            general_consent: true,
            version: OpenProject::VERSION.to_semver,
            token_version: OpenProject::Token::VERSION,
            domain: Setting.host_name
          }.to_json
        )
        .to_return(status: 202, body: success_response.to_json, headers: { "Content-Type" => "application/json" })

      service.call

      expect(request_stub).to have_been_requested
    end

    context "with newsletter consent enabled" do
      let(:trial_attributes) do
        {
          company: "Test Company",
          firstname: "John",
          lastname: "Doe",
          email: "john.doe@example.com",
          general_consent: true,
          newsletter_consent: true
        }
      end

      it "includes newsletter consent in the payload" do
        request_stub = stub_request(:post, trials_url)
          .with(
            body: hash_including(
              newsletter_consent: true
            )
          )
          .to_return(status: 202, body: success_response.to_json, headers: { "Content-Type" => "application/json" })

        service.call

        expect(request_stub).to have_been_requested
      end
    end
  end
end

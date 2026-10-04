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

RSpec.describe EnterpriseTrials::AugurLoadTrialService, :webmock do
  let(:system_user) { User.system }
  let(:trial_key) { Token::EnterpriseTrialKey.create!(user: system_user) }
  let(:service) { described_class.new(trial_key) }
  let(:augur_host) { "https://augur.example.org" }
  let(:trial_url) { "#{augur_host}/public/v1/trials/#{trial_key.value}" }

  before do
    allow(OpenProject::Configuration).to receive(:enterprise_trial_creation_host).and_return(augur_host)
    trial_key # ensure trial key is created
  end

  context "when a trial key exists" do
    context "when the request is successful" do
      context "when token is provided in the response" do
        let(:token_data) { { "token" => "valid-token-data" } }

        before do
          stub_request(:get, /#{Regexp.escape(augur_host)}\/public\/v1\/trials\/.*/)
            .to_return(status: 200, body: token_data.to_json, headers: { "Content-Type" => "application/json" })
        end

        it "creates an enterprise token and returns success" do
          token_double = instance_double(EnterpriseToken)
          allow(EnterpriseToken)
            .to receive(:new)
                  .with(encoded_token: "valid-token-data")
                  .and_return(token_double)
          allow(token_double).to receive(:save).and_return(true)

          result = service.call

          expect(result).to be_success
          expect(result.message).to eq(I18n.t("ee.trial.successfully_saved"))
          expect(Token::EnterpriseTrialKey).not_to exist(trial_key.id)

          expect(token_double).to have_received(:save)
        end

        context "when the token cannot be saved" do
          let(:enterprise_token) { instance_double(EnterpriseToken, save: false) }

          before do
            allow(EnterpriseToken).to receive(:new).and_return(enterprise_token)
          end

          it "returns a failure result" do
            result = service.call

            expect(result).to be_failure
            expect(result.result).to eq(enterprise_token)
            expect(Token::EnterpriseTrialKey).to exist(trial_key.id)
          end
        end
      end

      context "when token is not in the response" do
        let(:token_data) { { "token" => nil } }

        before do
          stub_request(:get, /#{Regexp.escape(augur_host)}\/public\/v1\/trials\/.*/)
            .to_return(status: 200, body: token_data.to_json, headers: { "Content-Type" => "application/json" })
        end

        it "returns success without creating a token" do
          allow(EnterpriseToken).to receive(:new)
          result = service.call

          expect(result).to be_success
          expect(result.message).to eq(I18n.t("ee.trial.already_retrieved"))
          expect(Token::EnterpriseTrialKey).not_to exist(trial_key.id)
          expect(EnterpriseToken).not_to have_received(:new)
        end
      end
    end

    context "when the trial is not found" do
      before do
        stub_request(:get, /#{Regexp.escape(augur_host)}\/public\/v1\/trials\/.*/)
          .to_return(status: 404, body: "", headers: {})
      end

      it "destroys the trial key and returns failure" do
        result = service.call

        expect(result).to be_failure
        expect(result.message).to eq(I18n.t("ee.trial.not_found"))
        expect(Token::EnterpriseTrialKey).not_to exist(trial_key.id)
      end
    end

    context "when the trial is pending confirmation" do
      before do
        stub_request(:get, /#{Regexp.escape(augur_host)}\/public\/v1\/trials\/.*/)
          .to_return(status: 422, body: "", headers: {})
      end

      it "returns a failure result with a message to wait" do
        result = service.call

        expect(result).to be_failure
        expect(result.message).to eq(I18n.t("ee.trial.wait_for_confirmation"))
        expect(Token::EnterpriseTrialKey).to exist(trial_key.id)
      end
    end

    context "when an unexpected error occurs" do
      before do
        stub_request(:get, /#{Regexp.escape(augur_host)}\/public\/v1\/trials\/.*/)
          .to_return(status: 500, body: "", headers: {})
      end

      it "logs the error and returns a generic failure message" do
        result = service.call

        expect(result).to be_failure
        expect(result.message).to eq(I18n.t("js.error.internal"))
        expect(Token::EnterpriseTrialKey).to exist(trial_key.id)
      end
    end
  end
end

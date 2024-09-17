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
require_module_spec_helper

RSpec.describe Storages::Peripherals::StorageInteraction::Authentication, :webmock do
  let(:user) { create(:user) }

  shared_examples_for "successful response" do |refreshed: false|
    it "must #{refreshed ? 'refresh token and ' : ''}return success" do
      result = described_class[auth_strategy].call(storage:, http_options:) { |http| make_request(http) }
      expect(result).to be_success
      expect(result.result).to eq("EXPECTED_RESULT")
    end
  end

  context "with a Nextcloud storage" do
    let(:storage) do
      create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
    end
    let(:request_url) { "#{storage.uri}ocs/v1.php/cloud/user" }
    let(:http_options) { { headers: { "OCS-APIRequest" => "true", "Accept" => "application/json" } } }

    context "with basic auth strategy" do
      let(:auth_strategy) { Storages::Peripherals::StorageInteraction::AuthenticationStrategies::BasicAuth.strategy }

      context "with valid credentials", vcr: "auth/nextcloud/basic_auth" do
        before do
          # Those values are only used to record the vcr cassette
          storage.username = "admin"
          storage.password = "admin"
        end

        it_behaves_like "successful response"
      end

      context "with empty username and password" do
        it "must return error" do
          result = described_class[auth_strategy].call(storage:, http_options:) { |http| make_request(http) }
          expect(result).to be_failure

          error = result.errors
          expect(error.code).to eq(:error)
          expect(error.data.source)
            .to be(Storages::Peripherals::StorageInteraction::AuthenticationStrategies::BasicAuth)
        end
      end

      context "with invalid username and/or password", vcr: "auth/nextcloud/basic_auth_password_invalid" do
        before do
          # Those values are only used to record the vcr cassette
          storage.username = "admin"
          storage.password = "YouShallNot(Multi)Pass"
        end

        it "must return unauthorized" do
          result = described_class[auth_strategy].call(storage:, http_options:) { |http| make_request(http) }
          expect(result).to be_failure

          error = result.errors
          expect(error.code).to eq(:unauthorized)
          expect(error.data.source).to be("EXECUTING_QUERY")
        end
      end
    end

    context "with user token strategy" do
      let(:auth_strategy) do
        Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
      end

      context "with incomplete storage configuration (missing oauth client)" do
        let(:storage) { create(:nextcloud_storage) }

        it "must return error" do
          result = described_class[auth_strategy].call(storage:, http_options:) { |http| make_request(http) }
          expect(result).to be_failure

          error = result.errors
          expect(error.code).to eq(:error)
          expect(error.data.source)
            .to be(Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken)
        end
      end

      context "with not existent oauth token" do
        let(:user_without_token) { create(:user) }
        let(:auth_strategy) do
          Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken
            .strategy
            .with_user(user_without_token)
        end

        it "must return unauthorized" do
          result = described_class[auth_strategy].call(storage:, http_options:) { |http| make_request(http) }
          expect(result).to be_failure

          error = result.errors
          expect(error.code).to eq(:unauthorized)
          expect(error.data.source)
            .to be(Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken)
        end
      end

      context "with invalid oauth refresh token", vcr: "auth/nextcloud/user_token_refresh_token_invalid" do
        before { storage }

        it "must return unauthorized" do
          result = described_class[auth_strategy].call(storage:, http_options:) { |http| make_request(http) }
          expect(result).to be_failure

          error = result.errors
          expect(error.code).to eq(:unauthorized)
          expect(error.data.source)
            .to be(Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken)
        end

        it "logs, retries once, raises exception if race condition happens" do
          token = OAuthClientToken.last
          strategy = described_class[auth_strategy]

          allow(Rails.logger).to receive(:error)
          allow(strategy).to receive(:current_token).and_return(ServiceResult.success(result: token))
          allow(token).to receive(:destroy).and_raise(ActiveRecord::StaleObjectError).twice

          expect do
            strategy.call(storage:, http_options:) { |http| make_request(http) }
          end.to raise_error(ActiveRecord::StaleObjectError)

          expect(Rails.logger)
            .to have_received(:error)
            .with("#<ActiveRecord::StaleObjectError: Stale object error.> happend for User ##{user.id} #{user.name}").once
        end
      end

      context "with invalid oauth access token", vcr: "auth/nextcloud/user_token_access_token_invalid" do
        it_behaves_like "successful response", refreshed: true
      end
    end
  end

  context "with a OneDrive/SharePoint storage" do
    let(:storage) { create(:sharepoint_dev_drive_storage, oauth_client_token_user: user) }
    let(:http_options) { {} }

    context "with client credentials strategy" do
      let(:request_url) { "#{storage.uri}v1.0/drives" }
      let(:auth_strategy) do
        Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthClientCredentials.strategy
      end

      context "with valid oauth credentials", vcr: "auth/one_drive/client_credentials" do
        it_behaves_like "successful response"
      end

      context "with invalid client secret", vcr: "auth/one_drive/client_credentials_invalid_client_secret" do
        it "must return unauthorized" do
          result = described_class[auth_strategy].call(storage:) { |http| make_request(http) }
          expect(result).to be_failure

          error = result.errors
          expect(error.code).to eq(:unauthorized)
          expect(error.data.source)
            .to be(Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthClientCredentials)
        end
      end

      context "with invalid client id", vcr: "auth/one_drive/client_credentials_invalid_client_id" do
        it "must return unauthorized" do
          result = described_class[auth_strategy].call(storage:) { |http| make_request(http) }
          expect(result).to be_failure

          error = result.errors
          expect(error.code).to eq(:unauthorized)
          expect(error.data.source)
            .to be(Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthClientCredentials)
        end
      end
    end

    context "with user token strategy" do
      let(:request_url) { "#{storage.uri}v1.0/me" }
      let(:auth_strategy) do
        Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
      end

      context "with valid access token", vcr: "auth/one_drive/user_token" do
        it_behaves_like "successful response"
      end

      context "with incomplete storage configuration (missing oauth client)" do
        let(:storage) { create(:one_drive_storage) }

        it "must return error" do
          result = described_class[auth_strategy].call(storage:) { |http| make_request(http) }
          expect(result).to be_failure

          error = result.errors
          expect(error.code).to eq(:error)
          expect(error.data.source)
            .to be(Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken)
        end
      end

      context "with not existent oauth token" do
        let(:user_without_token) { create(:user) }
        let(:auth_strategy) do
          Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken
            .strategy
            .with_user(user_without_token)
        end

        it "must return unauthorized" do
          result = described_class[auth_strategy].call(storage:) { |http| make_request(http) }
          expect(result).to be_failure

          error = result.errors
          expect(error.code).to eq(:unauthorized)
          expect(error.data.source)
            .to be(Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken)
        end
      end

      context "with invalid oauth refresh token", vcr: "auth/one_drive/user_token_refresh_token_invalid" do
        it "must return unauthorized" do
          result = described_class[auth_strategy].call(storage:) { |http| make_request(http) }
          expect(result).to be_failure

          error = result.errors
          expect(error.code).to eq(:unauthorized)
          expect(error.data.source)
            .to be(Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken)
        end
      end

      context "with invalid oauth access token", vcr: "auth/one_drive/user_token_access_token_invalid" do
        it_behaves_like "successful response", refreshed: true
      end
    end
  end

  private

  def make_request(http)
    handle_response http.get(request_url)
  end

  def handle_response(response)
    case response
    in { status: 200..299 }
      ServiceResult.success(result: "EXPECTED_RESULT")
    in { status: 401 }
      error(:unauthorized)
    in { status: 403 }
      error(:forbidden)
    in { status: 404 }
      error(:not_found)
    else
      error(:error)
    end
  end

  def error(code)
    data = Storages::StorageErrorData.new(source: "EXECUTING_QUERY")
    ServiceResult.failure(result: code, errors: Storages::StorageError.new(code:, data:))
  end
end

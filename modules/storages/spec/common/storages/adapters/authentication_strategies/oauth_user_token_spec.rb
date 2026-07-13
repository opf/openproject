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

module Storages
  module Adapters
    module AuthenticationStrategies
      RSpec.describe OAuthUserToken, :disable_ssrf_filter, :webmock do
        let(:user) { create(:user) }
        let(:storage) do
          create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
        end
        let(:request_url) { "#{storage.uri}ocs/v1.php/cloud/user" }
        let(:http_options) { { headers: { "OCS-APIRequest" => "true", "Accept" => "application/json" } } }
        let(:strategy_data) { Input::Strategy.build(user:, key: :oauth_user_token) }

        subject(:Authentication) { described_class }

        shared_examples_for "successful response" do |refreshed: false|
          it "must #{'refresh token and ' if refreshed}return success" do
            result = Authentication[strategy_data].call(storage:) { |http| make_request(http) }
            expect(result).to be_success
            expect(result.value!).to eq("EXPECTED_RESULT")
          end
        end

        context "with incomplete storage configuration (missing oauth client)" do
          let(:storage) { create(:nextcloud_storage) }

          it "must return error" do
            result = Authentication[strategy_data].call(storage:) { |http| make_request(http) }
            expect(result).to be_failure

            error = result.failure
            expect(error.code).to eq(:missing_oauth_client)
            expect(error.source).to be(described_class)
          end
        end

        context "with not existent oauth token" do
          let(:user_without_token) { create(:user) }
          let(:strategy_data) { Input::Strategy.build(user: user_without_token, key: :oauth_user_token) }

          it "must return unauthorized" do
            result = Authentication[strategy_data].call(storage:, http_options:) { |http| make_request(http) }
            expect(result).to be_failure

            error = result.failure
            expect(error.code).to eq(:missing_token)
            expect(error.source).to be(described_class)
          end
        end

        context "with invalid oauth refresh token", vcr: "auth/nextcloud/user_token_refresh_token_invalid" do
          before { storage }

          it "must return unauthorized" do
            result = Authentication[strategy_data].call(storage:, http_options:) { |http| make_request(http) }
            expect(result).to be_failure

            error = result.failure
            expect(error.code).to eq(:unauthorized)
            expect(error.source).to be(described_class)
          end

          it "logs, retries once, raises exception if race condition happens" do
            token = OAuthClientToken.last
            strategy = Authentication[strategy_data]

            allow(Rails.logger).to receive(:error)
            allow(strategy).to receive(:current_token).and_return(Success(token))
            allow(token).to receive(:destroy!).and_raise(ActiveRecord::StaleObjectError).twice

            expect do
              strategy.call(storage:, http_options:) { |http| make_request(http) }
            end.to raise_error(ActiveRecord::StaleObjectError)

            expect(Rails.logger).to have_received(:error).with(/User ##{user.id} #{user.name}/).once
          end
        end

        context "with invalid oauth access token" do
          it "must refresh token and return success", vcr: "auth/nextcloud/refresh_token" do
            token = OAuthClientToken.where(oauth_client_id: storage.oauth_client.id).last
            original_access_token = token&.access_token
            token&.update!(access_token: "NOT_A_VALID_TOKEN")

            result = Authentication[strategy_data].call(storage:) { |http| make_request(http) }

            expect(result).to be_success
            expect(result.value!).to eq("EXPECTED_RESULT")
            expect(original_access_token).not_to eq(token&.reload&.access_token)
          end
        end

        context "with valid access token", vcr: "auth/one_drive/user_token" do
          let(:request_url) { "#{storage.uri}v1.0/me" }
          let(:storage) { create(:one_drive_sandbox_storage, oauth_client_token_user: user) }

          it_behaves_like "successful response"
        end

        private

        def make_request(http) = handle_response(http.get(request_url))

        def handle_response(response)
          case response
          in { status: 200..299 }
            Success("EXPECTED_RESULT")
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
          Failure(Results::Error.new(source: "EXECUTING_QUERY", code:))
        end
      end
    end
  end
end

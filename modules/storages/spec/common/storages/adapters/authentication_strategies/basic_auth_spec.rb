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
      RSpec.describe BasicAuth, :disable_ssrf_filter, :webmock do
        let(:user) { create(:user) }

        let(:storage) do
          create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
        end

        let(:request_url) { "#{storage.uri}ocs/v1.php/cloud/user" }
        let(:http_options) { { headers: { "OCS-APIRequest" => "true", "Accept" => "application/json" } } }

        let(:strategy_data) { Input::Strategy.build(key: :basic_auth) }

        context "with valid credentials", vcr: "auth/nextcloud/basic_auth" do
          before do
            storage.username = "admin"
            storage.password = "admin"
          end

          it "successful response" do
            result = Authentication[strategy_data].call(storage:, http_options:) { |http| make_request(http) }
            expect(result).to be_success
            expect(result.value!).to eq("EXPECTED_RESULT")
          end
        end

        context "with empty username and password" do
          before do
            storage.username = ""
            storage.password = ""
          end

          it "must return error" do
            result = Authentication[strategy_data].call(storage:, http_options:) { |http| make_request(http) }
            expect(result).to be_failure

            error = result.failure
            expect(error.code).to eq(:missing_credentials)
            expect(error.source).to be(described_class)
          end
        end

        context "with invalid username and/or password", vcr: "auth/nextcloud/basic_auth_password_invalid" do
          before do
            storage.username = "admin"
            storage.password = "YouShallNot(Multi)Pass"
          end

          it "must return unauthorized" do
            result = Authentication[strategy_data].call(storage:, http_options:) { |http| make_request(http) }
            expect(result).to be_failure

            error = result.failure
            expect(error.code).to eq(:unauthorized)
            expect(error.source).to eq("EXECUTING_QUERY")
          end
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

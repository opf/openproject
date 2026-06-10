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
      RSpec.describe OAuthClientCredentials, :disable_ssrf_filter, :webmock do
        let(:user) { create(:user) }
        let(:storage) { create(:one_drive_sandbox_storage, oauth_client_token_user: user) }

        let(:strategy_data) { Input::Strategy.build(key: :oauth_client_credentials, use_cache: false) }
        let(:request_url) { "#{storage.uri}v1.0/drives" }

        context "with valid oauth credentials", vcr: "auth/one_drive/client_credentials" do
          it "return success" do
            result = Authentication[strategy_data].call(storage:) { make_request(it) }

            expect(result).to be_success
            expect(result.value!).to eq("EXPECTED_RESULT")
          end

          it "caches the token if use_cache is true" do
            strategy_data = Input::Strategy.build(key: :oauth_client_credentials, use_cache: true)
            Authentication[strategy_data].call(storage:) { make_request(it) }

            cache_key = described_class::TOKEN_CACHE_KEY % storage.id
            expect(OpenProject::ConfidentialCache.read(cache_key)).not_to be_nil
          end
        end

        context "with invalid client secret", vcr: "auth/one_drive/client_credentials_invalid_client_secret" do
          it "must return unauthorized" do
            result = Authentication[strategy_data].call(storage:) { make_request(it) }
            expect(result).to be_failure

            error = result.failure
            expect(error.code).to eq(:unauthorized)
            expect(error.source).to eq(described_class)
          end
        end

        context "with invalid client id", vcr: "auth/one_drive/client_credentials_invalid_client_id" do
          it "must return unauthorized" do
            result = Authentication[strategy_data].call(storage:) { make_request(it) }
            expect(result).to be_failure

            error = result.failure
            expect(error.code).to eq(:unauthorized)
            expect(error.source).to eq(described_class)
          end
        end

        private

        def make_request(http)
          handle_response(http.get(request_url))
        end

        def handle_response(response)
          case response
          in { status: 200..299 }
            Success("EXPECTED_RESULT")
          in { status: 401 }
            error(:unauthorized)
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

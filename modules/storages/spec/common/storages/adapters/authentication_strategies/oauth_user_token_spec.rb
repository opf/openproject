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
      RSpec.describe OAuthUserToken, :webmock do
        subject(:Authentication) { described_class }

        let(:user) { create(:user) }
        let(:storage) { create(:one_drive_sandbox_storage, oauth_client_token_user: user) }
        let(:strategy_data) { Input::Strategy.build(user:, key: :oauth_user_token) }

        let(:token_fetcher) { instance_double(OAuthClients::TokenFetcher, access_token_for: Success(access_token)) }
        let(:access_token) { "you-are-allowed-to-enter" }

        before do
          allow(OAuthClients::TokenFetcher).to receive(:new).with(user:).and_return(token_fetcher)
        end

        context "with incomplete storage configuration (missing oauth client)" do
          let(:storage) { create(:nextcloud_storage) }

          it "must return error" do
            result = Authentication[strategy_data].call(storage:) { Success("should not've been called") }
            expect(result).to be_failure

            error = result.failure
            expect(error.code).to eq(:missing_oauth_client)
            expect(error.source).to be(described_class)
          end
        end

        context "when token fetcher returns an error" do
          let(:token_fetcher) do
            instance_double(OAuthClients::TokenFetcher, access_token_for: Failure(SimpleError.new(
                                                                                    source: OAuthClients::TokenFetcher,
                                                                                    code: :token_fetcher_error
                                                                                  )))
          end

          it "returns that error" do
            result = Authentication[strategy_data].call(storage:) { Success("should not've been called") }
            expect(result).to be_failure

            error = result.failure
            expect(error.code).to eq(:token_fetcher_error)
            expect(error.source).to be(OAuthClients::TokenFetcher)
          end
        end

        context "when token fetcher returns an access token" do
          it "returns whatever the block returned" do
            result = Authentication[strategy_data].call(storage:) { Success("The result") }
            expect(result).to be_success
            expect(result.value!).to eq("The result")
          end

          it "passes an HTTPX session that sets the access token as Bearer token" do
            stub_request(:get, "https://example.com")
            Authentication[strategy_data].call(storage:) do |http|
              http.get("https://example.com")
            end
            expect(WebMock).to have_requested(:get, "https://example.com")
              .with(headers: { Authorization => "Bearer #{access_token}" })
          end

          it "correctly calls the token fetcher" do
            Authentication[strategy_data].call(storage:) { Success("The result") }

            expect(OAuthClients::TokenFetcher).to have_received(:new).with(user:)
            expect(token_fetcher).to have_received(:access_token_for).with(oauth_client: storage.oauth_client)
          end
        end
      end
    end
  end
end

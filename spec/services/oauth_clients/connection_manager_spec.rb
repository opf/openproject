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

RSpec.describe OAuthClients::ConnectionManager, :webmock, type: :model do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }

  let(:host) { "https://example.org" }
  let(:storage) { create(:nextcloud_storage, :with_oauth_client, host: "#{host}/") }
  let(:oauth_client) { storage.oauth_client }
  let(:configuration) { storage.oauth_configuration }

  let(:scope) { [:all] } # OAuth2 resources to access, specific to provider
  let(:oauth_client_token) { create(:oauth_client_token, oauth_client:, user:) }

  let(:instance) { described_class.new(user:, configuration:) }

  # In the second step the Authorization Server (Nextcloud) redirects
  # to a "callback" endpoint on the OAuth2 client (OpenProject):
  # https://<openproject-server>/oauth_clients/8/callback?state=&code=7kRGJ...jG3KZ
  # This callback code basically just calls `code_to_token(code)`.
  # The callback endpoint calls `code_to_token(code)` with the code
  # received and exchanges the code for a bearer+refresh token
  # using a HTTP request.
  describe "#code_to_token", :webmock do
    let(:code) { "7kRGJ...jG3KZ" }

    subject { instance.code_to_token(code) }

    context "with happy path", :storage_server_helpers do
      before do
        # Simulate a successful authorization returning the tokens
        response_body = {
          access_token: "yjTDZ...RYvRH",
          token_type: "Bearer",
          expires_in: 3600,
          refresh_token: "UwFp...1FROJ",
          user_id: "admin"
        }.to_json
        stub_request(:any, File.join(host, "/index.php/apps/oauth2/api/v1/token"))
          .to_return(status: 200, body: response_body, headers: { "content-type" => "application/json; charset=utf-8" })

        stub_nextcloud_user_query(host)
      end

      it "returns a valid ClientToken object and issues an appropriate event" do
        allow(OpenProject::Notifications)
          .to receive(:send).with(OpenProject::Events::REMOTE_IDENTITY_CREATED, integration: storage).once

        expect(subject.success).to be_truthy
        expect(subject.result).to be_a OAuthClientToken
      end

      it "fills in the origin_user_id" do
        expect { subject }.to change(OAuthClientToken, :count).by(1).and(change(RemoteIdentity, :count).by(1))
        last_token = RemoteIdentity.find_by!(user:, auth_source: oauth_client)

        expect(last_token.origin_user_id).to eq("admin")
      end
    end

    context "with known error" do
      before do
        stub_request(:post, File.join(host, "/index.php/apps/oauth2/api/v1/token"))
          .to_return(status: 400,
                     body: { error: error_message }.to_json,
                     headers: { "content-type" => "application/json; charset=utf-8" })
      end

      shared_examples "OAuth2 error response" do
        it "returns a specific error message" do
          expect(subject.success).to be_falsy
          expect(subject.result).to eq(:bad_request)
          expect(subject.error_payload[:error]).to eq(error_message)
        end
      end

      context "when 'invalid_request'" do
        let(:error_message) { "invalid_request" }

        it_behaves_like "OAuth2 error response"
      end

      context "when 'invalid_grant'" do
        let(:error_message) { "invalid_grant" }

        it_behaves_like "OAuth2 error response"
      end
    end

    context "with unknown reply" do
      before do
        stub_request(:post, File.join(host, "/index.php/apps/oauth2/api/v1/token"))
          .to_return(status: 400,
                     body: { error: "invalid_requesttt" }.to_json,
                     headers: { "content-type" => "application/json; charset=utf-8" })
      end

      it "returns an error wrapping the unknown response" do
        expect(subject.success).to be_falsy
        expect(subject.result).to eq(:bad_request)
        expect(subject.error_payload[:error]).to eq("invalid_requesttt")
        expect(subject.error_source).to be_a(described_class)
        expect(subject.errors.log_message).to include I18n.t("oauth_client.errors.oauth_returned_error")
      end
    end

    context "with reply including JSON syntax error" do
      before do
        stub_request(:post, File.join(host, "/index.php/apps/oauth2/api/v1/token"))
          .to_return(
            status: 400,
            headers: { "Content-Type" => "application/json; charset=utf-8" },
            body: "some: very, invalid> <json}"
          )
      end

      it "returns an error wrapping the parsing error" do
        expect(subject.success).to be_falsy
        expect(subject.result).to eq(:internal_server_error)
        expect(subject.error_payload.class).to be(Faraday::ParsingError)
        expect(subject.error_source).to be_a(described_class)
        expect(subject.errors.log_message).to include I18n.t("oauth_client.errors.oauth_returned_http_error")
      end
    end

    context "with 500 reply without body" do
      before do
        stub_request(:post, File.join(host, "/index.php/apps/oauth2/api/v1/token"))
          .to_return(status: 500)
      end

      it "returns an error wrapping the empty error" do
        expect(subject.success).to be_falsy
        expect(subject.result).to eq(:bad_request)
        expect(subject.error_payload[:error]).to eq("Unknown")
      end
    end

    context "when something is wrong with connection" do
      before do
        stub_request(:post, File.join(host, "/index.php/apps/oauth2/api/v1/token")).to_raise(Faraday::ConnectionFailed)
      end

      it "returns an error wrapping the server error" do
        expect(subject.success).to be_falsy
        expect(subject.result).to eq(:internal_server_error)
        expect(subject.error_payload.class).to be(Faraday::ConnectionFailed)
        expect(subject.error_source).to be_a(described_class)
        expect(subject.errors.log_message).to include I18n.t("oauth_client.errors.oauth_returned_http_error")
      end
    end

    context "when something is wrong with SSL" do
      before do
        stub_request(:post, File.join(host, "/index.php/apps/oauth2/api/v1/token")).to_raise(Faraday::SSLError)
      end

      it "returns an error wrapping the server error" do
        expect(subject.success).to be_falsy
        expect(subject.result).to eq(:internal_server_error)
        expect(subject.error_payload.class).to be(Faraday::SSLError)
        expect(subject.error_source).to be_a(described_class)
        expect(subject.errors.log_message).to include I18n.t("oauth_client.errors.oauth_returned_http_error")
      end
    end

    context "with timeout returns internal error" do
      before do
        stub_request(:post, File.join(host, "/index.php/apps/oauth2/api/v1/token")).to_timeout
      end

      it "returns an error wrapping the server timeout" do
        expect(subject.success).to be_falsy
        expect(subject.result).to eq(:internal_server_error)
        expect(subject.error_payload.class).to be(Faraday::ConnectionFailed)
        expect(subject.error_source).to be_a(described_class)
        expect(subject.errors.log_message).to include I18n.t("oauth_client.errors.oauth_returned_http_error")
      end
    end
  end
end

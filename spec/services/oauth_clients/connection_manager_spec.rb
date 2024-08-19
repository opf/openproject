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

  # The first step in the OAuth2 flow is to produce a URL for the
  # user to authenticate and authorize access at the OAuth2 provider
  # (Nextcloud).
  describe "#get_access_token" do
    subject { instance.get_access_token }

    context "with no OAuthClientToken present" do
      it "returns a redirection URL" do
        expect(subject.success).to be_falsy
        expect(subject.result).to be_a String
        # Details of string are tested above in section #get_authorization_uri
      end
    end

    context "with no OAuthClientToken present and state parameters" do
      subject { instance.get_access_token(state: "some_state") }

      it "returns the redirect URL" do
        allow(configuration).to receive(:scope).and_return(%w[email])

        expect(subject.success).to be_falsy
        expect(subject.result).to be_a String
        expect(subject.result).to include oauth_client.integration.host
        expect(subject.result).to include "&state=some_state"
        expect(subject.result).to include "&scope=email"
      end
    end

    context "with an OAuthClientToken present" do
      before do
        oauth_client_token
      end

      it "returns the OAuthClientToken" do
        expect(subject).to be_truthy
        expect(subject.result).to be_a OAuthClientToken # The one and only...
        expect(subject.result).to eql oauth_client_token
      end
    end
  end

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

    context "with happy path" do
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
      end

      it "returns a valid ClientToken object and issues an appropriate event" do
        allow(OpenProject::Notifications)
          .to receive(:send).with(OpenProject::Events::REMOTE_IDENTITY_CREATED, integration: storage).once

        expect(subject.success).to be_truthy
        expect(subject.result).to be_a OAuthClientToken
      end

      it "fills in the origin_user_id" do
        expect { subject }.to change(OAuthClientToken, :count).by(1).and(change(RemoteIdentity, :count).by(1))
        last_token = RemoteIdentity.find_by!(user:, oauth_client:)

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

  describe "#refresh_token" do
    subject { instance.refresh_token }

    context "without existing OAuthClientToken" do
      it "returns an error message" do
        expect(subject.success).to be_falsy
        expect(subject.result).to eq(:error)
        expect(subject.errors.log_message)
          .to include I18n.t("oauth_client.errors.refresh_token_called_without_existing_token")
      end
    end

    context "with existing OAuthClientToken" do
      before { oauth_client_token }

      context "when token is stale" do
        before do
          oauth_client_token.update_columns(updated_at: 1.day.ago)
        end

        context "with successful response from OAuth2 provider (happy path)" do
          before do
            # Simulate a successful authorization returning the tokens
            response_body = {
              access_token: "xyjTDZ...RYvRH",
              token_type: "Bearer",
              expires_in: 3601,
              refresh_token: "xUwFp...1FROJ",
              user_id: "admin"
            }.to_json
            stub_request(:any, File.join(host, "/index.php/apps/oauth2/api/v1/token"))
              .to_return(status: 200, body: response_body, headers: { "content-type" => "application/json; charset=utf-8" })
          end

          it "returns a valid ClientToken object", :webmock do
            expect(subject.success).to be_truthy
            expect(subject.result).to be_a OAuthClientToken
            expect(subject.result.access_token).to eq("xyjTDZ...RYvRH")

            expect(subject.result.expires_in).to be(3601)
          end
        end

        context "with invalid access_token data" do
          before do
            # Simulate a token too long
            response_body = {
              access_token: nil, # will fail model validation
              token_type: "Bearer",
              expires_in: 3601,
              refresh_token: "xUwFp...1FROJ",
              user_id: "admin"
            }.to_json
            stub_request(:any, File.join(host, "/index.php/apps/oauth2/api/v1/token"))
              .to_return(status: 200, body: response_body, headers: { "content-type" => "application/json; charset=utf-8" })
          end

          it "returns dependent error from model validation", :webmock do
            expect(subject.success).to be_falsy
            expect(subject.result).to eq(:error)
            expect(subject.error_payload.class).to be(AttrRequired::AttrMissing)
            expect(subject.error_payload.message).to include("'access_token' required.")
          end
        end

        context "with server error from OAuth2 provider" do
          before do
            stub_request(:any, File.join(host, "/index.php/apps/oauth2/api/v1/token"))
              .to_return(status: 400,
                         body: { error: "invalid_request" }.to_json,
                         headers: { "content-type" => "application/json; charset=utf-8" })
          end

          it "returns a server error", :webmock do
            expect(subject.success).to be_falsy
            expect(subject.result).to eq(:bad_request)
            expect(subject.error_payload[:error]).to eq("invalid_request")
          end
        end

        context "with successful response but invalid data" do
          before do
            # Simulate timeout
            stub_request(:any, File.join(host, "/index.php/apps/oauth2/api/v1/token"))
              .to_timeout
          end

          it "returns an error wrapping a timeout", :webmock do
            expect(subject.success).to be_falsy
            expect(subject.result).to eq(:internal_server_error)
            expect(subject.error_payload.class).to be(Faraday::ConnectionFailed)
            expect(subject.error_source).to be_a(described_class)
            expect(subject.errors.log_message).to include("Faraday::ConnectionFailed: execution expired")
          end
        end

        context "with parallel requests for refresh", :aggregate_failures do
          after do
            Storages::Storage.destroy_all
            User.destroy_all
            OAuthClientToken.destroy_all
            OAuthClient.destroy_all
          end

          it "requests token only once and other thread uses new token" do
            response_body1 = {
              access_token: "xyjTDZ...RYvRH",
              token_type: "Bearer",
              expires_in: 3601,
              refresh_token: "xUwFp...1FROJ",
              user_id: "admin"
            }
            response_body2 = response_body1.dup
            response_body2[:access_token] = "differ...RYvRH"
            request_url = File.join(host, "/index.php/apps/oauth2/api/v1/token")
            stub_request(:any, request_url).to_return(
              { status: 200, body: response_body1.to_json, headers: { "content-type" => "application/json; charset=utf-8" } },
              { status: 200, body: response_body2.to_json, headers: { "content-type" => "application/json; charset=utf-8" } }
            )

            result1 = nil
            result2 = nil
            thread1 = Thread.new do
              ApplicationRecord.connection_pool.with_connection do
                result1 = described_class.new(user:, configuration: storage.oauth_configuration).refresh_token.result
              end
            end
            thread2 = Thread.new do
              ApplicationRecord.connection_pool.with_connection do
                result2 = described_class.new(user:, configuration: storage.oauth_configuration).refresh_token.result
              end
            end
            thread1.join
            thread2.join

            expect(result1.access_token).to eq(response_body1[:access_token])
            expect(result2.access_token).to eq(response_body1[:access_token])
            expect(WebMock).to have_requested(:any, request_url).once
          end

          it "requests token refresh twice if enough time passes between requests" do
            stub_const("OAuthClients::ConnectionManager::TOKEN_IS_FRESH_DURATION", 2.seconds)
            response_body1 = {
              access_token: "xyjTDZ...RYvRH",
              token_type: "Bearer",
              expires_in: 3601,
              refresh_token: "xUwFp...1FROJ",
              user_id: "admin"
            }
            response_body2 = response_body1.dup
            response_body2[:access_token] = "differ...RYvRH"
            request_url = File.join(host, "/index.php/apps/oauth2/api/v1/token")
            headers = { "content-type" => "application/json; charset=utf-8" }
            stub_request(:any, request_url)
              .to_return(status: 200, body: response_body1.to_json, headers:).then
              .to_return(status: 200, body: response_body2.to_json, headers:)

            result1 = nil
            result2 = nil
            thread1 = Thread.new do
              ApplicationRecord.connection_pool.with_connection do
                sleep(3)
                result1 = described_class.new(user:, configuration: storage.oauth_configuration).refresh_token.result
              end
            end
            thread2 = Thread.new do
              ApplicationRecord.connection_pool.with_connection do
                result2 = described_class.new(user:, configuration: storage.oauth_configuration).refresh_token.result
              end
            end
            thread1.join
            thread2.join

            expect([result1.access_token,
                    result2.access_token]).to contain_exactly(response_body1[:access_token], response_body2[:access_token])
            expect(WebMock).to have_requested(:any, request_url).twice
          end
        end
      end

      context "when token is fresh" do
        it "does not send refresh request and respond with existing token", :webmock do
          expect(subject.success).to be_truthy
          expect(subject.result).to eq(oauth_client_token)
          expect { subject }.not_to change(oauth_client_token, :access_token)
        end
      end
    end
  end

  describe "#request_with_token_refresh" do
    let(:yield_service_result) { ServiceResult.success }
    let(:refresh_service_result) { ServiceResult.success }

    subject do
      instance.request_with_token_refresh(oauth_client_token) { yield_service_result }
    end

    before do
      allow(instance).to receive(:refresh_token).and_return(refresh_service_result)
      allow(oauth_client_token).to receive(:reload)
    end

    context "with yield returning :success" do
      it "returns a ServiceResult with success, without refreshing the token" do
        expect(subject.success).to be_truthy
        expect(instance).not_to have_received(:refresh_token)
        expect(oauth_client_token).not_to have_received(:reload)
      end
    end

    context "with yield returning :error" do
      let(:yield_service_result) { ServiceResult.failure(result: :error) }

      it "returns a ServiceResult with success, without refreshing the token" do
        expect(subject.success).to be_falsy
        expect(subject.result).to be :error
        expect(instance).not_to have_received(:refresh_token)
        expect(oauth_client_token).not_to have_received(:reload)
      end
    end

    context "with yield returning :unauthorized and the refresh returning a with a success" do
      let(:yield_service_result) { ServiceResult.failure(result: :unauthorized) }

      it "returns a ServiceResult with success, without refresh" do
        expect(subject.success).to be_falsy
        expect(subject.result).to be :unauthorized
        expect(instance).to have_received(:refresh_token)
        expect(oauth_client_token).to have_received(:reload)
      end
    end

    context "with yield returning :unauthorized and the refresh returning with a :failure" do
      let(:yield_service_result) { ServiceResult.failure(result: :unauthorized) }
      let(:refresh_service_result) do
        data = Storages::StorageErrorData.new(source: nil, payload: { error: "invalid_request" })
        ServiceResult.failure(result: :error,
                              errors: Storages::StorageError.new(code: :error, data:))
      end

      it "returns a ServiceResult with success, without refresh" do
        expect(subject.success).to be_falsy
        expect(subject.result).to be :error
        expect(instance).to have_received(:refresh_token)
        expect(oauth_client_token).not_to have_received(:reload)
      end
    end

    context "with yield returning :unauthorized first time and :success the second time" do
      let(:yield_double_object) { Object.new }
      let(:yield_service_result1) { ServiceResult.failure(result: :unauthorized) }
      let(:yield_service_result2) { ServiceResult.success }
      let(:refresh_service_result) { ServiceResult.success }

      subject do
        instance.request_with_token_refresh(oauth_client_token) { yield_double_object.yield_twice_method }
      end

      before do
        allow(instance).to receive(:refresh_token).and_return refresh_service_result

        without_partial_double_verification do
          allow(yield_double_object)
            .to receive(:yield_twice_method)
                  .and_return(
                    yield_service_result1,
                    yield_service_result2
                  )
        end
      end

      it "returns a ServiceResult with success, without refresh" do
        without_partial_double_verification do
          expect(subject.success).to be_truthy
          expect(subject).to be yield_service_result2
          expect(instance).to have_received(:refresh_token)
          expect(oauth_client_token).to have_received(:reload)
          expect(yield_double_object).to have_received(:yield_twice_method).twice
        end
      end
    end
  end
end

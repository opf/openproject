#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'
require 'webmock/rspec'

describe OAuthClients::ConnectionManager, type: :model do
  let(:user) { create :user }
  let(:host) { "https://example.org" }
  let(:provider_type) { Storages::Storage::PROVIDER_TYPE_NEXTCLOUD }
  let(:storage) { create(:storage, provider_type:, host: "#{host}/") }
  let(:scope) { [:all] } # OAuth2 resources to access, specific to provider
  let(:oauth_client) do
    create(:oauth_client,
           client_id: "nwz34rWsolvJvchfQ1bVHXfMb1ETK89lCBgzrLhWx3ACW5nKfmdcyf5ftlCyKGbk",
           client_secret: "A08n6CRBOOr41iqkWRynnP6BbmEnau7LeP9t9xrIbiYX46iXgmIZgqhJoDFjUMEq",
           integration: storage)
  end
  let(:oauth_client_token) { create(:oauth_client_token, oauth_client:, user:) }
  let(:instance) { described_class.new(user:, oauth_client:) }

  # The get_authorization_uri method returns the OAuth2 authorization URI as a string. That URI is the starting point for
  # a user to grant OpenProject access to Nextcloud.
  describe '#get_authorization_uri' do
    let(:scope) { nil }
    let(:state) { nil }

    subject { instance.get_authorization_uri(scope:, state:) }

    context 'with empty state and scope' do
      shared_examples_for 'returns the authorization URI relative to the host' do
        it 'returns the authorization URI' do
          expect(subject).to be_a String
          expect(subject).to include oauth_client.integration.host
          expect(subject).not_to include "scope"
          expect(subject).not_to include "state"
        end
      end

      context 'when Nextcloud is installed in the server root' do
        it_behaves_like 'returns the authorization URI relative to the host'
      end

      context 'when Nextcloud is installed in a sub-directory' do
        let(:host) { "https://example.org/nextcloud" }

        it_behaves_like 'returns the authorization URI relative to the host'
      end
    end

    context 'with state but empty scope' do
      let(:state) { "https://example.com/page" }

      it 'returns the redirect URL' do
        expect(subject).to be_a String
        expect(subject).to include oauth_client.integration.host
        expect(subject).not_to include "scope"
        expect(subject).to include "&state=https"
      end
    end

    context 'with multiple scopes but empty state' do
      let(:scope) { %i(email profile) }

      it 'returns the redirect URL' do
        expect(subject).to be_a String
        expect(subject).to include oauth_client.integration.host
        expect(subject).not_to include "state"
        expect(subject).to include "&scope=email%20profile"
      end
    end
  end

  # The first step in the OAuth2 flow is to produce a URL for the
  # user to authenticate and authorize access at the OAuth2 provider
  # (Nextcloud).
  describe '#get_access_token' do
    subject { instance.get_access_token }

    context 'with no OAuthClientToken present' do
      it 'returns a redirection URL' do
        expect(subject.success).to be_falsey
        expect(subject.result).to be_a String
        # Details of string are tested above in section #get_authorization_uri
      end
    end

    context 'with no OAuthClientToken present and state parameters' do
      subject { instance.get_access_token(state: "some_state", scope: [:email]) }

      it 'returns the redirect URL' do
        expect(subject.success).to be_falsey
        expect(subject.result).to be_a String
        expect(subject.result).to include oauth_client.integration.host
        expect(subject.result).to include "&state=some_state"
        expect(subject.result).to include "&scope=email"
      end
    end

    context 'with an OAuthClientToken present' do
      before do
        oauth_client_token
      end

      it 'returns the OAuthClientToken' do
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
  describe '#code_to_token' do
    let(:code) { "7kRGJ...jG3KZ" }

    subject { instance.code_to_token(code) }

    context 'with happy path' do
      before do
        # Simulate a successful authorization returning the tokens
        response_body = {
          access_token: "yjTDZ...RYvRH",
          token_type: "Bearer",
          expires_in: 3600,
          refresh_token: "UwFp...1FROJ",
          user_id: "admin"
        }.to_json
        stub_request(:any, File.join(host, '/index.php/apps/oauth2/api/v1/token'))
          .to_return(status: 200, body: response_body)
      end

      it 'returns a valid ClientToken object', webmock: true do
        expect(subject.success).to be_truthy
        expect(subject.result).to be_a OAuthClientToken
      end
    end

    context 'with known error', webmock: true do
      before do
        stub_request(:post, File.join(host, '/index.php/apps/oauth2/api/v1/token'))
          .to_return(status: 400, body: { error: error_message }.to_json)
      end

      shared_examples 'OAuth2 error response' do
        it 'returns a specific error message' do
          expect(subject.success).to be_falsey
          expect(subject.result).to eq error_message
          expect(subject.errors[:base].count).to be(1)
          expect(subject.errors[:base].first).to include I18n.t("oauth_client.errors.rack_oauth2.#{error_message}")
        end
      end

      context 'when "invalid_request"' do
        let(:error_message) { 'invalid_request' }

        it_behaves_like 'OAuth2 error response'
      end

      context 'when "invalid_grant"' do
        let(:error_message) { 'invalid_grant' }

        it_behaves_like 'OAuth2 error response'
      end
    end

    context 'with known reply invalid_grant', webmock: true do
      before do
        stub_request(:post, File.join(host, '/index.php/apps/oauth2/api/v1/token'))
          .to_return(status: 400, body: { error: "invalid_grant" }.to_json)
      end

      it 'returns a specific error message' do
        expect(subject.success).to be_falsey
        expect(subject.result).to eq 'invalid_grant'
        expect(subject.errors[:base].count).to be(1)
        expect(subject.errors[:base].first).to include I18n.t('oauth_client.errors.rack_oauth2.invalid_grant')
      end
    end

    context 'with unknown reply', webmock: true do
      before do
        stub_request(:post, File.join(host, '/index.php/apps/oauth2/api/v1/token'))
          .to_return(status: 400, body: { error: "invalid_requesttt" }.to_json)
      end

      it 'returns an unspecific error message' do
        expect(subject.success).to be_falsey
        expect(subject.result).to eq 'invalid_requesttt'
        expect(subject.errors[:base].count).to be(1)
        expect(subject.errors[:base].first).to include I18n.t('oauth_client.errors.oauth_returned_error')
      end
    end

    context 'with reply including JSON syntax error', webmock: true do
      before do
        stub_request(:post, File.join(host, '/index.php/apps/oauth2/api/v1/token'))
          .to_return(
            status: 400,
            headers: { 'Content-Type' => 'application/json; charset=utf-8' },
            body: "some: very, invalid> <json}"
          )
      end

      it 'returns an unspecific error message' do
        expect(subject.success).to be_falsey
        expect(subject.result).to eq 'Unknown :: some: very, invalid> <json}'
        expect(subject.errors[:base].count).to be(1)
        expect(subject.errors[:base].first).to include I18n.t('oauth_client.errors.oauth_returned_error')
      end
    end

    context 'with 500 reply without body', webmock: true do
      before do
        stub_request(:post, File.join(host, '/index.php/apps/oauth2/api/v1/token'))
          .to_return(status: 500)
      end

      it 'returns an unspecific error message' do
        expect(subject.success).to be_falsey
        expect(subject.result).to eq 'Unknown :: '
        expect(subject.errors[:base].count).to be(1)
        expect(subject.errors[:base].first).to include I18n.t('oauth_client.errors.oauth_returned_error')
      end
    end

    context 'with bad HTTP response', webmock: true do
      before do
        stub_request(:post, File.join(host, '/index.php/apps/oauth2/api/v1/token')).to_raise(Net::HTTPBadResponse)
      end

      it 'returns an unspecific error message' do
        expect(subject.success).to be_falsey
        expect(subject.result).to be_nil
        expect(subject.errors[:base].count).to be(1)
        expect(subject.errors[:base].first).to include I18n.t('oauth_client.errors.oauth_returned_http_error')
      end
    end

    context 'with timeout returns internal error', webmock: true do
      before do
        stub_request(:post, File.join(host, '/index.php/apps/oauth2/api/v1/token')).to_timeout
      end

      it 'returns an unspecific error message' do
        expect(subject.success).to be_falsey
        expect(subject.result).to be_nil
        expect(subject.errors[:base].count).to be(1)
        expect(subject.errors[:base].first).to include I18n.t('oauth_client.errors.oauth_returned_standard_error')
      end
    end
  end

  describe '#refresh_token' do
    subject { instance.refresh_token }

    context 'without preexisting OAuthClientToken' do
      it 'returns an error message' do
        expect(subject.success).to be_falsey
        expect(subject.errors[:base].first)
          .to include I18n.t('oauth_client.errors.refresh_token_called_without_existing_token')
      end
    end

    context 'with successful response from OAuth2 provider (happy path)' do
      before do
        # Simulate a successful authorization returning the tokens
        response_body = {
          access_token: "xyjTDZ...RYvRH",
          token_type: "Bearer",
          expires_in: 3601,
          refresh_token: "xUwFp...1FROJ",
          user_id: "admin"
        }.to_json
        stub_request(:any, File.join(host, '/index.php/apps/oauth2/api/v1/token'))
          .to_return(status: 200, body: response_body)
        oauth_client_token
      end

      it 'returns a valid ClientToken object', webmock: true do
        expect(subject.success).to be_truthy
        expect(subject.result).to be_a OAuthClientToken
        expect(subject.result.access_token).to eq("xyjTDZ...RYvRH")
        expect(subject.result.refresh_token).to eq("xUwFp...1FROJ")
        expect(subject.result.expires_in).to be(3601)
      end
    end

    context 'with invalid access_token data' do
      before do
        # Simulate a token too long
        response_body = {
          access_token: "x" * 257, # will fail model validation
          token_type: "Bearer",
          expires_in: 3601,
          refresh_token: "xUwFp...1FROJ",
          user_id: "admin"
        }.to_json
        stub_request(:any, File.join(host, '/index.php/apps/oauth2/api/v1/token'))
          .to_return(status: 200, body: response_body)

        oauth_client_token
      end

      it 'returns dependent error from model validation', webmock: true do
        expect(subject.success).to be_falsey
        expect(subject.result).to be_nil
        expect(subject.errors.size).to be(1)
        puts subject.errors
      end
    end

    context 'with server error from OAuth2 provider' do
      before do
        stub_request(:any, File.join(host, '/index.php/apps/oauth2/api/v1/token'))
          .to_return(status: 400, body: { error: "invalid_request" }.to_json)
        oauth_client_token
      end

      it 'returns a server error', webmock: true do
        expect(subject.success).to be_falsey
        expect(subject.errors.size).to be(1)
        puts subject.errors
      end
    end

    context 'with successful response but invalid data' do
      before do
        # Simulate timeout
        stub_request(:any, File.join(host, '/index.php/apps/oauth2/api/v1/token'))
          .to_timeout
        oauth_client_token
      end

      it 'returns a valid ClientToken object', webmock: true do
        expect(subject.success).to be_falsey
        expect(subject.result).to be_nil
        expect(subject.errors.size).to be(1)
      end
    end
  end

  describe '#authorization_state' do
    subject { instance.authorization_state }

    context 'without access token present' do
      it 'returns :failed_authorization' do
        expect(subject).to eq :failed_authorization
      end
    end

    context 'with access token present', webmock: true do
      before do
        oauth_client_token
      end

      context 'with access token valid' do
        context 'without other errors or exceptions' do
          before do
            stub_request(:get, File.join(host, OAuthClients::ConnectionManager::AUTHORIZATION_CHECK_PATH))
              .to_return(status: 200)
          end

          it 'returns :connected' do
            expect(subject).to eq :connected
          end
        end

        context 'with some other error or exception' do
          before do
            stub_request(:get, File.join(host, OAuthClients::ConnectionManager::AUTHORIZATION_CHECK_PATH))
              .to_timeout
          end

          it 'returns :error' do
            expect(subject).to eq :error
          end
        end
      end

      context 'with outdated access token' do
        let(:new_oauth_client_token) { create :oauth_client_token }
        let(:refresh_service_result) { ServiceResult.success }

        before do
          stub_request(:get, File.join(host, OAuthClients::ConnectionManager::AUTHORIZATION_CHECK_PATH))
            .to_return(status: 401) # 401 unauthorized
          allow(instance).to receive(:refresh_token).and_return(refresh_service_result)
        end

        context 'with valid refresh token' do
          it 'refreshes the access token and returns :connected' do
            expect(subject).to eq :connected
            expect(instance).to have_received(:refresh_token)
          end
        end

        context 'with invalid refresh token' do
          let(:refresh_service_result) { ServiceResult.failure(result: 'invalid_request') }

          it 'refreshes the access token and returns :failed_authorization' do
            expect(subject).to eq :failed_authorization
            expect(instance).to have_received(:refresh_token)
          end
        end

        context 'with some other error while refreshing access token' do
          let(:refresh_service_result) { ServiceResult.failure }

          it 'returns :error' do
            expect(subject).to eq :error
            expect(instance).to have_received(:refresh_token)
          end
        end
      end
    end

    context 'with both invalid access token and refresh token', webmock: true do
      it 'returns :failed_authorization' do
        expect(subject).to eq :failed_authorization
      end
    end
  end

  describe '#request_with_token_refresh' do
    let(:yield_service_result) { ServiceResult.success }
    let(:refresh_service_result) { ServiceResult.success }

    subject do
      instance.request_with_token_refresh(oauth_client_token) { yield_service_result }
    end

    before do
      allow(instance).to receive(:refresh_token).and_return(refresh_service_result)
      allow(oauth_client_token).to receive(:reload)
    end

    context 'with yield returning :success' do
      it 'returns a ServiceResult with success, without refreshing the token' do
        expect(subject.success).to be_truthy
        expect(instance).not_to have_received(:refresh_token)
        expect(oauth_client_token).not_to have_received(:reload)
      end
    end

    context 'with yield returning :error' do
      let(:yield_service_result) { ServiceResult.failure(result: :error) }

      it 'returns a ServiceResult with success, without refreshing the token' do
        expect(subject.success).to be_falsey
        expect(subject.result).to be :error
        expect(instance).not_to have_received(:refresh_token)
        expect(oauth_client_token).not_to have_received(:reload)
      end
    end

    context 'with yield returning :not_authorized and the refresh returning a with a success' do
      let(:yield_service_result) { ServiceResult.failure(result: :not_authorized) }

      it 'returns a ServiceResult with success, without refresh' do
        expect(subject.success).to be_falsey
        expect(subject.result).to be :not_authorized
        expect(instance).to have_received(:refresh_token)
        expect(oauth_client_token).to have_received(:reload)
      end
    end

    context 'with yield returning :not_authorized and the refresh returning with a :failure' do
      let(:yield_service_result) { ServiceResult.failure(result: :not_authorized) }
      let(:refresh_service_result) { ServiceResult.failure }

      it 'returns a ServiceResult with success, without refresh' do
        expect(subject.success).to be_falsey
        expect(subject.result).to be :error
        expect(instance).to have_received(:refresh_token)
        expect(oauth_client_token).not_to have_received(:reload)
      end
    end

    context 'with yield returning :not_authorized first time and :success the second time' do
      let(:yield_double_object) { Object.new }
      let(:yield_service_result1) { ServiceResult.failure(result: :not_authorized) }
      let(:yield_service_result2) { ServiceResult.success }
      let(:refresh_service_result) { ServiceResult.success }

      subject do
        instance.request_with_token_refresh(oauth_client_token) { yield_double_object.yield_twice_method }
      end

      before do
        allow(instance).to receive(:refresh_token).and_return refresh_service_result
        allow(yield_double_object)
          .to receive(:yield_twice_method)
                .and_return(
                  yield_service_result1,
                  yield_service_result2
                )
      end

      it 'returns a ServiceResult with success, without refresh' do
        expect(subject.success).to be_truthy
        expect(subject).to be yield_service_result2
        expect(instance).to have_received(:refresh_token)
        expect(oauth_client_token).to have_received(:reload)
        expect(yield_double_object).to have_received(:yield_twice_method).twice
      end
    end
  end
end

# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe OAuthClients::ConnectionManager, :webmock, type: :model do
  let(:user) { create(:user) }
  let(:storage) { create(:one_drive_storage, :with_oauth_client, tenant_id: 'consumers') }
  let(:token) { create(:oauth_client_token, oauth_client: storage.oauth_client, user:) }

  subject(:connection_manager) do
    described_class.new(user:, configuration: storage.oauth_configuration)
  end

  describe '#code_to_token' do
    let(:code) { 'wow.such.code.much.token' }
    let(:code_to_token_response) do
      {
        access_token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik5HVEZ2ZEstZnl0aEV1Q...",
        token_type: "Bearer",
        expires_in: 3599,
        scope: "Mail.Read User.Read",
        refresh_token: "AwABAAAAvPM1KaPlrEqdFSBzjqfTGAMxZGUTdM0t4B4..."
      }.to_json
    end
    let(:me_response) do
      {
        businessPhones: [
          "+45 123 4567 8901"
        ],
        displayName: "Sheev Palpatine ",
        givenName: "Sheev",
        jobTitle: "Galatic Senator",
        mail: "palpatine@senate.com",
        mobilePhone: "+45 123 4567 8901",
        officeLocation: "500 Republica",
        preferredLanguage: "en-US",
        surname: "Palpatine",
        userPrincipalName: "palpatine@senate.com",
        id: "87d349ed-44d7-43e1-9a83-5f2406dee5bd"
      }.to_json
    end

    before do
      stub_request(:post, 'https://login.microsoftonline.com/consumers/oauth2/v2.0/token')
        .to_return(status: 200, body: code_to_token_response, headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, 'https://graph.microsoft.com/v1.0/me')
        .with(headers: { Authorization: "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik5HVEZ2ZEstZnl0aEV1Q..." })
        .to_return(status: 200, body: me_response, headers: { 'Content-Type' => 'application/json' })
    end

    it 'fills in the origin_user_id' do
      expect { subject.code_to_token(code) }.to change(OAuthClientToken, :count).by(1)

      last_token = OAuthClientToken
                     .where(access_token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik5HVEZ2ZEstZnl0aEV1Q...")
                     .last

      expect(last_token.origin_user_id).to eq('87d349ed-44d7-43e1-9a83-5f2406dee5bd')
    end
  end

  describe '#get_authorization_uri' do
    it 'always add the necessary scopes' do
      uri = connection_manager.get_authorization_uri(state: nil)

      expect(uri).to include storage.oauth_configuration.scope.join('%20')
    end

    it 'adds the state if present' do
      uri = connection_manager.get_authorization_uri(state: 'https://some.site.com')
      expect(uri).to include "&state=https"
    end
  end

  describe '#get_access_token' do
    subject(:access_token_result) { connection_manager.get_access_token }

    context 'with no OAuthClientToken present' do
      it 'returns a redirection URL' do
        expect(access_token_result).to be_failure
        expect(access_token_result.result).to eq(connection_manager.get_authorization_uri)
      end
    end

    context 'with an OAuthClientToken present' do
      before { token }

      it 'returns the OAuthClientToken' do
        expect(access_token_result).to be_truthy
        expect(access_token_result.result).to be_a OAuthClientToken # The one and only...
        expect(access_token_result.result).to eql token
      end
    end
  end

  describe '#authorization_state' do
    subject(:authorization_state) { connection_manager.authorization_state }

    context 'without access token present' do
      it 'returns :failed_authorization' do
        expect(authorization_state).to eq :failed_authorization
      end
    end

    context 'with access token present', :webmock do
      before { token }

      context 'with access token valid' do
        context 'without other errors or exceptions' do
          before { stub_request(:get, 'https://graph.microsoft.com/v1.0/me').to_return(status: 200) }

          it 'returns :connected' do
            expect(authorization_state).to eq :connected
          end
        end

        context 'with some other error or exception' do
          before { stub_request(:get, 'https://graph.microsoft.com/v1.0/me').to_timeout }

          it 'returns :error' do
            expect(authorization_state).to eq :error
          end
        end
      end

      context 'with outdated access token' do
        shared_examples 'refresh' do |_code|
          before do
            stub_request(:get, 'https://graph.microsoft.com/v1.0/me').to_return(status: 401)
          end

          context 'with valid refresh token' do
            it 'refreshes the access token and returns :connected' do
              expect(authorization_state).to eq :connected
            end
          end

          context 'with invalid refresh token' do
            it 'refreshes the access token and returns :failed_authorization' do
              allow(token).to receive(:updated_at).and_return(3.months.ago)
              expect(authorization_state).to eq :failed_authorization
            end
          end

          context 'with some other error while refreshing access token' do
            it 'returns :error' do
              expect(authorization_state).to eq :error
            end
          end
        end

        context 'when Unathorized is returned' do
          before do
            stub_request(:get, 'https://graph.microsoft.com/v1.0/me').to_return(status: 401)
          end

          context 'with valid refresh token' do
            it 'refreshes the access token and returns :connected' do
              expect(authorization_state).to eq :connected
            end
          end

          context 'with invalid refresh token' do
            before do
              token.update!(updated_at: 3.months.ago)
              stub_request(:post, 'https://login.microsoftonline.com/consumers/oauth2/v2.0/token')
                .to_return(status: 400,
                           body: { error: 'invalid_request', error_message: 'nope. not happening' }.to_json,
                           headers: { 'Content-Type' => 'application/json' })
            end

            it 'refreshes the access token and returns :failed_authorization' do
              expect(authorization_state).to eq :failed_authorization
            end
          end

          context 'with some other error while refreshing access token' do
            it 'returns :error' do
              token.update!(updated_at: 3.months.ago)

              stub_request(:get, 'https://graph.microsoft.com/v1.0/me').to_return(status: 401)
              stub_request(:post, 'https://login.microsoftonline.com/consumers/oauth2/v2.0/token')
                .to_return(status: 400,
                           body: { error: 'you_error', error_message: 'it is not me, it is you' }.to_json,
                           headers: { 'Content-Type' => 'application/json' })

              expect(authorization_state).to eq :error
            end
          end
        end

        context 'when Forbidden is returned' do
          before do
            stub_request(:get, 'https://graph.microsoft.com/v1.0/me').to_return(status: 403)
          end

          context 'with valid refresh token' do
            it 'refreshes the access token and returns :connected' do
              expect(authorization_state).to eq :connected
            end
          end

          context 'with invalid refresh token' do
            before do
              token.update!(updated_at: 3.months.ago)
              stub_request(:post, 'https://login.microsoftonline.com/consumers/oauth2/v2.0/token')
                .to_return(status: 400,
                           body: { error: 'invalid_request', error_message: 'nope. not happening' }.to_json,
                           headers: { 'Content-Type' => 'application/json' })
            end

            it 'refreshes the access token and returns :failed_authorization' do
              expect(authorization_state).to eq :failed_authorization
            end
          end
        end
      end
    end
  end
end

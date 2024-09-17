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

RSpec.describe OAuthClients::ConnectionManager, :oauth_connection_helpers, :webmock, type: :model do
  let(:user) { create(:user) }
  let(:storage) { create(:one_drive_storage, :with_oauth_client, tenant_id: "consumers") }
  let(:token) { create(:oauth_client_token, oauth_client: storage.oauth_client, user:) }

  subject(:connection_manager) do
    described_class.new(user:, configuration: storage.oauth_configuration)
  end

  describe "#code_to_token" do
    let(:code) { "wow.such.code.much.token" }
    let(:code_to_token_response) do
      {
        access_token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik5HVEZ2ZEstZnl0aEV1Q...",
        token_type: "Bearer",
        expires_in: 3599,
        scope: "Mail.Read User.Read",
        refresh_token: "AwABAAAAvPM1KaPlrEqdFSBzjqfTGAMxZGUTdM0t4B4..."
      }.to_json
    end

    before do
      stub_request(:post, "https://login.microsoftonline.com/consumers/oauth2/v2.0/token")
        .to_return(status: 200, body: code_to_token_response, headers: { "Content-Type" => "application/json" })

      mock_one_drive_authorization_validation(
        with: { headers: { Authorization: "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik5HVEZ2ZEstZnl0aEV1Q..." } }
      )
    end

    it "fills in the origin_user_id" do
      expect { subject.code_to_token(code) }.to change(OAuthClientToken, :count).by(1).and(change(RemoteIdentity, :count).by(1))

      last_token = RemoteIdentity.find_by!(user:, oauth_client: storage.oauth_client)
      expect(last_token.origin_user_id).to eq("87d349ed-44d7-43e1-9a83-5f2406dee5bd")
    end

    context "when the identification request fails" do
      before do
        stub_request(:get, "https://graph.microsoft.com/v1.0/me")
          .with(headers: { Authorization: "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik5HVEZ2ZEstZnl0aEV1Q..." })
          .to_return(status: 404)
      end

      it "raises an error" do
        expect { subject.code_to_token(code) }.to raise_error(HTTPX::HTTPError)
      end
    end
  end

  describe "#get_access_token" do
    subject(:access_token_result) { connection_manager.get_access_token }

    context "with no OAuthClientToken present" do
      it "returns a redirection URL" do
        expect(access_token_result).to be_failure
        expect(access_token_result.result).to eq(storage.oauth_configuration.authorization_uri)
      end
    end

    context "with an OAuthClientToken present" do
      before { token }

      it "returns the OAuthClientToken" do
        expect(access_token_result).to be_truthy
        expect(access_token_result.result).to be_a OAuthClientToken # The one and only...
        expect(access_token_result.result).to eql token
      end
    end
  end
end

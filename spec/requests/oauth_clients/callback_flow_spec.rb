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
require "rack/test"

RSpec.describe "OAuthClient callback endpoint" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) { create(:user) }

  let(:code) do
    "mBf4v9hNA6hXXCWHd5mZggsAa2FSOXinx9jKx1yjSoDwOPOX4k6zGEgM2radqgg1nRwXCqvIe5xZsfwqMIaTdL" +
      "jYnl0OpYOc6ePblzQTmnlp7RYiHW09assYEJjv9zps"
  end
  let(:state) { "asdf1234" }
  let(:redirect_uri) do
    File.join(API::V3::Utilities::PathHelper::ApiV3Path::root_url, "/my-path?and=some&query=params")
  end
  let(:oauth_client_token) { create(:oauth_client_token) }
  let(:oauth_client) do
    create(:oauth_client,
           client_id: "kETWr2XsjPxhVbN7Q5jmPq83xribuUTRzgfXthpYT0vSqyJWm4dOnivKzHiZasf0",
           client_secret: "J1sg4L5PYbM2RZL3pUyxTnamvfpcP5eUcCPmeCQHJO60Gy6CJIdDaF4yXOeC8BPS")
  end
  let(:rack_oauth2_client) { instance_double(Rack::OAuth2::Client) }
  let(:connection_manager) { instance_double(OAuthClients::ConnectionManager) }
  let(:uri) { URI(File.join("oauth_clients", oauth_client.client_id, "callback")) }

  subject(:response) { last_response }

  context "when user is not logged in" do
    it "requires login" do
      get uri.to_s
      expect(last_response).to have_http_status(:unauthorized)
    end
  end

  context "when user is logged in" do
    before do
      login_as current_user

      allow(Rack::OAuth2::Client).to receive(:new).and_return(rack_oauth2_client)
      allow(rack_oauth2_client)
        .to receive(:access_token!)
        .with(:body)
        .and_return(Rack::OAuth2::AccessToken::Bearer.new(access_token: "xyzaccesstoken",
                                                          refresh_token: "xyzrefreshtoken",
                                                          user_id: "g-root"))
      allow(rack_oauth2_client).to receive(:authorization_code=)
      state_cookie = CGI.escape({ href: redirect_uri, storageId: oauth_client.integration_id }.to_json)
      set_cookie "oauth_state_asdf1234=#{state_cookie}"
    end

    shared_examples "with errors and state param with cookie, not being admin" do
      it "redirects to URI referenced in the state param and held in a cookie" do
        expect(response).to have_http_status(:found)
        expect(response.location).to eq redirect_uri
      end
    end

    shared_examples "with errors, being an admin" do
      it "redirects to admin settings for the storage" do
        expect(response).to have_http_status(:found)
        expect(URI(response.location).path).to eq edit_admin_settings_storage_path(oauth_client.integration)
      end
    end

    shared_examples "fallback redirect" do
      it "redirects to home" do
        expect(response).to have_http_status(:found)
        expect(URI(response.location).path).to eq API::V3::Utilities::PathHelper::ApiV3Path::root_path
      end
    end

    context "with valid params" do
      context "without errors" do
        before do
          uri.query = URI.encode_www_form([["code", code], ["state", state]])
          get uri.to_s
        end

        it "redirects to the URL that was referenced by the state param and held by a cookie" do
          expect(rack_oauth2_client).to have_received(:authorization_code=).with(code)
          expect(response).to have_http_status :found
          expect(response.location).to eq redirect_uri
          expect(OAuthClientToken.count).to eq 1
          expect(OAuthClientToken.last.access_token).to eq "xyzaccesstoken"
          expect(OAuthClientToken.last.refresh_token).to eq "xyzrefreshtoken"
        end
      end

      context "with a OAuth state cookie containing a URL pointing to a different host" do
        let(:redirect_uri) { "https://some-other-domain.com/foo/bar" }

        before do
          uri.query = URI.encode_www_form([["code", code], ["state", state]])
          get uri.to_s

          subject
        end

        it_behaves_like "fallback redirect"
      end

      context "with some other error, having a state param" do
        before do
          allow(OAuthClients::ConnectionManager)
            .to receive(:new).and_return(connection_manager)
          allow(connection_manager)
            .to receive(:code_to_token).with(code).and_return(ServiceResult.failure)

          uri.query = URI.encode_www_form([["code", code], ["state", state]])
          get uri.to_s

          subject
        end

        context "with current_user being an admin" do
          let(:current_user) { create(:admin) }

          it_behaves_like "with errors, being an admin"
        end

        context "with current_user not being an admin" do
          it_behaves_like "with errors and state param with cookie, not being admin"
        end
      end
    end

    context "without code param, but with state param," do
      before do
        uri.query = URI.encode_www_form([["state", state]])
        get uri.to_s

        subject
      end

      context "with current_user not being an admin" do
        it_behaves_like "with errors and state param with cookie, not being admin"
      end

      context "with current_user being an admin" do
        let(:current_user) { create(:admin) }

        it_behaves_like "with errors, being an admin"
      end
    end

    context "without state param" do
      before do
        uri.query = URI.encode_www_form([["code", code]])
        get uri.to_s

        subject
      end

      it_behaves_like "fallback redirect"
    end
  end
end

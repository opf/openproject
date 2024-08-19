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
require_relative "openid_connect_spec_helpers"

RSpec.configure do |c|
  c.include OpenIDConnectSpecHelpers
end

RSpec.describe "OpenID Connect", :skip_2fa_stage, # Prevent redirects to 2FA stage
               type: :rails_request,
               with_ee: %i[openid_providers] do
  let(:host) { OmniAuth::OpenIDConnect::Heroku.new("foo", {}).host }
  let(:user_info) do
    {
      sub: "87117114115116",
      name: "Hans Wurst",
      email: "h.wurst@finn.de",
      given_name: "Hans",
      family_name: "Wurst"
    }
  end

  before do
    # The redirect will include an authorisation code.
    # Since we don't actually get a valid code in the test we will stub the resulting AccessToken.
    allow_any_instance_of(OpenIDConnect::Client).to receive(:access_token!) do
      OpenIDConnect::AccessToken.new client: self, access_token: "foo bar baz"
    end

    # Using the granted AccessToken the client then performs another request to the OpenID Connect
    # provider to retrieve user information such as name and email address.
    # Since the test is not supposed to make an actual call it is be stubbed too.
    allow_any_instance_of(OpenIDConnect::AccessToken).to receive(:userinfo!).and_return(
      OpenIDConnect::ResponseObject::UserInfo.new(user_info)
    )

    # Enable storing the access token in a cookie is not necessary since it is currently hard wired to always
    # be true.
  end

  describe "sign-up and login" do
    before do
      allow(Setting).to receive(:plugin_openproject_openid_connect).and_return(
        "providers" => {
          "heroku" => {
            "identifier" => "does not",
            "secret" => "matter"
          }
        }
      )
    end

    it "works" do
      ##
      # it should redirect to the provider's openid connect authentication endpoint
      click_on_signin

      expect(response).to have_http_status :found
      expect(response.location).to match /https:\/\/#{host}.*$/

      params = Rack::Utils.parse_nested_query(response.location.gsub(/^.*\?/, ""))

      expect(params).to include "client_id"
      expect(params["redirect_uri"]).to match /^.*\/auth\/heroku\/callback$/
      expect(params["scope"]).to include "openid"

      ##
      # it should redirect back from the provider to the login page
      redirect_from_provider

      expect(response).to have_http_status :found
      expect(response.location).to match /\/\?first_time_user=true$/

      user = User.find_by(mail: user_info[:email])

      expect(user).not_to be_nil
      expect(user.active?).to be true

      ##
      # it should redirect to the provider again upon clicking on sign-in when the user has been activated
      user = User.find_by(mail: user_info[:email])
      user.activate
      user.save!

      click_on_signin

      expect(response).to have_http_status :found
      expect(response.location).to match /https:\/\/#{host}.*$/

      ##
      # it should then login the user upon the redirect back from the provider
      redirect_from_provider

      expect(response).to have_http_status :found
      expect(response.location).to match /\/my\/page/
    end

    context "with a custom claim and mapping" do
      let(:user_info) do
        {
          sub: "87117114115116",
          name: "Hans Wurst",
          email: "h.wurst@finn.de",
          given_name: "Hans",
          family_name: "Wurst",
          foobar: "a.truly.random.value"
        }
      end

      before do
        allow(Setting).to receive(:plugin_openproject_openid_connect).and_return(
          "providers" => {
            "heroku" => {
              "attribute_map" => { login: :foobar },
              "identifier" => "does not",
              "secret" => "matter"
            }
          }
        )
      end

      it "maps to the login" do
        click_on_signin
        redirect_from_provider

        user = User.find_by(login: "a.truly.random.value")
        expect(user).to be_present
      end
    end
  end

  context "provider configuration through the settings" do
    before do
      allow(Setting).to receive(:plugin_openproject_openid_connect).and_return(
        "providers" => {
          "google" => {
            "identifier" => "does not",
            "secret" => "matter"
          },
          "azure" => {
            "identifier" => "IDENTIFIER",
            "secret" => "SECRET"
          }
        }
      )
    end

    it "shows no option unless EE", with_ee: false do
      get "/login"
      expect(response.body).not_to match /Google/i
      expect(response.body).not_to match /Azure/i
    end

    it "makes providers that have been configured through settings available without requiring a restart" do
      get "/login"
      expect(response.body).to match /Google/i
      expect(response.body).to match /Azure/i

      expect { click_on_signin("google") }.not_to raise_error
      expect(response).to have_http_status :found
    end
  end
end

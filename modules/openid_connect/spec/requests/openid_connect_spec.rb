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
require_relative "openid_connect_spec_helpers"

RSpec.configure do |c|
  c.include OpenIDConnectSpecHelpers
end

RSpec.describe "OpenID Connect", :skip_2fa_stage, :skip_csrf, # Prevent redirects to 2FA stage
               type: :rails_request,
               with_ee: %i[sso_auth_providers] do
  let(:host) { "keycloak.local" }
  let(:user_info) do
    {
      sub: "87117114115116",
      name: "Hans Wurst",
      email: "h.wurst@finn.de",
      given_name: "Hans",
      family_name: "Wurst",
      groups: ["my-group"]
    }
  end
  let(:access_token) { "foo-bar-baz" }
  let(:refresh_token) { "refreshing-foo-bar-baz" }
  let(:expires_in) { 60 }
  let(:oidc_sid) { "oidc-session-id-42" }

  before do
    # The redirect will include an authorisation code.
    # Since we don't actually get a valid code in the test we will stub the resulting AccessToken.
    allow_any_instance_of(OpenIDConnect::Client).to receive(:access_token!) do
      instance_double(OpenIDConnect::AccessToken,
                      access_token:,
                      refresh_token:,
                      expires_in:,
                      userinfo!: OpenIDConnect::ResponseObject::UserInfo.new(user_info),
                      id_token: "not-nil").as_null_object
    end

    # We are also stubbing the way that an ID token would be decoded, so that the omniauth-openid-connect
    # strategy can fill the session id as well
    allow(OpenIDConnect::ResponseObject::IdToken).to receive(:decode).and_return(
      instance_double(OpenIDConnect::ResponseObject::IdToken, sid: oidc_sid).as_null_object
    )
  end

  describe "sign-up and login" do
    let(:limit_self_registration) { false }
    let!(:provider) { create(:oidc_provider, slug: "keycloak", limit_self_registration:) }

    it "signs up and logs in the user", :freeze_time do # rubocop:disable RSpec/ExampleLength
      ##
      # it should redirect to the provider's openid connect authentication endpoint
      click_on_signin("keycloak")

      expect(response).to have_http_status :found
      expect(response.location).to match /https:\/\/#{host}.*$/

      params = Rack::Utils.parse_nested_query(response.location.gsub(/^.*\?/, ""))

      expect(params).to include "client_id"
      expect(params["redirect_uri"]).to match /^.*\/auth\/keycloak\/callback$/
      expect(params["scope"]).to include "openid"

      ##
      # it should redirect back from the provider to the login page
      redirect_from_provider("keycloak")

      expect(response).to have_http_status :found
      expect(response.location).to match /\/\?first_time_user=true$/

      user = User.find_by(mail: user_info[:email])

      aggregate_failures "user details" do
        expect(user).not_to be_nil
        expect(user.active?).to be true
        expect(user.groups).to be_empty # group-sync not enabled
      end

      session = Sessions::UserSession.for_user(user).first
      session_link = session&.oidc_session_link

      expect(session_link).not_to be_nil
      expect(session_link.oidc_session).to eq oidc_sid

      token = user.oidc_user_tokens.first
      expect(token).not_to be_nil
      aggregate_failures "OIDC user token details" do
        expect(token.access_token).to eq access_token
        expect(token.refresh_token).to eq refresh_token
        expect(token.expires_at).to eq 60.seconds.from_now.change(usec: 0)
        expect(token.audiences).to eq ["__op-idp__"]
      end
    end

    context "when provider is configured to synchronize groups" do
      let!(:provider) do
        create(:oidc_provider, slug: "keycloak", limit_self_registration:, sync_groups: true, groups_claim: "groups")
      end

      it "signs up and logs in the user, adding them to the group", :freeze_time do
        click_on_signin("keycloak")
        redirect_from_provider("keycloak")

        user = User.find_by(mail: user_info[:email])

        expect(user).not_to be_nil
        expect(user.groups.pluck(:name)).to eq(["my-group"])
      end
    end

    context "when the user is already registered" do
      before do
        click_on_signin("keycloak")
        redirect_from_provider("keycloak")
      end

      it "logs in the user" do
        ##
        # it should redirect to the provider again upon clicking on sign-in when the user has been activated
        click_on_signin("keycloak")

        expect(response).to have_http_status :found
        expect(response.location).to match /https:\/\/#{host}.*$/

        ##
        # it should then login the user upon the redirect back from the provider
        redirect_from_provider("keycloak")

        expect(response).to have_http_status :found
        expect(response.location).to eq "http://#{Setting.host_name}/"
      end

      context "when synchronizing groups, but the groups-claim is empty" do
        let!(:provider) do
          create(:oidc_provider, slug: "keycloak", limit_self_registration:, sync_groups: true, groups_claim: "groups")
        end
        let(:user_info) do
          {
            sub: "87117114115116",
            name: "Hans Wurst",
            email: "h.wurst@finn.de",
            given_name: "Hans",
            family_name: "Wurst",
            groups: []
          }
        end

        before do
          User.find_by(mail: user_info[:email]).groups.create!(name: "A group")
        end

        it "removes all groups" do
          click_on_signin("keycloak")
          redirect_from_provider("keycloak")

          user = User.find_by(mail: user_info[:email])
          expect(user.groups.pluck(:name)).to be_empty
        end
      end
    end

    context "with self-registration disabled and provider respecting that",
            with_settings: {
              self_registration: 0
            } do
      let(:limit_self_registration) { true }

      it "does not allow registration" do
        click_on_signin("keycloak")
        redirect_from_provider("keycloak")

        expect(response).to have_http_status :found
        expect(response.location).to match /\/login$/
        expect(flash[:error]).to include "User registration is limited for the Single sign-on provider 'keycloak'"

        user = User.find_by(mail: user_info[:email])
        expect(user).to be_nil
      end
    end

    context "with self-registration manual and provider respecting that",
            with_settings: {
              self_registration: 2
            } do
      let(:limit_self_registration) { true }

      it "does not allow registration" do
        click_on_signin("keycloak")
        redirect_from_provider("keycloak")

        expect(response).to have_http_status :found
        expect(response.location).to match /\/login$/
        expect(flash[:notice]).to eq "Your account was created and is now pending administrator approval."

        user = User.find_by(mail: user_info[:email])
        expect(user).to be_registered
        expect(user).not_to be_active
      end
    end

    context "with self-registration disabled and provider ignoring that",
            with_settings: {
              self_registration: 0
            } do
      let(:limit_self_registration) { false }

      it "does not allow registration" do
        click_on_signin("keycloak")
        redirect_from_provider("keycloak")

        expect(response).to have_http_status :found
        expect(response.location).to match /\/\?first_time_user=true$/

        user = User.find_by(mail: user_info[:email])
        expect(user).to be_active
      end
    end

    context "with a custom attribute mapping" do
      let!(:provider) do
        create(:oidc_provider,
               slug: "keycloak",
               limit_self_registration:,
               mapping_login: :foobar)
      end

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

      it "maps to the login" do
        click_on_signin("keycloak")
        redirect_from_provider("keycloak")

        user = User.find_by(login: "a.truly.random.value")
        expect(user).to be_present
      end
    end
  end
end

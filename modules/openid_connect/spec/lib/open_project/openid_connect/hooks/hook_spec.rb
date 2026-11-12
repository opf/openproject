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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe OpenProject::OpenIDConnect::Hooks::Hook do
  describe "#omniauth_user_authorized" do
    subject(:call_hook) { described_class.instance.omniauth_user_authorized(context) }

    let(:context) { { controller:, auth_hash: } }
    let(:controller) { instance_double(ActionController::Base, session:) }
    let(:session) { {} }

    let(:existing_provider) { create(:oidc_provider, slug: "oidc-foo") }

    let(:auth_hash) { { provider: "oidc-foo", credentials: { token:, refresh_token:, expires_in: } } }
    let(:token) { "an-access-token" }
    let(:refresh_token) { "a-refresh-token" }
    let(:expires_in) { 3600 }

    before do
      existing_provider.save!
    end

    it "populates the session with token information", :aggregate_failures do
      call_hook

      expect(session["omniauth.oidc_access_token"]).to eq(token)
      expect(session["omniauth.oidc_refresh_token"]).to eq(refresh_token)
      expect(session["omniauth.oidc_expires_in"]).to eq(expires_in)
    end

    context "when the provider indicated in the auth hash can't be found" do
      let(:existing_provider) { create(:oidc_provider, slug: "oidc-bar") }

      it "does not change the session at all" do
        call_hook

        expect(session).to be_empty
      end
    end

    context "when expires_in is missing" do
      let(:expires_in) { nil }

      it "does not store an expires_in" do
        call_hook

        expect(session["omniauth.oidc_expires_in"]).to be_nil
      end
    end

    context "when expires_in is passed as a string" do
      let(:expires_in) { "7200" }

      it "stores expires_in as integer" do
        call_hook

        expect(session["omniauth.oidc_expires_in"]).to eq(7200)
      end
    end
  end

  describe "#user_logged_in" do
    subject(:call_hook) { described_class.instance.user_logged_in(context) }

    let(:context) { { session:, user: } }
    let(:session) do
      {
        "omniauth.oidc_access_token" => access_token,
        "omniauth.oidc_refresh_token" => refresh_token,
        "omniauth.oidc_expires_in" => expires_in
      }
    end
    let(:user) { build_stubbed(:user) }

    let(:access_token) { "an-access-token" }
    let(:refresh_token) { "a-refresh-token" }
    let(:expires_in) { 3600 }

    let(:create_service) { instance_double(OpenIDConnect::UserTokens::CreateService, call: nil) }
    let(:session_mapper) { class_double(OpenProject::OpenIDConnect::SessionMapper, handle_login: nil) }

    before do
      allow(OpenIDConnect::UserTokens::CreateService).to receive(:new).and_return(create_service)
      session_mapper.as_stubbed_const
    end

    it "calls UserTokens::CreateService", :aggregate_failures do
      call_hook

      expect(OpenIDConnect::UserTokens::CreateService).to have_received(:new).with(user)
      expect(create_service).to have_received(:call).with(
        access_token:,
        refresh_token:,
        expires_in:,
        known_audiences: [OpenIDConnect::UserToken::IDP_AUDIENCE],
        clear_previous: true
      )
    end

    it "calls SessionMapper" do
      call_hook

      expect(session_mapper).to have_received(:handle_login).with(session)
    end

    context "when there is no token data" do
      let(:session) { {} }

      it "does not call UserTokens::CreateService", :aggregate_failures do
        call_hook

        expect(OpenIDConnect::UserTokens::CreateService).not_to have_received(:new)
        expect(create_service).not_to have_received(:call)
      end

      it "calls SessionMapper anyways" do
        call_hook

        expect(session_mapper).to have_received(:handle_login).with(session)
      end
    end

    context "when there is no refresh token or expires_in" do
      let(:session) do
        {
          "omniauth.oidc_access_token" => access_token
        }
      end

      it "calls UserTokens::CreateService", :aggregate_failures do
        call_hook

        expect(OpenIDConnect::UserTokens::CreateService).to have_received(:new).with(user)
        expect(create_service).to have_received(:call).with(
          access_token:,
          refresh_token: nil,
          expires_in: nil,
          known_audiences: [OpenIDConnect::UserToken::IDP_AUDIENCE],
          clear_previous: true
        )
      end

      it "calls SessionMapper" do
        call_hook

        expect(session_mapper).to have_received(:handle_login).with(session)
      end
    end
  end
end

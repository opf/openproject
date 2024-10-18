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

RSpec.describe "OIDC administration CRUD",
               :js,
               :with_cuprite do
  shared_let(:user) { create(:admin) }
  let(:danger_zone) { DangerZone.new(page) }

  before do
    login_as(user)
  end

  context "with EE", with_ee: %i[sso_auth_providers] do
    it "can manage OIDC providers through the UI" do
      visit "/admin/openid_connect/providers"
      expect(page).to have_text "No OpenID providers configured yet."
      click_link_or_button "OpenID provider"
      click_link_or_button "Custom"

      fill_in "Display name", with: "My provider"
      click_link_or_button "Continue"

      # Skip metadata
      click_link_or_button "Continue"

      # Fill out configuration
      fill_in "Authorization endpoint", with: "https://example.com/sso"
      fill_in "User information endpoint", with: "https://example.com/sso/userinfo"
      fill_in "Token endpoint", with: "https://example.com/sso/token"
      fill_in "Issuer", with: "foobar"

      click_link_or_button "Continue"

      # Client credentials
      fill_in "Client ID", with: "client_id"
      fill_in "Client secret", with: "client secret"

      click_link_or_button "Continue"

      # Mapping form
      fill_in "Mapping for: Username", with: "login"
      fill_in "Mapping for: Email", with: "mail"
      fill_in "Mapping for: First name", with: "myName"
      fill_in "Mapping for: Last name", with: "myLastName"

      click_link_or_button "Continue"

      # Claims
      fill_in "Claims", with: '{"foo": "bar"}'
      fill_in "ACR values", with: "foo bar"

      click_link_or_button "Finish setup"

      # We're now on the show page
      within_test_selector("openid_connect_provider_metadata") do
        expect(page).to have_text "Not configured"
      end

      # Back to index
      visit "/admin/openid_connect/providers"
      expect(page).to have_text "My provider"
      expect(page).to have_css(".users", text: 0)
      expect(page).to have_css(".creator", text: user.name)

      click_link_or_button "My provider"

      provider = OpenIDConnect::Provider.find_by!(display_name: "My provider")
      expect(provider.slug).to eq "oidc-my-provider"
      expect(provider.authorization_endpoint).to eq "https://example.com/sso"
      expect(provider.token_endpoint).to eq "https://example.com/sso/token"
      expect(provider.userinfo_endpoint).to eq "https://example.com/sso/userinfo"

      expect(provider.issuer).to eq "foobar"
      expect(provider.client_id).to eq "client_id"
      expect(provider.client_secret).to eq "client secret"

      expect(provider.mapping_login).to eq "login"
      expect(provider.mapping_email).to eq "mail"
      expect(provider.mapping_first_name).to eq "myName"
      expect(provider.mapping_last_name).to eq "myLastName"

      click_link_or_button "Delete"
      # Confirm the deletion
      # Without confirmation, the button is disabled
      expect(danger_zone).to be_disabled

      # With wrong confirmation, the button is disabled
      danger_zone.confirm_with("foo")

      expect(danger_zone).to be_disabled

      # With correct confirmation, the button is enabled
      # and the project can be deleted
      danger_zone.confirm_with(provider.display_name)
      expect(danger_zone).not_to be_disabled
      danger_zone.danger_button.click

      expect(page).to have_text "No OpenID providers configured yet."
      expect { provider.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it "can import metadata from URL", :webmock do
      visit "/admin/openid_connect/providers"

      click_link_or_button "OpenID provider"
      click_link_or_button "Custom"

      fill_in "Display name", with: "My provider"
      click_link_or_button "Continue"

      url = "https://example.com/metadata"
      metadata = Rails.root.join("modules/openid_connect/spec/fixtures/keycloak_localhost.json").read
      stub_request(:get, url).to_return(status: 200, body: metadata, headers: { "Content-Type" => "application/json" })

      choose "I have a discovery endpoint URL"
      fill_in "openid_connect_provider_metadata_url", with: url

      click_link_or_button "Continue"
      expect(page).to have_text "The information has been pre-filled using the supplied discovery endpoint."
      expect(page).to have_field "Authorization endpoint", with: "http://localhost:8080/realms/test/protocol/openid-connect/auth"
      expect(page).to have_field "Token endpoint", with: "http://localhost:8080/realms/test/protocol/openid-connect/token"
      expect(page).to have_field "User information endpoint", with: "http://localhost:8080/realms/test/protocol/openid-connect/userinfo"
      expect(page).to have_field "End session endpoint", with: "http://localhost:8080/realms/test/protocol/openid-connect/logout"
      expect(page).to have_field "Issuer", with: "http://localhost:8080/realms/test"

      expect(WebMock).to have_requested(:get, url)
    end

    context "when provider exists already" do
      let!(:provider) { create(:oidc_provider, display_name: "My provider") }

      it "shows an error trying to use the same name" do
        visit "/admin/openid_connect/providers/new"
        fill_in "Display name", with: "My provider"
        click_link_or_button "Continue"

        expect(page).to have_text "Display name has already been taken."
      end
    end
  end

  context "without EE", without_ee: %i[sso_auth_providers] do
    it "renders the upsale page" do
      visit "/admin/openid_connect/providers"
      expect(page).to have_text "OpenID providers is an Enterprise  add-on"
    end
  end
end

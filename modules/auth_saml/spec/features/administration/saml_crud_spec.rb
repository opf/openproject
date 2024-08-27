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

RSpec.describe "SAML administration CRUD",
               :js,
               :with_cuprite do
  shared_let(:user) { create(:admin) }

  before do
    login_as(user)
  end

  context "with EE", with_ee: %i[sso_auth_providers] do
    it "can manage SAML providers through the UI" do
      visit "/admin/saml/providers"
      expect(page).to have_text "No SAML providers configured yet."
      click_link_or_button "SAML identity provider"

      fill_in "Name", with: "My provider"
      click_link_or_button "Continue"

      expect(page).to have_css("h1", text: "My provider")

      # Skip metadata
      click_link_or_button "Continue"

      # Fill out configuration
      fill_in "Identity provider login endpoint", with: "https://example.com/sso"
      fill_in "Identity provider logout endpoint", with: "https://example.com/slo"
      fill_in "Public certificate of identity provider", with: CertificateHelper.valid_certificate.to_pem

      click_link_or_button "Continue"

      # Encryption form
      check "Sign SAML AuthnRequests"
      fill_in "Certificate used by OpenProject for SAML requests", with: CertificateHelper.valid_certificate.to_pem
      fill_in "Corresponding private key for OpenProject SAML requests", with: CertificateHelper.private_key.private_to_pem

      click_link_or_button "Continue"

      # Mapping form
      fill_in "Mapping for: Username", with: "login\nmail", fill_options: { clear: :backspace }
      fill_in "Mapping for: Email", with: "mail", fill_options: { clear: :backspace }
      fill_in "Mapping for: First name", with: "myName", fill_options: { clear: :backspace }
      fill_in "Mapping for: Last name", with: "myLastName", fill_options: { clear: :backspace }
      fill_in "Mapping for: Internal user id", with: "uid", fill_options: { clear: :backspace }

      click_link_or_button "Continue"

      # Skip requested attributes form
      click_link_or_button "Finish setup"

      # We're now on the show page
      within_test_selector("saml_provider_metadata") do
        expect(page).to have_text "Not configured"
      end

      # Back to index
      visit "/admin/saml/providers"
      expect(page).to have_text "My provider"
      expect(page).to have_css(".users", text: 0)
      expect(page).to have_css(".creator", text: user.name)

      click_link_or_button "My provider"

      provider = Saml::Provider.find_by!(display_name: "My provider")
      expect(provider.slug).to eq "saml-my-provider"
      expect(provider.idp_cert.strip.gsub("\r\n", "\n")).to eq CertificateHelper.valid_certificate.to_pem.strip
      expect(provider.certificate.strip.gsub("\r\n", "\n")).to eq CertificateHelper.valid_certificate.to_pem.strip
      expect(provider.private_key.strip.gsub("\r\n", "\n")).to eq CertificateHelper.private_key.private_to_pem.strip
      expect(provider.idp_sso_service_url).to eq "https://example.com/sso"
      expect(provider.idp_slo_service_url).to eq "https://example.com/slo"
      expect(provider.mapping_login).to eq "login\nmail"
      expect(provider.mapping_mail).to eq "mail"
      expect(provider.mapping_firstname).to eq "myName"
      expect(provider.mapping_lastname).to eq "myLastName"
      expect(provider.mapping_uid).to eq "uid"
      expect(provider.authn_requests_signed).to be true

      accept_confirm do
        click_link_or_button "Delete"
      end

      expect(page).to have_text "No SAML providers configured yet."
    end

    it "can import metadata from XML" do
      visit "/admin/saml/providers/new"
      fill_in "Name", with: "My provider"
      click_link_or_button "Continue"

      choose "Metadata XML"

      metadata = Rails.root.join("modules/auth_saml/spec/fixtures/idp_metadata.xml").read
      fill_in "saml_provider_metadata_xml", with: metadata

      click_link_or_button "Continue"
      expect(page).to have_text "This information has been pre-filled using the supplied metadata."
      expect(page).to have_field "Service entity ID", with: "http://#{Setting.host_name}/"
      expect(page).to have_field "Identity provider login endpoint", with: "https://example.com/login"
      expect(page).to have_field "Identity provider logout endpoint", with: "https://example.com/logout"
    end

    it "can import metadata from URL", :webmock do
      visit "/admin/saml/providers/new"
      fill_in "Name", with: "My provider"
      click_link_or_button "Continue"

      url = "https://example.com/metadata"
      metadata = Rails.root.join("modules/auth_saml/spec/fixtures/idp_metadata.xml").read
      stub_request(:get, url).to_return(status: 200, body: metadata)

      choose "Metadata URL"

      fill_in "saml_provider_metadata_url", with: url

      click_link_or_button "Continue"
      expect(page).to have_text "This information has been pre-filled using the supplied metadata."
      expect(page).to have_field "Service entity ID", with: "http://#{Setting.host_name}/"
      expect(page).to have_field "Identity provider login endpoint", with: "https://example.com/login"
      expect(page).to have_field "Identity provider logout endpoint", with: "https://example.com/logout"

      expect(WebMock).to have_requested(:get, url)
    end

    context "when provider exists already" do
      let!(:provider) { create(:saml_provider, display_name: "My provider") }

      it "shows an error trying to use the same name" do
        visit "/admin/saml/providers/new"
        fill_in "Name", with: "My provider"
        click_link_or_button "Continue"

        expect(page).to have_text "Display name has already been taken."
      end
    end
  end

  context "without EE", without_ee: %i[sso_auth_providers] do
    it "renders the upsale page" do
      visit "/admin/saml/providers"
      expect(page).to have_text "SAML identity providers is an Enterprise  add-on"
    end
  end
end

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
require_module_spec_helper

RSpec.describe "SAML metadata refresh", :skip_csrf, :webmock,
               type: :rails_request, with_ee: %i[sso_auth_providers] do
  let(:admin) { create(:admin) }
  let(:metadata_url) { "https://example.com/metadata" }
  let(:metadata) { Rails.root.join("modules/auth_saml/spec/fixtures/idp_metadata.xml").read }
  let(:provider) { create(:saml_provider, :with_encryption, metadata_url:, last_metadata_update: 1.day.ago) }
  let(:metadata_token) { page.find("input[name='metadata_token']", visible: :all).value }

  before do
    login_as admin
    allow(OpenProject::SsrfProtection).to receive(:safe_ip?).with("example.com").and_return(IPAddr.new("93.184.216.34"))
    stub_request(:get, metadata_url).to_return(status: 200, body: metadata)
  end

  it "offers a refresh action in the side panel" do
    get saml_provider_path(provider)

    expect(page.find(:test_id, "saml_provider_refresh_metadata"))
      .to have_link("Refresh metadata", href: refresh_metadata_saml_provider_path(provider))
    expect(page.find(:test_id, "saml_provider_metadata")).to have_no_link("Refresh metadata")
  end

  it "previews the fetched changes without saving them" do
    original_options = provider.options.deep_dup

    get refresh_metadata_saml_provider_path(provider)

    expect(response).to have_http_status(:ok)
    expect(page).to have_heading("Review metadata changes")
    expect(page).to have_text("https://example.com/sso")
    expect(page).to have_text("https://example.com/login")
    expect(page).to have_text("Public certificate of identity provider")
    expect(page).to have_button("Apply changes")
    expect(page).to have_link("Cancel", href: saml_provider_path(provider))
    expect(provider.reload.options).to eq(original_options)
  end

  it "applies the reviewed endpoints and certificate without fetching metadata again" do
    original_options = provider.options.deep_dup
    get refresh_metadata_saml_provider_path(provider)
    token = metadata_token
    stub_request(:get, metadata_url).to_return(status: 200, body: metadata.gsub("/login", "/other-login"))

    post apply_metadata_saml_provider_path(provider), params: { metadata_token: token }

    expect(response).to redirect_to(saml_provider_path(provider))
    expect(flash[:notice]).to eq(I18n.t("saml.metadata_parser.success"))
    provider.reload
    expect(provider.idp_sso_service_url).to eq("https://example.com/login")
    expect(provider.idp_slo_service_url).to eq("https://example.com/logout")
    expect(provider.idp_entity_id).to eq("urn:dev-example.com")
    certificate = Nokogiri::XML(metadata).at_xpath("//*[local-name()='X509Certificate']").text
    expect(provider.idp_cert).to eq(OneLogin::RubySaml::Utils.format_cert(certificate))
    expect(provider.last_metadata_update).to be > 1.minute.ago
    expect(provider.metadata_url).to eq(metadata_url)
    expect(provider.options.slice("mapping_login", "mapping_mail", "certificate", "private_key", "authn_requests_signed"))
      .to eq(original_options.slice("mapping_login", "mapping_mail", "certificate", "private_key", "authn_requests_signed"))
    expect(WebMock).to have_requested(:get, metadata_url).once
  end

  it "leaves the configuration unchanged when cancelling" do
    original_options = provider.options.deep_dup
    get refresh_metadata_saml_provider_path(provider)

    get saml_provider_path(provider)

    expect(provider.reload.options).to eq(original_options)
  end

  it "reports when the fetched metadata matches the current configuration" do
    get refresh_metadata_saml_provider_path(provider)
    post apply_metadata_saml_provider_path(provider), params: { metadata_token: }

    get refresh_metadata_saml_provider_path(provider)

    expect(page).to have_text("The metadata matches the current configuration.")
  end

  it "leaves the configuration unchanged when fetching metadata fails" do
    original_options = provider.options.deep_dup
    stub_request(:get, metadata_url).to_return(status: 500)

    get refresh_metadata_saml_provider_path(provider)

    expect(response).to redirect_to(saml_provider_path(provider))
    expect(flash[:error]).to include("Failed to retrieve the identity provider metadata")
    expect(provider.reload.options).to eq(original_options)
  end

  it "rejects malformed metadata without changing the configuration" do
    original_options = provider.options.deep_dup
    stub_request(:get, metadata_url).to_return(status: 200, body: "<invalid>")

    get refresh_metadata_saml_provider_path(provider)

    expect(response).to redirect_to(saml_provider_path(provider))
    expect(flash[:error]).to include("Failed to retrieve the identity provider metadata")
    expect(provider.reload.options).to eq(original_options)
  end

  it "blocks unsafe metadata hosts" do
    allow(OpenProject::SsrfProtection).to receive(:safe_ip?).with("example.com").and_return(nil)

    get refresh_metadata_saml_provider_path(provider)

    expect(response).to redirect_to(saml_provider_path(provider))
    expect(flash[:error]).to include("MetadataHostNotAllowedError")
    expect(WebMock).not_to have_requested(:get, metadata_url)
  end

  it "rejects a modified preview token" do
    get refresh_metadata_saml_provider_path(provider)
    token = "#{metadata_token}invalid"
    original_options = provider.reload.options.deep_dup

    post apply_metadata_saml_provider_path(provider), params: { metadata_token: token }

    expect(flash[:error]).to eq(I18n.t("saml.providers.apply_metadata.expired"))
    expect(provider.reload.options).to eq(original_options)
  end

  it "rejects a missing preview token" do
    post apply_metadata_saml_provider_path(provider)

    expect(flash[:error]).to eq(I18n.t("saml.providers.apply_metadata.expired"))
  end

  it "rejects an expired preview" do
    get refresh_metadata_saml_provider_path(provider)
    token = metadata_token
    original_options = provider.reload.options.deep_dup

    travel 16.minutes do
      post apply_metadata_saml_provider_path(provider), params: { metadata_token: token }
    end

    expect(flash[:error]).to eq(I18n.t("saml.providers.apply_metadata.expired"))
    expect(provider.reload.options).to eq(original_options)
  end

  it "rejects a preview if the provider has since changed" do
    get refresh_metadata_saml_provider_path(provider)
    token = metadata_token
    provider.update!(idp_sso_service_url: "https://example.com/changed")

    post apply_metadata_saml_provider_path(provider), params: { metadata_token: token }

    expect(flash[:error]).to eq(I18n.t("saml.providers.apply_metadata.provider_changed"))
    expect(provider.reload.idp_sso_service_url).to eq("https://example.com/changed")
  end

  it "rejects a preview for a different provider" do
    get refresh_metadata_saml_provider_path(provider)
    token = metadata_token
    other_provider = create(:saml_provider, metadata_url:)

    post apply_metadata_saml_provider_path(other_provider), params: { metadata_token: token }

    expect(flash[:error]).to eq(I18n.t("saml.providers.apply_metadata.expired"))
    expect(other_provider.reload.idp_sso_service_url).to eq("https://example.com/sso")
  end

  context "without a metadata URL" do
    let(:provider) { create(:saml_provider, metadata_xml: metadata) }

    it "does not offer or allow refreshing" do
      get saml_provider_path(provider)
      expect(page).to have_no_link("Refresh metadata")

      get refresh_metadata_saml_provider_path(provider)
      expect(response).to have_http_status(:not_found)

      post apply_metadata_saml_provider_path(provider)
      expect(response).to have_http_status(:not_found)
    end
  end

  context "with an environment-managed provider" do
    before do
      allow(Setting).to receive(:seed_saml_provider).and_return({ provider.slug => {} })
    end

    it "does not offer or allow refreshing" do
      get saml_provider_path(provider)
      expect(page).to have_no_link("Refresh metadata")

      get refresh_metadata_saml_provider_path(provider)
      expect(response).to redirect_to(saml_provider_path(provider))

      post apply_metadata_saml_provider_path(provider)
      expect(response).to redirect_to(saml_provider_path(provider))
      expect(WebMock).not_to have_requested(:get, metadata_url)
    end
  end

  context "without admin permissions" do
    let(:admin) { create(:user) }

    it "does not allow previewing or applying metadata" do
      get refresh_metadata_saml_provider_path(provider)
      expect(response).to have_http_status(:forbidden)

      post apply_metadata_saml_provider_path(provider)
      expect(response).to have_http_status(:forbidden)
      expect(WebMock).not_to have_requested(:get, metadata_url)
    end
  end

  context "without Enterprise", with_ee: [] do
    it "does not allow previewing or applying metadata" do
      get refresh_metadata_saml_provider_path(provider)
      expect(response).to redirect_to(saml_providers_path)

      post apply_metadata_saml_provider_path(provider)
      expect(response).to redirect_to(saml_providers_path)
      expect(WebMock).not_to have_requested(:get, metadata_url)
    end
  end
end

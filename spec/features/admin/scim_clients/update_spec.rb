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

RSpec.describe "Updating a SCIM client", :js, :selenium, driver: :firefox_de do
  shared_let(:admin) { create(:admin, preferences: { time_zone: "Etc/UTC" }) }
  shared_let(:auth_provider) { create(:oidc_provider) }

  let(:sso_scim_client) { create(:scim_client, auth_provider:) }
  let(:oauth_client_scim_client) { create(:scim_client, :oauth2_client, auth_provider:) }
  let(:token_scim_client) { create(:scim_client, :oauth2_token, auth_provider:) }

  let!(:static_tokens) do
    application = token_scim_client.oauth_application
    [
      create(:oauth_access_token, application:, created_at: 2.weeks.ago, expires_in: 2.days.to_i),
      create(:oauth_access_token, application:, created_at: 1.week.ago, expires_in: 2.weeks.to_i)
    ]
  end

  current_user { admin }

  it "can update a SCIM client authenticating through JWT", :aggregate_failures, with_ee: [:scim_api] do
    visit edit_admin_scim_client_path(sso_scim_client)
    expect(page).to be_axe_clean.within("#content")

    expect(page.find_field("Authentication method", disabled: :all)).to be_disabled
    fill_in "Name", with: ""
    fill_in "Subject claim", with: ""
    click_on "Save"

    expect(page).to have_text("Name can't be blank")
    expect(page).to have_text("Subject claim can't be blank")

    fill_in "Name", with: "New SSO name"
    fill_in "Subject claim", with: "new-claim"
    click_on "Save"

    expect(page).to have_current_path(admin_scim_clients_path)
    within_test_selector("Admin::ScimClients::TableComponent") do
      expect(page).to have_text("New SSO name")
    end

    visit edit_admin_scim_client_path(sso_scim_client)

    within(".PageHeader") { click_on "Delete" }
    page.within_modal("Delete SCIM client") { click_on "Delete" }
    expect(page).to have_current_path(admin_scim_clients_path)
    expect(ScimClient.where(id: sso_scim_client.id)).to be_empty
  end

  it "can update a SCIM client authenticating through client credentials", :aggregate_failures, with_ee: [:scim_api] do
    visit edit_admin_scim_client_path(oauth_client_scim_client)
    expect(page).to be_axe_clean.within("#content")

    expect(page.find_field("Authentication method", disabled: :all)).to be_disabled
    fill_in "Name", with: ""
    click_on "Save"

    expect(page).to have_text("Name can't be blank")

    fill_in "Name", with: "New client credentials name"
    click_on "Save"

    expect(page).to have_current_path(admin_scim_clients_path)
    within_test_selector("Admin::ScimClients::TableComponent") do
      expect(page).to have_text("New client credentials name")
    end

    visit edit_admin_scim_client_path(oauth_client_scim_client)

    expect(page).to have_field("Client ID", with: oauth_client_scim_client.oauth_application.uid)
    expect(page).to have_no_field("Client secret")

    within(".PageHeader") { click_on "Delete" }
    page.within_modal("Delete SCIM client") { click_on "Delete" }
    expect(page).to have_current_path(admin_scim_clients_path)
    expect(ScimClient.where(id: oauth_client_scim_client.id)).to be_empty
  end

  it "can update a SCIM client authenticating through a static access token", :aggregate_failures, with_ee: [:scim_api] do
    visit edit_admin_scim_client_path(token_scim_client)
    expect(page).to be_axe_clean.within("#content")

    expect(page.find_field("Authentication method", disabled: :all)).to be_disabled
    fill_in "Name", with: ""
    click_on "Save"

    expect(page).to have_text("Name can't be blank")

    fill_in "Name", with: "New static token name"
    click_on "Save"

    expect(page).to have_current_path(admin_scim_clients_path)
    within_test_selector("Admin::ScimClients::TableComponent") do
      expect(page).to have_text("New static token name")
    end

    visit edit_admin_scim_client_path(token_scim_client)

    within_test_selector("Admin::ScimClients::TokenTableComponent") do
      expect(page).to have_css(".created_at").twice
      expect(page).to have_css(".expires_at").twice
      expect(page).to have_text("Expired on").once
      expect(page).to have_no_text("Revoked on")

      expect(page).to have_test_selector("op-scim-clients--revoke-token-button").once
      page.find_test_selector("op-scim-clients--revoke-token-button").click
    end

    page.within_modal("Revoke static token") { click_on "Revoke" }

    within_test_selector("Admin::ScimClients::TokenTableComponent") do
      expect(page).to have_text("Revoked on").once
      expect(page).to have_no_test_selector("op-scim-clients--revoke-token-button")
    end

    page.find_test_selector("op-scim-clients--add-token-button").click
    within_modal("Token created") do
      plaintext_token = page.find_field("Token").value
      hashed_token = Doorkeeper::AccessToken.last.token
      expect(plaintext_token).to be_present
      expect(Digest::SHA256.hexdigest(plaintext_token)).to eq(hashed_token)
      click_on("Close")
    end
    within_test_selector("Admin::ScimClients::TokenTableComponent") do
      expect(page).to have_css(".created_at").exactly(3).times
      expect(page).to have_css(".expires_at").exactly(3).times

      expect(page).to have_test_selector("op-scim-clients--revoke-token-button").once
    end

    within(".PageHeader") { click_on "Delete" }
    page.within_modal("Delete SCIM client") { click_on "Delete" }
    expect(page).to have_current_path(admin_scim_clients_path)
    expect(ScimClient.where(id: token_scim_client.id)).to be_empty
  end
end

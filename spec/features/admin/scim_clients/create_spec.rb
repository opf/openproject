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

RSpec.describe "Creating a SCIM client", :js, :selenium, driver: :firefox_de do
  shared_let(:admin) { create(:admin, preferences: { time_zone: "Etc/UTC" }) }
  shared_let(:oidc_provider) { create(:oidc_provider) }

  current_user { admin }

  it "can create a SCIM client authenticating through JWT", :aggregate_failures, with_ee: [:scim_api] do
    visit new_admin_scim_client_path

    expect(page).to be_axe_clean.within("#content")

    expect(page).to have_no_field("Subject claim")
    select "JWT from identity provider", from: "Authentication method"
    expect(page).to have_field("Subject claim")

    select oidc_provider.display_name, from: "Authentication provider"

    click_on("Create") # forgot to fill out form
    expect(page).to have_text("Name can't be blank")
    expect(page).to have_text("Subject claim can't be blank")

    fill_in "Name", with: "My SCIM Client"
    fill_in "Subject claim", with: "123-abc-456-def"
    click_on("Create")
    wait_for { ScimClient.find_by(name: "My SCIM Client") }.not_to be_nil

    created_client = ScimClient.find_by(name: "My SCIM Client")
    expect(page).to have_current_path(edit_admin_scim_client_path(created_client, first_time_setup: true))
    expect(created_client.auth_provider_id).to eq(oidc_provider.id)
    expect(created_client.authentication_method).to eq("sso")
    expect(created_client.auth_provider_link&.external_id).to eq("123-abc-456-def")
  end

  it "can create a SCIM client authenticating through client credentials", with_ee: [:scim_api] do
    visit new_admin_scim_client_path

    fill_in "Name", with: "My SCIM Client"
    select oidc_provider.display_name, from: "Authentication provider"
    select "OAuth 2.0 client credentials", from: "Authentication method"

    click_on("Create")
    wait_for { ScimClient.find_by(name: "My SCIM Client") }.not_to be_nil

    created_client = ScimClient.find_by(name: "My SCIM Client")
    expect(page).to have_current_path(edit_admin_scim_client_path(created_client, first_time_setup: true))

    page.within_modal("Client credentials created") do
      expect(page).to have_field("Client ID", with: created_client.oauth_application.uid)
      plaintext_secret = page.find_field("Client secret").value
      hashed_secret = created_client.oauth_application.secret
      expect(Digest::SHA256.hexdigest(plaintext_secret)).to eq(hashed_secret)
    end
  end

  it "can create a SCIM client authenticating through a static access token", with_ee: [:scim_api] do
    visit new_admin_scim_client_path

    fill_in "Name", with: "My SCIM Client"
    select oidc_provider.display_name, from: "Authentication provider"
    select "Static access token", from: "Authentication method"

    click_on("Create")
    wait_for { ScimClient.find_by(name: "My SCIM Client") }.not_to be_nil

    created_client = ScimClient.find_by(name: "My SCIM Client")
    expect(page).to have_current_path(edit_admin_scim_client_path(created_client, first_time_setup: true))

    page.within_modal("Token created") do
      plaintext_token = page.find_field("Token").value
      hashed_token = created_client.oauth_application.access_tokens.last.token
      expect(plaintext_token).to be_present
      expect(Digest::SHA256.hexdigest(plaintext_token)).to eq(hashed_token)
    end
  end
end

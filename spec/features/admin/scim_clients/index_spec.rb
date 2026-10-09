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

RSpec.describe "Listing SCIM clients", :js, :selenium, driver: :firefox_de do
  shared_let(:admin) { create(:admin, preferences: { time_zone: "Etc/UTC" }) }

  current_user { admin }

  context "when using an insufficient enterprise token" do
    it "renders an enterprise banner and no table" do
      visit admin_scim_clients_path

      expect(page).to be_axe_clean.within("#content")

      expect(page).to have_enterprise_banner(:corporate)
      expect(page).to have_no_test_selector("Admin::ScimClients::TableComponent")

      within(".SubHeader") do
        expect(page).to have_no_link("SCIM client")
      end
    end
  end

  context "when there are no SCIM clients", with_ee: [:scim_api] do
    it "renders a proper blank slate" do
      visit admin_scim_clients_path

      expect(page).to be_axe_clean.within "#content"

      expect(page).not_to have_enterprise_banner
      within_test_selector("Admin::ScimClients::TableComponent") do
        expect(page).to have_content("No SCIM clients configured yet")
        expect(page).to have_content("Add clients to see them here")
      end

      within(".SubHeader") do
        click_on "SCIM client"
      end

      expect(page).to have_current_path(new_admin_scim_client_path)
    end
  end

  context "when there are SCIM clients", with_ee: [:scim_api] do
    let!(:sso_client) { create(:scim_client) }

    it "renders a proper clients table" do
      visit admin_scim_clients_path

      expect(page).to be_axe_clean.within "#content"

      expect(page).not_to have_enterprise_banner
      within_test_selector("Admin::ScimClients::TableComponent") do
        within(".name") { expect(page).to have_content(sso_client.name) }
        within(".authentication_method") { expect(page).to have_content("JWT from identity provider") }

        click_on(sso_client.name)
      end

      expect(page).to have_current_path(edit_admin_scim_client_path(sso_client))
    end
  end
end

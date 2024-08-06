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

RSpec.describe "CRUD LDAP connections", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }
  let(:ldap_page) { Pages::Admin::LdapAuthSources::Index.new }

  before do
    login_as(admin)
  end

  it "can create, modify, and delete LDAP connections" do
    ldap_page.visit!

    expect(page).to have_text "LDAP connections"
    expect(page).to have_text "There is currently nothing to display."

    page.find_test_selector("op-admin-ldap-connection--button-new", text: "LDAP connection").click

    expect(page).to have_current_path new_ldap_auth_source_path

    fill_in "ldap_auth_source_name", with: "My LDAP connection"
    fill_in "ldap_auth_source_host", with: "localhost"
    fill_in "ldap_auth_source_attr_login", with: "uid"

    click_on "Create"

    ldap_page.expect_and_dismiss_toaster message: "Successful creation."
    expect(page).to have_css("td.name", text: "My LDAP connection")
    expect(page).to have_css("td.host", text: "localhost")

    created_connection = LdapAuthSource.last
    connection = created_connection.dup
    connection.name = "Admin connection"
    connection.save!
    admin.update_column(:ldap_auth_source_id, connection.id)

    ldap_page.visit!
    expect(page).to have_text "My LDAP connection"
    expect(page).to have_text "Admin connection"

    page.within("#ldap-auth-source-#{created_connection.id}") do
      expect(page).to have_link "Delete"
      accept_prompt { click_on "Delete" }
    end

    ldap_page.expect_and_dismiss_toaster message: "Successful deletion."

    expect(page).to have_no_text "My LDAP connection"
    expect(page).to have_text "Admin connection"

    page.within("#ldap-auth-source-#{connection.id}") do
      expect(page).to have_no_link "Delete"
    end

    page.within("#ldap-auth-source-#{connection.id}") do
      click_on "Admin connection"
    end

    expect(page).to have_current_path edit_ldap_auth_source_path(connection)
    fill_in "ldap_auth_source_name", with: "Updated Admin connection"
    click_on "Save"

    ldap_page.expect_and_dismiss_toaster message: "Successful update."
    expect(page).to have_css("td.name", text: "Updated Admin connection")
  end

  context "when providing seed variables",
          :settings_reset,
          with_env: {
            OPENPROJECT_SEED_LDAP_FOOBAR_HOST: "localhost"
          } do
    let!(:ldap_auth_source) { create(:ldap_auth_source, name: "foobar") }

    it "blocks editing of that connection by name" do
      reset(:seed_ldap)

      ldap_page.visit!
      expect(page).to have_text "foobar"

      page.within("#ldap-auth-source-#{ldap_auth_source.id}") do
        click_on "foobar"
      end

      expect(page).to have_text(I18n.t(:label_seeded_from_env_warning))
      expect(page).to have_field("ldap_auth_source_name", with: "foobar", disabled: true)
      expect(page).to have_no_button "Save"
    end
  end
end

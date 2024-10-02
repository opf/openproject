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

RSpec.describe "OAuth applications management", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }

  before do
    login_as admin
  end

  it "can create, update, show and delete applications" do
    visit oauth_applications_path

    # Initially empty
    expect(page).to have_test_selector("op-admin-oauth--applications-placeholder")

    # Create application
    page.find_test_selector("op-admin-oauth--button-new", text: "OAuth application").click

    fill_in "application_name", with: "My API application"
    # Fill invalid redirect_uri
    fill_in "application_redirect_uri", with: "not a url!"
    click_on "Create"

    expect_flash(type: :error, message: "Redirect URI must be an absolute URI.")

    fill_in("application_redirect_uri", with: "")
    # Fill redirect_uri which does not provide a Secure Context
    fill_in "application_redirect_uri", with: "http://example.org"
    click_on "Create"

    expect_flash(type: :error, message: 'Redirect URI is not providing a "Secure Context"')

    # Can create localhost without https (https://community.openproject.com/wp/34025)
    fill_in "application_redirect_uri", with: "urn:ietf:wg:oauth:2.0:oob\nhttp://localhost/my/callback"
    click_on "Create"

    expect_flash(message: "Successful creation.")

    expect(page).to have_css(".attributes-key-value--key", text: "Client ID")
    expect(page).to have_css(".attributes-key-value--value", text: "urn:ietf:wg:oauth:2.0:oob\nhttp://localhost/my/callback")

    # Should print secret on initial visit
    expect(page).to have_css(".attributes-key-value--key", text: "Client secret")
    expect(page.first(".attributes-key-value--value code").text).to match /\w+/

    # Edit again
    click_on "Edit"

    fill_in "application_redirect_uri", with: "urn:ietf:wg:oauth:2.0:oob"
    click_on "Save"

    # Show application
    click_on "My API application"

    expect(page).to have_no_css(".attributes-key-value--key", text: "Client secret")
    expect(page).to have_no_css(".attributes-key-value--value code")
    expect(page).to have_css(".attributes-key-value--key", text: "Client ID")
    expect(page).to have_css(".attributes-key-value--value", text: "urn:ietf:wg:oauth:2.0:oob")

    accept_alert do
      click_on "Delete"
    end

    # Table is empty again
    expect(page).to have_test_selector("op-admin-oauth--applications-placeholder")
  end

  context "with a seeded application", with_flag: { built_in_oauth_applications: true } do
    before do
      OAuthApplicationsSeeder.new.seed_data!
    end

    it "does not allow editing or deleting the seeded application" do
      visit oauth_applications_path

      app = Doorkeeper::Application.last

      within_test_selector("op-admin-oauth--built-in-applications") do
        expect(page).to have_test_selector("op-admin-oauth--application", count: 1)
        expect(page).to have_link(text: "OpenProject Mobile App")
        expect(page).to have_test_selector("op-admin-oauth--application-enabled-toggle-switch", text: "Off")

        find_test_selector("op-admin-oauth--application-enabled-toggle-switch").click
        expect(page).not_to have_test_selector("op-admin-oauth--application-enabled-toggle-switch", text: "Loading")
        expect(page).to have_test_selector("op-admin-oauth--application-enabled-toggle-switch", text: "On")

        app.reload
        expect(app).to be_builtin
        expect(app).to be_enabled

        find_test_selector("op-admin-oauth--application-enabled-toggle-switch").click
        expect(page).not_to have_test_selector("op-admin-oauth--application-enabled-toggle-switch", text: "Loading")
        expect(page).to have_test_selector("op-admin-oauth--application-enabled-toggle-switch", text: "Off")

        app.reload
        expect(app).to be_builtin
        expect(app).not_to be_enabled

        click_on "OpenProject Mobile App"
      end

      expect(page).to have_no_button("Edit")
      expect(page).to have_no_button("Delete")

      visit edit_oauth_application_path(app)
      expect(page).to have_text "You are not authorized to access this page."
    end
  end
end

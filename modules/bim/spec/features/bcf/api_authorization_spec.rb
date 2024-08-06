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

RSpec.describe "authorization for BCF api", :js, with_config: { edition: "bim" } do
  let!(:user) { create(:admin) }
  let(:client_secret) { app.plaintext_secret }
  let(:scope) { "bcf_v2_1" }
  let!(:project) { create(:project, enabled_module_names: [:bim]) }

  def oauth_path(client_id)
    "/oauth/authorize?response_type=code&client_id=#{client_id}&redirect_uri=urn:ietf:wg:oauth:2.0:oob&scope=#{scope}"
  end

  before do
    login_with user.login, "adminADMIN!"

    visit oauth_applications_path
  end

  it "can create and later authorize and manage an OAuth application grant and then use the access token for the bcf api" do
    # Initially empty
    expect(page).to have_css(".generic-table--empty-row", text: "There is currently nothing to display")

    # Create application
    page.find_test_selector("op-admin-oauth--button-new", text: "OAuth application").click
    fill_in "application_name", with: "My API application"
    # Limit to bcf access
    check scope
    # Fill invalid redirect_uri
    fill_in "application_redirect_uri", with: "not a url!"
    click_on "Create"

    expect(page).to have_css(".errorExplanation", text: "Redirect URI must be an absolute URI.")
    fill_in "application_redirect_uri", with: "urn:ietf:wg:oauth:2.0:oob\nhttps://localhost/my/callback"
    click_on "Create"

    expect(page).to have_css(".op-toast.-success", text: "Successful creation.")

    expect(page).to have_css(".attributes-key-value--key",
                             text: "Client ID")
    expect(page).to have_css(".attributes-key-value--value",
                             text: "urn:ietf:wg:oauth:2.0:oob\nhttps://localhost/my/callback")

    # Should print secret on initial visit
    expect(page).to have_css(".attributes-key-value--key", text: "Client secret")
    client_secret = page.first(".attributes-key-value--value code").text
    expect(client_secret).to match /\w+/

    app = Doorkeeper::Application.first

    visit oauth_path app.uid

    # We get to the authorization screen
    expect(page).to have_css("h2", text: "Authorize My API application")

    # With the correct scope printed
    expect(page).to have_css("li strong", text: I18n.t("oauth.scopes.bcf_v2_1"))
    expect(page).to have_css("li", text: I18n.t("oauth.scopes.bcf_v2_1_text"))

    # Authorize
    find('input.button[value="Authorize"]').click

    # Expect auth token
    code = find_by_id("authorization_code").text

    # And also have a grant for this application
    user.oauth_grants.reload
    expect(user.oauth_grants.count).to eq 1
    expect(user.oauth_grants.first.application).to eq app

    parameters = {
      client_id: app.uid,
      client_secret:,
      code:,
      grant_type: :authorization_code,
      redirect_uri: app.redirect_uri.split.first
    }

    session = ActionDispatch::Integration::Session.new(Rails.application)
    response = session.post("/oauth/token", params: parameters)
    expect(response).to eq 200
    body = JSON.parse(session.response.body)

    expect(body["access_token"]).to be_present
    expect(body["refresh_token"]).to be_present
    expect(body["scope"]).to eq scope

    access_token = body["access_token"]

    # Should show that grant in my account
    visit my_account_path
    click_on "Access token"

    expect(page).to have_css("#oauth-application-grant-#{app.id}", text: app.name)
    expect(page).to have_css("td", text: app.name)

    # While being logged in, the api can be accessed with the session
    visit("/api/bcf/2.1/projects/#{project.id}")
    expect(page)
      .to have_content(JSON.dump({ project_id: project.id, name: project.name }))

    logout

    # A basic auth alert is displayed asking to enter name and password Register
    # some basic auth credentials
    # - A non-matching url is used so that capybara will issue a CancelAuth
    #   instead of trying to authenticate
    # - The register method is not recognized by selenium-webdriver with Chrome
    #   120 with old headless
    if page.driver.browser.respond_to?(:register)
      page.driver.browser.register(username: "foo", password: "bar", uri: /does_not_match/)
    end
    # While not being logged in and without a token, the api cannot be accessed
    visit("/api/bcf/2.1/projects/#{project.id}")
    # Cancel button of basic auth should have been chosen now
    expect(page)
      .to have_content(JSON.dump({ message: "You need to be authenticated to access this resource." }))

    ## Without the access token, access is denied
    api_session = ActionDispatch::Integration::Session.new(Rails.application)
    response = api_session.get("/api/bcf/2.1/projects/#{project.id}")
    expect(response).to eq 401

    # With the access token, access is allowed
    response = api_session.get("/api/bcf/2.1/projects/#{project.id}",
                               headers: { Authorization: "Bearer #{access_token}" })
    expect(response).to eq 200
    expect(api_session.response.body)
      .to be_json_eql({ project_id: project.id, name: project.name }.to_json)
  end
end

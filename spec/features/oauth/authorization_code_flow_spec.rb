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

RSpec.describe "OAuth authorization code flow", :js do
  let!(:user) { create(:user) }
  let!(:redirect_uri) { "urn:ietf:wg:oauth:2.0:oob" }
  let!(:allowed_redirect_uri) { redirect_uri }
  let!(:app) { create(:oauth_application, name: "Cool API app!", redirect_uri: allowed_redirect_uri) }
  let(:client_secret) { app.plaintext_secret }

  def oauth_path(client_id, redirect_url)
    "/oauth/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{CGI.escape(redirect_url)}&scope=api_v3"
  end

  def get_and_test_token(code)
    parameters = {
      client_id: app.uid,
      client_secret:,
      code:,
      grant_type: :authorization_code,
      redirect_uri: app.redirect_uri
    }

    session = ActionDispatch::Integration::Session.new(Rails.application)
    response = session.post("/oauth/token", params: parameters)
    expect(response).to eq 200
    body = JSON.parse(session.response.body)

    expect(body["access_token"]).to be_present
    expect(body["refresh_token"]).to be_present
    expect(body["scope"]).to eq "api_v3"
  end

  it "can authorize and manage an OAuth application grant" do
    visit oauth_path app.uid, redirect_uri

    # Expect we're guided to the login screen
    login_with user.login, "adminADMIN!", visit_signin_path: false

    # We get to the authorization screen
    expect(page).to have_css("h2", text: "Authorize Cool API app!")

    # With the correct scope printed
    expect(page).to have_css("li strong", text: I18n.t("oauth.scopes.api_v3"))
    expect(page).to have_css("li", text: I18n.t("oauth.scopes.api_v3_text"))

    SeleniumHubWaiter.wait
    # Authorize
    find('input.button[value="Authorize"]').click

    # Expect auth token
    code = find_by_id("authorization_code").text

    # And also have a grant for this application
    user.oauth_grants.reload
    expect(user.oauth_grants.count).to eq 1
    expect(user.oauth_grants.first.application).to eq app

    get_and_test_token(code)

    # Should show that grant in my account
    visit my_account_path
    click_on "Access token"

    expect(page).to have_css("#oauth-application-grant-#{app.id}", text: app.name)
    expect(page).to have_css("td", text: app.name)

    # Revoke the application
    within("#oauth-application-grant-#{app.id}") do
      SeleniumHubWaiter.wait
      find_test_selector("oauth-token-row-#{app.id}-revoke").click
    end

    page.driver.browser.switch_to.alert.accept

    # Should be back on access_token path
    expect(page).to have_css(".op-toast.-success")
    expect(page).to have_no_css("[id^=oauth-application-grant]")

    expect(page).to have_current_path /\/my\/access_token/

    # And all grants have been revoked
    authorized = Doorkeeper::Application.authorized_for(user)
    expect(authorized).to be_empty
  end

  it "does not authenticate unknown applications" do
    visit oauth_path "WAT", redirect_uri

    # Expect we're guided to the login screen
    login_with user.login, "adminADMIN!", visit_signin_path: false

    # But we got no further
    expect(page).to have_css(".op-toast.-error",
                             text: "Client authentication failed due to unknown client, no client authentication included, or unsupported authentication method.")

    # And also have no grant for this application
    user.oauth_grants.reload
    expect(user.oauth_grants.count).to eq 0
  end

  # Selenium can't return response headers
  context "in browser that can log response headers", js: false do
    before do
      login_as user
    end

    context "with real urls as allowed redirect uris" do
      let!(:redirect_uri) { "https://foo.com/foo" }
      let!(:allowed_redirect_uri) { "#{redirect_uri} https://bar.com/bar" }

      it "can authorize and manage an OAuth application grant" do
        visit oauth_path app.uid, redirect_uri

        # Check that the hosts of allowed redirection urls are present in the content security policy

        form_csp_header = page
                            .response_headers["content-security-policy"]
                            .split(";")
                            .find { |s| s.start_with?(" form-action") }

        expect(form_csp_header)
          .to include("'self'")

        expect(form_csp_header)
          .to include("foo.com")

        expect(form_csp_header)
          .to include("bar.com")
      end
    end
  end

  context "when redirecting to a stubbed foreign service", driver: :chrome_billy do
    let!(:redirect_uri) { "https://oauth.example.com/callback" }

    before do
      proxy
        .stub("https://oauth.example.com:443/callback")
        .and_return(code: 200, text: "Welcome to stubbed response")
    end

    it "can be authorized twice (Regression #34554)" do
      visit oauth_path app.uid, redirect_uri

      # Expect we're guided to the login screen
      login_with user.login, "adminADMIN!", visit_signin_path: false

      # We get to the authorization screen
      expect(page).to have_css("h2", text: "Authorize Cool API app!")

      # Authorize
      find('input.button[value="Authorize"]').click

      # Expect redirect to stubbed URL
      expect(page).to have_current_path(/#{Regexp.escape(redirect_uri)}\?code=.+$/, url: true)
      expect(page).to have_text "Welcome to stubbed response"

      # Get auth token from URL query
      code = page.current_url.match(/\?code=(.+)$/)[1]
      get_and_test_token(code)

      # Log out again
      logout

      # Try to reauthorize with existing grant
      visit oauth_path app.uid, redirect_uri

      # Expect we're guided to the login screen
      login_with user.login, "adminADMIN!", visit_signin_path: false

      # Expect redirect to stubbed URL
      expect(page).to have_current_path(/#{Regexp.escape(redirect_uri)}\?code=.+$/, url: true)
      expect(page).to have_text "Welcome to stubbed response"

      # Get auth token from URL query
      new_code = page.current_url.match(/\?code=(.+)$/)[1]
      get_and_test_token(new_code)
    end
  end
end

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

RSpec.describe "OAuth authorization code flow with PKCE", :js do
  let!(:user) { create(:user) }
  let!(:redirect_uri) { "urn:ietf:wg:oauth:2.0:oob" }
  let!(:allowed_redirect_uri) { redirect_uri }
  let!(:app) do
    create(:oauth_application,
           name: "Public mobile client",
           confidential: false,
           redirect_uri: allowed_redirect_uri)
  end
  let(:code_verifier) { SecureRandom.hex(64) }
  let(:code_challenge) { Doorkeeper::AccessGrant.generate_code_challenge code_verifier }

  let(:params) do
    {
      response_type: :code,
      client_id: app.uid,
      redirect_uri:,
      scope: :api_v3,
      code_challenge_method: "S256",
      code_challenge:
    }
  end

  def oauth_path
    "/oauth/authorize?#{params.to_query}"
  end

  def get_and_test_token(code)
    parameters = {
      client_id: app.uid,
      code:,
      grant_type: :authorization_code,
      redirect_uri: app.redirect_uri,
      code_verifier:
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
    visit oauth_path

    # Expect we're guided to the login screen
    login_with user.login, "adminADMIN!", visit_signin_path: false

    # We get to the authorization screen
    expect(page).to have_css("h2", text: "Authorize Public mobile client")

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
  end
end

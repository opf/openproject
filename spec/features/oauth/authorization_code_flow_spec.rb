#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'OAuth authorization code flow',
         type: :feature,
         js: true do
  let!(:user) { FactoryBot.create(:user) }
  let!(:redirect_uri) { 'urn:ietf:wg:oauth:2.0:oob' }
  let!(:allowed_redirect_uri) { redirect_uri }
  let!(:app) { FactoryBot.create(:oauth_application, name: 'Cool API app!', redirect_uri: allowed_redirect_uri) }
  let(:client_secret) { app.plaintext_secret }

  def oauth_path(client_id, redirect_url)
    "/oauth/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{CGI.escape(redirect_url)}&scope=api_v3"
  end

  it 'can authorize and manage an OAuth application grant' do
    visit oauth_path app.uid, redirect_uri

    # Expect we're guided to the login screen
    login_with user.login, 'adminADMIN!', visit_signin_path: false

    # We get to the authorization screen
    expect(page).to have_selector('h2', text: 'Authorize Cool API app!')

    # With the correct scope printed
    expect(page).to have_selector('li strong', text: I18n.t('oauth.scopes.api_v3'))
    expect(page).to have_selector('li', text: I18n.t('oauth.scopes.api_v3_text'))

    first = true
    allow_any_instance_of(::OAuth::AuthBaseController)
      .to receive(:allowed_forms).and_wrap_original do |m|
      forms = m.call

      # Multiple requests end up here with one not containing the request url
      if first
        expect(forms).to include redirect_uri
        first = false
      end

      forms
    end

    # Authorize
    find('input.button[value="Authorize"]').click

    # Expect auth token
    code = find('#authorization_code').text

    # And also have a grant for this application
    user.oauth_grants.reload
    expect(user.oauth_grants.count).to eq 1
    expect(user.oauth_grants.first.application).to eq app

    parameters = {
      client_id: app.uid,
      client_secret: client_secret,
      code: code,
      grant_type: :authorization_code,
      redirect_uri: app.redirect_uri
    }

    session = ActionDispatch::Integration::Session.new(Rails.application)
    response = session.post("/oauth/token", params: parameters)
    expect(response).to eq 200
    body = JSON.parse(session.response.body)

    expect(body['access_token']).to be_present
    expect(body['refresh_token']).to be_present
    expect(body['scope']).to eq 'api_v3'

    # Should show that grant in my account
    visit my_account_path
    click_on 'Access token'

    expect(page).to have_selector("#oauth-application-grant-#{app.id}", text: app.name)
    expect(page).to have_selector('td', text: app.name)

    # Revoke the application
    within("#oauth-application-grant-#{app.id}") do
      click_on 'Revoke'
    end

    page.driver.browser.switch_to.alert.accept

    # Should be back on access_token path
    expect(page).to have_selector('.flash.notice')
    expect(page).to have_no_selector("[id^=oauth-application-grant]")

    expect(current_path).to match "/my/access_token"

    # And all grants have been revoked
    authorized = ::Doorkeeper::Application.authorized_for(user)
    expect(authorized).to be_empty
  end

  it 'does not authenticate unknown applications' do
    visit oauth_path 'WAT', redirect_uri

    # Expect we're guided to the login screen
    login_with user.login, 'adminADMIN!', visit_signin_path: false

    # But we got no further
    expect(page).to have_selector('.notification-box.-error', text: 'Client authentication failed due to unknown client, no client authentication included, or unsupported authentication method.')

    # And also have no grant for this application
    user.oauth_grants.reload
    expect(user.oauth_grants.count).to eq 0
  end

  # Selenium can't return response headers
  context 'in browser that can log response headers', js: false do
    before do
      login_as user
    end

    context 'with real urls as allowed redirect uris' do
      let!(:redirect_uri) { "https://foo.com/foo " }
      let!(:allowed_redirect_uri) { "#{redirect_uri} https://bar.com/bar" }
      it 'can authorize and manage an OAuth application grant' do
        visit oauth_path app.uid, redirect_uri

        allow_any_instance_of(::OAuth::AuthBaseController)
          .to receive(:allowed_forms).and_wrap_original do |m|
          forms = m.call

          expect(forms).to include 'https://foo.com/'
          expect(forms).to include 'https://bar.com/'

          forms
        end

        # Check that the hosts of allowed redirection urls are present in the content security policy
        expect(page.response_headers['content-security-policy']).to(
          include("form-action 'self' https://foo.com/ https://bar.com/;")
        )
      end
    end
  end
end

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe 'OAuth user flow', type: :feature, js: true do
  let!(:user) { FactoryBot.create(:user) }
  let!(:app) { FactoryBot.create(:oauth_application, name: 'Cool API app!') }

  def oauth_path(client_id)
    "/oauth/authorize?response_type=code&client_id=#{client_id}&redirect_uri=urn:ietf:wg:oauth:2.0:oob&scope=api_v3"
  end

  before do
    # Do not login, will do that in the oauth flow
  end

  it 'can authorize and manage an OAuth application grant' do
    visit oauth_path app.uid

    # Expect we're guided to the login screen
    login_with user.login, 'adminADMIN!', visit_signin_path: false

    # We get to the authorization screen
    expect(page).to have_selector('h2', text: 'Authorize Cool API app!')

    # With the correct scope printed
    expect(page).to have_selector('li strong', text: I18n.t('oauth.scopes.api_v3'))
    expect(page).to have_selector('li', text: I18n.t('oauth.scopes.api_v3_text'))

    # Authorize
    find('input.button[value="Authorize"]').click

    # Expect auth token
    expect(page).to have_selector('#authorization_code')

    # And also have no grant for this application
    user.oauth_grants.reload
    expect(user.oauth_grants.count).to eq 1
    expect(user.oauth_grants.first.application).to eq app

    # Should show that grant in my account
    visit my_account_path
    click_on 'OAuth Grants and Apps'

    expect(page).to have_selector('h2', text: app.name)
    expect(page).to have_selector('td.scopes', text: 'Full API access')

    # Revoke the application
    click_on 'Revoke'
    page.driver.browser.switch_to.alert.accept

    # Should be on empty grant page
    expect(page).to have_selector('.flash.notice')
    expect(page).to have_selector('.generic-table--no-results-container', text: I18n.t('oauth.grants.none_given'))

    # And all grants have been revoked
    user.oauth_grants.reload
    expect(user.oauth_grants.count).to eq 1
    expect(user.oauth_grants.first.revoked_at).not_to be_nil
  end

  it 'does not authenticate unknown applications' do
    visit oauth_path 'WAT'

    # Expect we're guided to the login screen
    login_with user.login, 'adminADMIN!', visit_signin_path: false

    # But we got no further
    expect(page).to have_selector('.notification-box.-error', text: 'Client authentication failed due to unknown client, no client authentication included, or unsupported authentication method.')

    # And also have no grant for this application
    user.oauth_grants.reload
    expect(user.oauth_grants.count).to eq 0
  end
end

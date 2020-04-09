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
require_relative 'openid_connect_spec_helpers'

RSpec.configure do |c|
  c.include OpenIDConnectSpecHelpers
end

describe 'OpenID Connect', type: :rails_request do
  let(:host) { OmniAuth::OpenIDConnect::Heroku.new('foo', {}).host }
  let(:user_info) do
    {
      sub: '87117114115116',
      name: 'Hans Wurst',
      email: 'h.wurst@finn.de',
      given_name: 'Hans',
      family_name: 'Wurst'
    }
  end

  before do
    allow(EnterpriseToken).to receive(:show_banners?).and_return(false)

    # The redirect will include an authorisation code.
    # Since we don't actually get a valid code in the test we will stub the resulting AccessToken.
    allow_any_instance_of(OpenIDConnect::Client).to receive(:access_token!) do
      OpenIDConnect::AccessToken.new client: self, access_token: 'foo bar baz'
    end

    # Using the granted AccessToken the client then performs another request to the OpenID Connect
    # provider to retrieve user information such as name and email address.
    # Since the test is not supposed to make an actual call it is be stubbed too.
    allow_any_instance_of(OpenIDConnect::AccessToken).to receive(:userinfo!).and_return(
      OpenIDConnect::ResponseObject::UserInfo.new(user_info)
    )

    # enable storing the access token in a cookie
    OpenProject::Configuration['omniauth_store_access_token_in_cookie'] = true
  end

  describe 'sign-up and login' do
    before do
      allow(Setting).to receive(:plugin_openproject_openid_connect).and_return(
        'providers' => {
          'heroku' => {
            'identifier' => 'does not',
            'secret' => 'matter'
          }
        }
      )
    end

    it 'works' do
      ##
      # it should redirect to the provider's openid connect authentication endpoint
      click_on_signin

      expect(response.status).to be 302
      expect(response.location).to match /https:\/\/#{host}.*$/

      params = Rack::Utils.parse_nested_query(response.location.gsub(/^.*\?/, ''))

      expect(params).to include 'client_id'
      expect(params['redirect_uri']).to match /^.*\/auth\/heroku\/callback$/
      expect(params['scope']).to include 'openid'

      ##
      # it should redirect back from the provider to the login page
      redirect_from_provider

      expect(response.status).to be 302
      expect(response.location).to match /\/login$/

      user = User.find_by_mail(user_info[:email])

      expect(user).not_to be nil
      expect(user.active?).to be false

      ##
      # it should redirect to the provider again upon clicking on sign-in when the user has been activated
      user = User.find_by_mail(user_info[:email])
      user.activate
      user.save!

      click_on_signin

      expect(response.status).to be 302
      expect(response.location).to match /https:\/\/#{host}.*$/

      ##
      # it should then login the user upon the redirect back from the provider
      redirect_from_provider

      expect(response.status).to be 302
      expect(response.location).to match /\/\?first_time_user=true$/

      # after_login requires the optional third context parameter
      # remove this guard once we are on v4.1
      if OpenProject::OmniAuth::Authorization.method(:after_login!).arity.abs > 2
        # check that cookie is stored in the access token
        expect(response.cookies['_open_project_session_access_token']).to eq 'foo bar baz'
      end
    end
  end

  context 'provider configuration through the settings' do
    before do
      allow(Setting).to receive(:plugin_openproject_openid_connect).and_return(
        'providers' => {
          'google' => {
            'identifier' => 'does not',
            'secret' => 'matter'
          },
          'azure' => {
            'identifier' => 'IDENTIFIER',
            'secret' => 'SECRET'
          }
        }
      )
    end

    it 'will show no option unless EE' do
      allow(EnterpriseToken).to receive(:show_banners?).and_return(true)
      get '/login'
      expect(response.body).not_to match /Google/i
      expect(response.body).not_to match /Azure/i
    end

    it 'should make providers that have been configured through settings available without requiring a restart' do
      get '/login'
      expect(response.body).to match /Google/i
      expect(response.body).to match /Azure/i

      expect { click_on_signin('google') }.not_to raise_error
      expect(response.status).to be 302
    end
  end
end

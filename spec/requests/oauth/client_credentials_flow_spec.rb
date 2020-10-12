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
require 'rest-client'

describe 'OAuth client credentials flow', type: :request do
  include Rack::Test::Methods

  let!(:application) { FactoryBot.create(:oauth_application, client_credentials_user_id: user_id, name: 'Cool API app!') }
  let(:client_secret) { application.plaintext_secret }

  let(:access_token) {
    response = post '/oauth/token',
                    grant_type: 'client_credentials',
                    scope: 'api_v3',
                    client_id: application.uid,
                    client_secret: client_secret

    expect(response).to be_successful
    body = JSON.parse(response.body)
    body['access_token']
  }

  subject do
    # Perform request with it
    headers = { 'HTTP_CONTENT_TYPE' => 'application/json', 'HTTP_AUTHORIZATION' => "Bearer #{access_token}" }
    response = get '/api/v3', {}, headers
    expect(response).to be_successful

    JSON.parse(response.body)
  end

  before do
    expect(access_token).to be_present
    expect(subject).to be_present
  end

  describe 'when application provides client credentials impersonator' do
    let(:user) { FactoryBot.create(:user) }
    let(:user_id) { user.id }

    it 'allows client credential flow as the user' do
      expect(subject.dig('_links', 'user', 'href')).to eq("/api/v3/users/#{user.id}")
    end
  end

  describe 'when application does not provide client credential impersonator' do
    let(:user_id) { nil }

    it 'allows client credential flow as the anonymous user' do
      expect(subject.dig('_links', 'user', 'href')).to be_nil
    end
  end
end

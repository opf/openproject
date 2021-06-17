#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.

require 'spec_helper'
require 'rack/test'

describe ::API::V3::Events::EventsAPI,
         'index',
         type: :request do

  include API::V3::Utilities::PathHelper

  shared_let(:recipient) { FactoryBot.create :user }
  shared_let(:event1) { FactoryBot.create :event, recipient: recipient }
  shared_let(:event2) { FactoryBot.create :event, recipient: recipient }

  let(:send_request) do
    header "Content-Type", "application/json"
    get api_v3_paths.events
  end

  let(:parsed_response) { JSON.parse(last_response.body) }


  before do
    login_as current_user
    send_request
  end

  describe 'as the user with events' do
    let(:current_user) { recipient }

    it_behaves_like 'API V3 collection response', 2, 2, 'Event'
  end

  describe 'admin user' do
    let(:current_user) { FactoryBot.build(:admin) }

    it_behaves_like 'API V3 collection response', 0, 0, 'Event'
  end

  describe 'as any user' do
    let(:current_user) { FactoryBot.build(:user) }

    it_behaves_like 'API V3 collection response', 0, 0, 'Event'
  end

  describe 'as any user' do
    let(:current_user) { User.anonymous }

    it 'returns a 403 response' do
      expect(last_response.status).to eq(403)
    end
  end
end

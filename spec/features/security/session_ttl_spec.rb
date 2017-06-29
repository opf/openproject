#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'Session TTL',
         with_settings: {session_ttl_enabled?: true, session_ttl: '10'},
         type: :feature do
  let!(:user) {FactoryGirl.create :admin}
  let!(:work_package) {FactoryGirl.create :work_package}

  before do
    login_with(user.login, user.password)
  end

  def expire!
    page.set_rack_session(updated_at: Time.now - 1.hour)
  end

  describe 'outdated TTL on Rails request' do
    it 'expires on the next Rails request' do
      visit '/my/account'
      expect(page).to have_selector('.form--field-container', text: user.login)

      # Expire the session
      expire!

      visit '/'
      expect(page).to have_selector('.action-login')
    end
  end

  describe 'outdated TTL on API request' do
    it 'expires on the next APIv3 request' do
      visit "/api/v3/work_packages/#{work_package.id}"

      body = JSON.parse(page.body)
      expect(body['id']).to eq(work_package.id)

      # Expire the session
      expire!
      visit "/api/v3/work_packages/#{work_package.id}"

      expect(page.body).to eq('unauthorized')
    end
  end
end

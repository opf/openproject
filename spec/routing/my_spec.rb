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

describe 'my routes', type: :routing do
  it '/my/account GET routes to my#account' do
    expect(get('/my/account')).to route_to('my#account')
  end

  it '/my/account PATCH routes to my#update_account' do
    expect(patch('/my/account')).to route_to('my#update_account')
  end

  it '/my/settings GET routes to my#settings' do
    expect(get('/my/settings')).to route_to('my#settings')
  end

  it '/my/settings PATCH routes to my#update_account' do
    expect(patch('/my/settings')).to route_to('my#update_settings')
  end

  it '/my/generate_rss_key POST routes to my#generate_rss_key' do
    expect(post('/my/generate_rss_key')).to route_to('my#generate_rss_key')
  end

  it '/my/generate_api_key POST routes to my#generate_api_key' do
    expect(post('/my/generate_api_key')).to route_to('my#generate_api_key')
  end

  it {
    expect(get('/my/deletion_info')).to route_to(controller: 'users',
                                                 action: 'deletion_info')
  }
end

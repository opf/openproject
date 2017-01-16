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

describe 'my routes', type: :routing do
  it '/my/add_block POST routes to my#add_block' do
    expect(post('/my/add_block')).to route_to('my#add_block')
  end

  it '/my/page_layout GET routes to my#page_layout' do
    expect(get('/my/page_layout')).to route_to('my#page_layout')
  end

  it '/my/remove_block POST routes to my#remove_block' do
    expect(post('/my/remove_block')).to route_to('my#remove_block')
  end

  it '/my/account GET routes to my#account' do
    expect(get('/my/account')).to route_to('my#account')
  end

  it '/my/account PATCH routes to my#account' do
    expect(patch('/my/account')).to route_to('my#account')
  end

  it '/my/reset_rss_key POST routes to my#reset_rss_key' do
    expect(post('/my/reset_rss_key')).to route_to('my#reset_rss_key')
  end

  it '/my/reset_api_key POST routes to my#reset_api_key' do
    expect(post('/my/reset_api_key')).to route_to('my#reset_api_key')
  end
end

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

describe 'users 2fa devices', type: :routing do
  it 'route to index' do
    expect(get('/my/two_factor_devices')).to route_to('two_factor_authentication/my/two_factor_devices#index')
  end

  it 'route to new' do
    expect(get('/my/two_factor_devices/new')).to route_to('two_factor_authentication/my/two_factor_devices#new')
  end

  it 'route to register' do
    expect(post('/my/two_factor_devices/register')).to route_to('two_factor_authentication/my/two_factor_devices#register')
  end

  it 'route to confirm' do
    expect(get('/my/two_factor_devices/1/confirm')).to route_to(controller: 'two_factor_authentication/my/two_factor_devices',
                                                                action: 'confirm',
                                                                device_id: '1')
  end

  it 'route to POST confirm' do
    expect(post('/my/two_factor_devices/1/confirm')).to route_to(controller: 'two_factor_authentication/my/two_factor_devices',
                                                                 action: 'confirm',
                                                                 device_id: '1')
  end

  it 'route to POST make_default' do
    expect(post('/my/two_factor_devices/1/make_default')).to route_to(controller: 'two_factor_authentication/my/two_factor_devices',
                                                                      action: 'make_default',
                                                                      device_id: '1')
  end

  it 'route to DELETE destroy' do
    expect(delete('/my/two_factor_devices/1')).to route_to(controller: 'two_factor_authentication/my/two_factor_devices',
                                                         action: 'destroy',
                                                         device_id: '1')
  end
end

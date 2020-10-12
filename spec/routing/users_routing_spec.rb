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

describe UsersController, 'routing', type: :routing do
  it {
    is_expected.to route(:get, '/users').to(controller: 'users',
                                            action: 'index')
  }

  it {
    expect(get('/users.xml'))
      .to route_to controller: 'users',
                   action: 'index',
                   format: 'xml'
  }

  it {
    is_expected.to route(:get, '/users/44').to(controller: 'users',
                                               action: 'show',
                                               id: '44')
  }

  it {
    expect(get('/users/44.xml'))
      .to route_to controller: 'users',
                   action: 'show',
                   id: '44',
                   format: 'xml'
  }

  it {
    is_expected.to route(:get, '/users/current').to(controller: 'users',
                                                    action: 'show',
                                                    id: 'current')
  }

  it {
    expect(get('/users/current.xml'))
      .to route_to controller: 'users',
                   action: 'show',
                   id: 'current',
                   format: 'xml'
  }

  it {
    is_expected.to route(:get, '/users/new').to(controller: 'users',
                                                action: 'new')
  }

  it {
    is_expected.to route(:get, '/users/444/edit').to(controller: 'users',
                                                     action: 'edit',
                                                     id: '444')
  }

  it {
    is_expected.to route(:get, '/users/222/edit/membership').to(controller: 'users',
                                                                action: 'edit',
                                                                id: '222',
                                                                tab: 'membership')
  }

  it {
    is_expected.to route(:post, '/users').to(controller: 'users',
                                             action: 'create')
  }

  it {
    expect(post('/users.xml'))
      .to route_to controller: 'users',
                   action: 'create',
                   format: 'xml'
  }

  it {
    is_expected.to route(:put, '/users/444').to(controller: 'users',
                                                action: 'update',
                                                id: '444')
  }

  it {
    expect(put('/users/444.xml'))
      .to route_to controller: 'users',
                   action: 'update',
                   id: '444',
                   format: 'xml'
  }

  it {
    expect(get('/users/1/change_status/foobar'))
      .to route_to controller: 'users',
                   action: 'change_status_info',
                   id: '1',
                   change_action: 'foobar'
  }
  it {
    expect(get('/users/1/deletion_info')).to route_to(controller: 'users',
                                                      action: 'deletion_info',
                                                      id: '1')
  }

  it {
    expect(delete('/users/1')).to route_to(controller: 'users',
                                           action: 'destroy',
                                           id: '1')
  }
end

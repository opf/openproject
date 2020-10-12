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

describe Users::MembershipsController, type: :routing do
  describe 'routing' do
    it 'connects DELETE users/:user_id/memberships/:id' do
      expect(delete('/users/1/memberships/2')).to route_to(controller: 'users/memberships',
                                                           action: 'destroy',
                                                           user_id: '1',
                                                           id: '2')
    end

    it 'connects PATCH users/:user_id/memberships/:id' do
      expect(patch('/users/1/memberships/2')).to route_to(controller: 'users/memberships',
                                                          action: 'update',
                                                          user_id: '1',
                                                          id: '2')
    end

    it 'connects POST users/:user_id/memberships' do
      expect(post('/users/1/memberships')).to route_to(controller: 'users/memberships',
                                                       action: 'create',
                                                       user_id: '1')
    end
  end
end

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

describe CostTypesController, type: :routing do
  describe 'routing' do
    it {
      expect(get('/cost_types')).to route_to(controller: 'cost_types',
                                             action: 'index')
    }

    it {
      expect(post('/cost_types')).to route_to(controller: 'cost_types',
                                              action: 'create')
    }

    it {
      expect(get('/cost_types/new')).to route_to(controller: 'cost_types',
                                                 action: 'new')
    }

    it {
      expect(get('/cost_types/5/edit')).to route_to(controller: 'cost_types',
                                                    action: 'edit',
                                                    id: '5')
    }

    it {
      expect(put('/cost_types/5')).to route_to(controller: 'cost_types',
                                               action: 'update',
                                               id: '5')
    }

    it {
      expect(put('/cost_types/5/set_rate')).to route_to(controller: 'cost_types',
                                                        action: 'set_rate',
                                                        id: '5')
    }

    it {
      expect(delete('/cost_types/5')).to route_to(controller: 'cost_types',
                                                  action: 'destroy',
                                                  id: '5')
    }

    it {
      expect(patch('/cost_types/5/restore')).to route_to(controller: 'cost_types',
                                                         action: 'restore',
                                                         id: '5')
    }
  end
end

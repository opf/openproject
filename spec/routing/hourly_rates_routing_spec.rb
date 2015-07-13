#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require 'spec_helper'

describe HourlyRatesController, type: :routing do
  describe 'routing' do
    it {
      expect(get('/projects/blubs/hourly_rates/5')).to route_to(controller: 'hourly_rates',
                                                                action: 'show',
                                                                project_id: 'blubs',
                                                                id: '5')
    }

    it {
      expect(get('/projects/blubs/hourly_rates/5/edit')).to route_to(controller: 'hourly_rates',
                                                                     action: 'edit',
                                                                     project_id: 'blubs',
                                                                     id: '5')
    }

    it {
      expect(get('/hourly_rates/5/edit')).to route_to(controller: 'hourly_rates',
                                                      action: 'edit',
                                                      id: '5')
    }

    it {
      expect(put('/projects/blubs/hourly_rates/5')).to route_to(controller: 'hourly_rates',
                                                                action: 'update',
                                                                project_id: 'blubs',
                                                                id: '5')
    }

    it {
      expect(post('/projects/blubs/hourly_rates/5/set_rate')).to route_to(controller: 'hourly_rates',
                                                                          action: 'set_rate',
                                                                          project_id: 'blubs',
                                                                          id: '5')
    }
  end
end

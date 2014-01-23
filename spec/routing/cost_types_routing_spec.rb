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

describe CostTypesController do
  describe "routing" do
    it { get('/cost_types').should route_to(:controller => 'cost_types',
                                            :action => 'index') }

    it { post('/cost_types').should route_to(:controller => 'cost_types',
                                             :action => 'create') }

    it { get('/cost_types/new').should route_to(:controller => 'cost_types',
                                                :action => 'new') }

    it { get('/cost_types/5/edit').should route_to(:controller => 'cost_types',
                                                   :action => 'edit',
                                                   :id => '5') }

    it { put('/cost_types/5').should route_to(:controller => 'cost_types',
                                              :action => 'update',
                                              :id => '5') }

    it { put('/cost_types/5/set_rate').should route_to(:controller => 'cost_types',
                                                       :action => 'set_rate',
                                                       :id => '5') }

    it { put('/cost_types/5/toggle_delete').should route_to(:controller => 'cost_types',
                                                            :action => 'toggle_delete',
                                                            :id => '5') }
  end
end

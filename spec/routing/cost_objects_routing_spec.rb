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

describe CostObjectsController do
  describe "routing" do
    it { get('/projects/blubs/cost_objects/new').should route_to(:controller => 'cost_objects',
                                                                 :action => 'new',
                                                                 :project_id => 'blubs') }
    it { post('/projects/blubs/cost_objects').should route_to(:controller => 'cost_objects',
                                                              :action => 'create',
                                                              :project_id => 'blubs') }
    it { get('/projects/blubs/cost_objects').should route_to(:controller => 'cost_objects',
                                                             :action => 'index',
                                                             :project_id => 'blubs') }
    it { get('/cost_objects/5').should route_to(:controller => 'cost_objects',
                                                :action => 'show',
                                                :id => '5') }
    it { put('/cost_objects/5').should route_to(:controller => 'cost_objects',
                                                :action => 'update',
                                                :id => '5') }
    it { delete('/cost_objects/5').should route_to(:controller => 'cost_objects',
                                                   :action => 'destroy',
                                                   :id => '5') }
    it { post('/projects/42/cost_objects/update_material_budget_item').should route_to(:controller => 'cost_objects',
                                                      :action => 'update_material_budget_item',
                                                      :project_id => '42') }
    it { post('/projects/42/cost_objects/update_labor_budget_item').should route_to(:controller => 'cost_objects',
                                                      :action => 'update_labor_budget_item',
                                                      :project_id => '42') }
    it { get('/cost_objects/5/copy').should route_to(:controller => 'cost_objects',
                                                      :action => 'copy',
                                                      :id => '5') }
  end

end

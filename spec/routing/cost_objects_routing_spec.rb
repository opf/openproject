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

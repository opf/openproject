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
    it { post('/cost_objects/5/preview').should route_to(:controller => 'cost_objects',
                                                         :action => 'preview',
                                                         :id => '5') }
  end

end

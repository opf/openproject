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

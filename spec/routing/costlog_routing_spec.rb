require 'spec_helper'

describe CostlogController do
  describe "routing" do
    it { get('/issues/5/cost_entries').should route_to(:controller => 'costlog',
                                              :action => 'index',
                                              :issue_id => '5') }

    it { get('/projects/blubs/cost_entries/new').should route_to(:controller => 'costlog',
                                                                 :action => 'new',
                                                                 :project_id => 'blubs') }

    it { post('/projects/blubs/cost_entries').should route_to(:controller => 'costlog',
                                                              :action => 'create',
                                                              :project_id => 'blubs') }

    it { get('/issues/5/cost_entries/new').should route_to(:controller => 'costlog',
                                                           :action => 'new',
                                                           :issue_id => '5') }

    it { get('/cost_entries/5/edit').should route_to(:controller => 'costlog',
                                                     :action => 'edit',
                                                     :id => '5') }

    it { put('/cost_entries/5').should route_to(:controller => 'costlog',
                                                :action => 'update',
                                                :id => '5') }

    it { delete('/cost_entries/5').should route_to(:controller => 'costlog',
                                                   :action => 'destroy',
                                                   :id => '5') }
  end
end

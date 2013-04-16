require 'spec_helper'

describe RbSprintsController do
  describe "routing" do
    #it { get('/projects/project_42/sprints/21').should route_to(:controller => 'rb_sprints',
    #                                                 :action => 'show',
    #                                                 :project_id => 'project_42',
    #                                                 :id => '21') }
    it { put('/projects/project_42/sprints/21').should route_to(:controller => 'rb_sprints',
                                                     :action => 'update',
                                                     :project_id => 'project_42',
                                                     :id => '21') }
  end
end
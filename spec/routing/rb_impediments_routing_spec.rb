require 'spec_helper'

describe RbImpedimentsController do
  describe "routing" do
    it { post('/projects/project_42/sprints/21/impediments').should route_to(:controller => 'rb_impediments',
                                                                             :action => 'create',
                                                                             :project_id => 'project_42',
                                                                             :sprint_id => '21') }
    it { put('/projects/project_42/sprints/21/impediments/85').should route_to(:controller => 'rb_impediments',
                                                                               :action => 'update',
                                                                               :project_id => 'project_42',
                                                                               :sprint_id => '21',
                                                                               :id => '85') }
  end
end

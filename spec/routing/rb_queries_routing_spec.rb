require 'spec_helper'

describe RbQueriesController do
  describe "routing" do
    it { get('/projects/project_42/sprints/21/query').should route_to(:controller => 'rb_queries',
                                                                      :action => 'show',
                                                                      :project_id => 'project_42',
                                                                      :sprint_id => '21') }
  end
end

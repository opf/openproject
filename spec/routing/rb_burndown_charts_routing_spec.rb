require 'spec_helper'

describe RbBurndownChartsController do
  describe "routing" do
    it { get('/projects/project_42/sprints/21/burndown_chart').should route_to(:controller => 'rb_burndown_charts',
                                                                               :action => 'show',
                                                                               :project_id => 'project_42',
                                                                               :sprint_id => '21') }
  end
end

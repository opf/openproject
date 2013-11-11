require 'spec_helper'

describe RbMasterBacklogsController do
  describe "routing" do
    it { get('/projects/project_42/backlogs').should route_to(:controller => 'rb_master_backlogs',
                                                              :action => 'index',
                                                              :project_id => 'project_42') }
  end
end

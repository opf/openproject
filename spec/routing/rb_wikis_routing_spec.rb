require 'spec_helper'

describe RbWikisController do
  describe "routing" do
    it { get('/projects/project_42/sprints/21/wiki').should route_to(:controller => 'rb_wikis',
                                                                     :action => 'show',
                                                                     :project_id => 'project_42',
                                                                     :sprint_id => '21') }
    it { get('/projects/project_42/sprints/21/wiki/edit').should route_to(:controller => 'rb_wikis',
                                                                          :action => 'edit',
                                                                          :project_id => 'project_42',
                                                                          :sprint_id => '21') }
  end
end

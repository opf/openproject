require 'spec_helper'

describe RbTasksController do
  describe "routing" do
    it { post('/projects/project_42/sprints/21/tasks').should route_to(:controller => 'rb_tasks',
                                                                       :action => 'create',
                                                                       :project_id => 'project_42',
                                                                       :sprint_id => '21') }
    it { put('/projects/project_42/sprints/21/tasks/85').should route_to(:controller => 'rb_tasks',
                                                                         :action => 'update',
                                                                         :project_id => 'project_42',
                                                                         :sprint_id => '21',
                                                                         :id => '85') }
  end
end

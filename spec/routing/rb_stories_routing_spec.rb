require 'spec_helper'

describe RbStoriesController do
  describe "routing" do
    it { get('/projects/project_42/sprints/21/stories').should route_to(:controller => 'rb_stories',
                                                                        :action => 'index',
                                                                        :project_id => 'project_42',
                                                                        :sprint_id => '21') }
    it { post('/projects/project_42/sprints/21/stories').should route_to(:controller => 'rb_stories',
                                                                         :action => 'create',
                                                                         :project_id => 'project_42',
                                                                         :sprint_id => '21') }
    it { put('/projects/project_42/sprints/21/stories/85').should route_to(:controller => 'rb_stories',
                                                                           :action => 'update',
                                                                           :project_id => 'project_42',
                                                                           :sprint_id => '21',
                                                                           :id => '85') }
  end
end

OpenProject::Application.routes.draw do

  # Use rb/ as a URL 'namespace.' We're using a slightly different URL pattern
  # From Redmine so namespacing avoids any further problems down the line
  resource :rb, :only => :none do

    scope "queries/:project_id" do
      resource :query,
               :only => :show,
               :controller => :rb_queries
    end

    scope "wiki/:sprint_id" do
      resource :wiki, :only => [:show, :edit], :controller => :rb_wikis
    end

    scope "projects/:project_id/burndown_charts/:sprint_id" do
      resource   :burndown_chart,   :only => :show,               :controller => :rb_burndown_charts
    end

    scope "impediment/:id" do
      resource   :impediment,       :except => :index,            :controller => :rb_impediments
    end

    scope  "impediments/:sprint_id" do
      resources  :impediments,      :only => :index,              :controller => :rb_impediments
    end

    scope "task/:id" do
      resource   :task,             :except => :index,            :controller => :rb_tasks
    end

    scope "tasks/:stroy_id" do
      resources  :tasks,            :only => :index,              :controller => :rb_tasks
    end

    scope "story/:id" do
      resource   :story,            :except => :index,            :controller => :rb_stories
    end

    scope "stories/:project_id" do
      resources  :stories,          :only => :index,              :controller => :rb_stories
    end

    scope "sprints/:sprint_id" do
      resource   :sprint,           :only => [:show, :update],    :controller => :rb_sprints
    end

    scope "server_variables/:project_id" do
      resource   :server_variables, :only => :show,               :controller => :rb_server_variables
    end

    scope "taskboard/:sprint_id" do
      resource   :taskboard,        :only => :show,               :controller => :rb_taskboards
    end

    scope "master_backlogs/:project_id" do
      resource   :master_backlog,   :only => :show,               :controller => :rb_master_backlogs
    end

    resources  :issue_boxes,      :only => [:show, :edit, :update]
  end

  get 'projects/:project_id/versions/:id/edit' => 'version_settings#edit'
  get 'projects/:id/project_issue_statuses' => 'projects#project_issue_statuses'
  post 'projects/:id/rebuild_positions' => 'projects#rebuild_positions'
end

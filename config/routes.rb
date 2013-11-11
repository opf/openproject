OpenProject::Application.routes.draw do

  scope "", as: "backlogs" do

    scope "projects/:project_id", as: 'project' do

      resources   :backlogs,         :controller => :rb_master_backlogs,  :only => :index

      resource    :server_variables, :controller => :rb_server_variables, :only => :show, :format => :js

      resources   :sprints,          :controller => :rb_sprints,          :only => :update do

        resource  :query,            :controller => :rb_queries,          :only => :show

        resource  :taskboard,        :controller => :rb_taskboards,       :only => :show

        resource  :wiki,             :controller => :rb_wikis,            :only => [:show, :edit]

        resource  :burndown_chart,   :controller => :rb_burndown_charts,  :only => :show

        resources :impediments,      :controller => :rb_impediments,      :only => [:create, :update]

        resources :tasks,            :controller => :rb_tasks,            :only => [:create, :update]

        resources :stories,          :controller => :rb_stories,          :only => [:index, :create, :update]

      end
    end
  end

  get  'projects/:project_id/versions/:id/edit' => 'version_settings#edit'
  post  'projects/:id/project_done_statuses' => 'projects#project_done_statuses'
  post 'projects/:id/rebuild_positions' => 'projects#rebuild_positions'
end

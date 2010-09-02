ActionController::Routing::Routes.draw do |map|

  # Use rb/ as a URL 'namespace.' We're using a slightly different URL pattern
  # From Redmine so namespacing avoids any further problems down the line
  map.resource :rb, :only => :none do |rb|
    rb.resources :queries,          :only => :show,               :controller => :rb_queries
    rb.resources :wikis,            :only => [:show, :edit],      :controller => :rb_statistics
    rb.resources :statistics,       :only => :show,               :controller => :rb_statistics
    rb.resources :calendars,        :only => :show,               :controller => :rb_calendars
    rb.resources :burndown_charts,  :only => :show,               :controller => :rb_burndown_charts
    rb.resources :impediments,      :except => :destroy,          :controller => :rb_impediments
    rb.resources :tasks,            :except => :destroy,          :controller => :rb_tasks
    rb.resources :stories,          :only => [:create, :update],  :controller => :rb_stories
    rb.resources :stories,          :only => :index,              :controller => :rb_stories, :as => "stories/:project_id"
    rb.resources :sprints,          :only => [:show, :update],    :controller => :rb_sprints
    rb.resources :server_variables, :only => :show,               :controller => :rb_server_variables
    rb.resources :master_backlogs,  :only => :show,               :controller => :rb_master_backlogs
  end

end
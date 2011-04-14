ActionController::Routing::Routes.draw do |map|

  # Use rb/ as a URL 'namespace.' We're using a slightly different URL pattern
  # From Redmine so namespacing avoids any further problems down the line
  map.resource :rb, :only => :none do |rb|
    rb.resource   :updated_items,    :only => :show,               :controller => :rb_updated_items,    :as => "updated_items/:project_id"
    rb.resource   :query,            :only => :show,               :controller => :rb_queries,          :as => "queries/:project_id"
    rb.resource   :wiki,             :only => [:show, :edit],      :controller => :rb_wikis,            :as => "wikis/:sprint_id"
    rb.resource   :statistics,       :only => :show,               :controller => :rb_statistics
    rb.resource   :calendars,        :only => :show,               :controller => :rb_calendars,        :as => "calendars/:project_id"
    rb.resource   :burndown_chart,   :only => :show,               :controller => :rb_burndown_charts,  :as => "projects/:project_id/burndown_charts/:sprint_id"
    rb.resource   :impediment,       :except => :index,            :controller => :rb_impediments,      :as => "impediment/:id"
    rb.resources  :impediments,      :only => :index,              :controller => :rb_impediments,      :as => "impediments/:sprint_id"
    rb.resource   :task,             :except => :index,            :controller => :rb_tasks,            :as => "task/:id"
    rb.resources  :tasks,            :only => :index,              :controller => :rb_tasks,            :as => "tasks/:story_id"
    rb.resource   :story,            :except => :index,            :controller => :rb_stories,          :as => "story/:id"
    rb.resources  :stories,          :only => :index,              :controller => :rb_stories,          :as => "stories/:project_id"
    rb.resource   :sprint,           :only => [:show, :update],    :controller => :rb_sprints,          :as => "sprints/:sprint_id"
    rb.resource   :server_variables, :only => :show,               :controller => :rb_server_variables, :as => "server_variables/:project_id"
    rb.resource   :taskboard,        :only => :show,               :controller => :rb_taskboards,       :as => "taskboards/:sprint_id"
    rb.resource   :master_backlog,   :only => :show,               :controller => :rb_master_backlogs,  :as => "master_backlogs/:project_id"
  end

  map.connect 'projects/:project_id/versions/:id/edit', :controller => 'version_settings', :action => 'edit'
end

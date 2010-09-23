ActionController::Routing::Routes.draw do |map|
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Here's a sample route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  map.home '', :controller => 'welcome'
  
  map.signin 'login', :controller => 'account', :action => 'login'
  map.signout 'logout', :controller => 'account', :action => 'logout'
  
  map.connect 'roles/workflow/:id/:role_id/:tracker_id', :controller => 'roles', :action => 'workflow'
  map.connect 'help/:ctrl/:page', :controller => 'help'
  
  map.connect 'time_entries/:id/edit', :action => 'edit', :controller => 'timelog'
  map.connect 'projects/:project_id/time_entries/new', :action => 'edit', :controller => 'timelog'
  map.connect 'projects/:project_id/issues/:issue_id/time_entries/new', :action => 'edit', :controller => 'timelog'
  
  map.with_options :controller => 'timelog' do |timelog|
    timelog.connect 'projects/:project_id/time_entries', :action => 'details'
    
    timelog.with_options :action => 'details', :conditions => {:method => :get}  do |time_details|
      time_details.connect 'time_entries'
      time_details.connect 'time_entries.:format'
      time_details.connect 'issues/:issue_id/time_entries'
      time_details.connect 'issues/:issue_id/time_entries.:format'
      time_details.connect 'projects/:project_id/time_entries.:format'
      time_details.connect 'projects/:project_id/issues/:issue_id/time_entries'
      time_details.connect 'projects/:project_id/issues/:issue_id/time_entries.:format'
    end
    timelog.connect 'projects/:project_id/time_entries/report', :action => 'report'
    timelog.with_options :action => 'report',:conditions => {:method => :get} do |time_report|
      time_report.connect 'time_entries/report'
      time_report.connect 'time_entries/report.:format'
      time_report.connect 'projects/:project_id/time_entries/report.:format'
    end

    timelog.with_options :action => 'edit', :conditions => {:method => :get} do |time_edit|
      time_edit.connect 'issues/:issue_id/time_entries/new'
    end
      
    timelog.connect 'time_entries/:id/destroy', :action => 'destroy', :conditions => {:method => :post}
  end
  
  map.connect 'projects/:id/wiki', :controller => 'wikis', :action => 'edit', :conditions => {:method => :post}
  map.connect 'projects/:id/wiki/destroy', :controller => 'wikis', :action => 'destroy', :conditions => {:method => :get}
  map.connect 'projects/:id/wiki/destroy', :controller => 'wikis', :action => 'destroy', :conditions => {:method => :post}
  map.with_options :controller => 'wiki' do |wiki_routes|
    wiki_routes.with_options :conditions => {:method => :get} do |wiki_views|
      wiki_views.connect 'projects/:id/wiki/:page', :action => 'special', :page => /page_index|date_index|export/i
      wiki_views.connect 'projects/:id/wiki/:page', :action => 'index', :page => nil
      wiki_views.connect 'projects/:id/wiki/:page/edit', :action => 'edit'
      wiki_views.connect 'projects/:id/wiki/:page/rename', :action => 'rename'
      wiki_views.connect 'projects/:id/wiki/:page/history', :action => 'history'
      wiki_views.connect 'projects/:id/wiki/:page/diff/:version/vs/:version_from', :action => 'diff'
      wiki_views.connect 'projects/:id/wiki/:page/annotate/:version', :action => 'annotate'
    end
    
    wiki_routes.connect 'projects/:id/wiki/:page/:action', 
      :action => /edit|rename|destroy|preview|protect/,
      :conditions => {:method => :post}
  end
  
  map.with_options :controller => 'messages' do |messages_routes|
    messages_routes.with_options :conditions => {:method => :get} do |messages_views|
      messages_views.connect 'boards/:board_id/topics/new', :action => 'new'
      messages_views.connect 'boards/:board_id/topics/:id', :action => 'show'
      messages_views.connect 'boards/:board_id/topics/:id/edit', :action => 'edit'
    end
    messages_routes.with_options :conditions => {:method => :post} do |messages_actions|
      messages_actions.connect 'boards/:board_id/topics/new', :action => 'new'
      messages_actions.connect 'boards/:board_id/topics/:id/replies', :action => 'reply'
      messages_actions.connect 'boards/:board_id/topics/:id/:action', :action => /edit|destroy/
    end
  end
  
  map.with_options :controller => 'boards' do |board_routes|
    board_routes.with_options :conditions => {:method => :get} do |board_views|
      board_views.connect 'projects/:project_id/boards', :action => 'index'
      board_views.connect 'projects/:project_id/boards/new', :action => 'new'
      board_views.connect 'projects/:project_id/boards/:id', :action => 'show'
      board_views.connect 'projects/:project_id/boards/:id.:format', :action => 'show'
      board_views.connect 'projects/:project_id/boards/:id/edit', :action => 'edit'
    end
    board_routes.with_options :conditions => {:method => :post} do |board_actions|
      board_actions.connect 'projects/:project_id/boards', :action => 'new'
      board_actions.connect 'projects/:project_id/boards/:id/:action', :action => /edit|destroy/
    end
  end
  
  map.with_options :controller => 'documents' do |document_routes|
    document_routes.with_options :conditions => {:method => :get} do |document_views|
      document_views.connect 'projects/:project_id/documents', :action => 'index'
      document_views.connect 'projects/:project_id/documents/new', :action => 'new'
      document_views.connect 'documents/:id', :action => 'show'
      document_views.connect 'documents/:id/edit', :action => 'edit'
    end
    document_routes.with_options :conditions => {:method => :post} do |document_actions|
      document_actions.connect 'projects/:project_id/documents', :action => 'new'
      document_actions.connect 'documents/:id/:action', :action => /destroy|edit/
    end
  end

  map.resources :issue_moves, :only => [:new, :create], :path_prefix => '/issues', :as => 'move'

  # Misc issue routes. TODO: move into resources
  map.auto_complete_issues '/issues/auto_complete', :controller => 'auto_completes', :action => 'issues'
  map.preview_issue '/issues/preview/:id', :controller => 'previews', :action => 'issue' # TODO: would look nicer as /issues/:id/preview
  map.issues_context_menu '/issues/context_menu', :controller => 'context_menus', :action => 'issues'
  map.issue_changes '/issues/changes', :controller => 'journals', :action => 'index'
  map.bulk_edit_issue 'issues/bulk_edit', :controller => 'issues', :action => 'bulk_edit', :conditions => { :method => :get }
  map.bulk_update_issue 'issues/bulk_edit', :controller => 'issues', :action => 'bulk_update', :conditions => { :method => :post }
  map.quoted_issue '/issues/:id/quoted', :controller => 'journals', :action => 'new', :id => /\d+/, :conditions => { :method => :post }
  map.connect '/issues/:id/destroy', :controller => 'issues', :action => 'destroy', :conditions => { :method => :post } # legacy

  map.resource :gantt, :path_prefix => '/issues', :controller => 'gantts', :only => [:show, :update]
  map.resource :gantt, :path_prefix => '/projects/:project_id/issues', :controller => 'gantts', :only => [:show, :update]
  map.resource :calendar, :path_prefix => '/issues', :controller => 'calendars', :only => [:show, :update]
  map.resource :calendar, :path_prefix => '/projects/:project_id/issues', :controller => 'calendars', :only => [:show, :update]

  map.with_options :controller => 'reports', :conditions => {:method => :get} do |reports|
    reports.connect 'projects/:id/issues/report', :action => 'issue_report'
    reports.connect 'projects/:id/issues/report/:detail', :action => 'issue_report_details'
  end

  # Following two routes conflict with the resources because #index allows POST
  map.connect '/issues', :controller => 'issues', :action => 'index', :conditions => { :method => :post }
  map.connect '/issues/create', :controller => 'issues', :action => 'index', :conditions => { :method => :post }
  
  map.resources :issues, :member => { :edit => :post }, :collection => {}
  map.resources :issues, :path_prefix => '/projects/:project_id', :collection => { :create => :post }

  map.with_options  :controller => 'issue_relations', :conditions => {:method => :post} do |relations|
    relations.connect 'issues/:issue_id/relations/:id', :action => 'new'
    relations.connect 'issues/:issue_id/relations/:id/destroy', :action => 'destroy'
  end
  
  map.with_options :controller => 'news' do |news_routes|
    news_routes.with_options :conditions => {:method => :get} do |news_views|
      news_views.connect 'news', :action => 'index'
      news_views.connect 'projects/:project_id/news', :action => 'index'
      news_views.connect 'projects/:project_id/news.:format', :action => 'index'
      news_views.connect 'news.:format', :action => 'index'
      news_views.connect 'projects/:project_id/news/new', :action => 'new'
      news_views.connect 'news/:id', :action => 'show'
      news_views.connect 'news/:id/edit', :action => 'edit'
    end
    news_routes.with_options do |news_actions|
      news_actions.connect 'projects/:project_id/news', :action => 'create', :conditions => {:method => :post}
      news_actions.connect 'news/:id/destroy', :action => 'destroy'
    end
    news_routes.connect 'news/:id/edit', :action => 'update', :conditions => {:method => :put}

    news_routes.connect 'news/:id/comments', :controller => 'comments', :action => 'create', :conditions => {:method => :post}
    news_routes.connect 'news/:id/comments/:comment_id', :controller => 'comments', :action => 'destroy', :conditions => {:method => :delete}
  end
  
  map.connect 'projects/:id/members/new', :controller => 'members', :action => 'new'
  
  map.with_options :controller => 'users' do |users|
    users.with_options :conditions => {:method => :get} do |user_views|
      user_views.connect 'users', :action => 'index'
      user_views.connect 'users/:id', :action => 'show', :id => /\d+/
      user_views.connect 'users/new', :action => 'add'
      user_views.connect 'users/:id/edit/:tab', :action => 'edit', :tab => nil
    end
    users.with_options :conditions => {:method => :post} do |user_actions|
      user_actions.connect 'users', :action => 'add'
      user_actions.connect 'users/new', :action => 'add'
      user_actions.connect 'users/:id/edit', :action => 'edit'
      user_actions.connect 'users/:id/memberships', :action => 'edit_membership'
      user_actions.connect 'users/:id/memberships/:membership_id', :action => 'edit_membership'
      user_actions.connect 'users/:id/memberships/:membership_id/destroy', :action => 'destroy_membership'
    end
  end

  # For nice "roadmap" in the url for the index action
  map.connect 'projects/:project_id/roadmap', :controller => 'versions', :action => 'index'

  map.resources :projects, :member => {
    :copy => [:get, :post],
    :settings => :get,
    :modules => :post,
    :archive => :post,
    :unarchive => :post
  } do |project|
    project.resource :project_enumerations, :as => 'enumerations', :only => [:update, :destroy]
    project.resources :files, :only => [:index, :new, :create]
    project.resources :versions, :collection => {:close_completed => :put}, :member => {:status_by => :post}
  end

  # Destroy uses a get request to prompt the user before the actual DELETE request
  map.project_destroy_confirm 'projects/:id/destroy', :controller => 'projects', :action => 'destroy', :conditions => {:method => :get}

  # TODO: port to be part of the resources route(s)
  map.with_options :controller => 'projects' do |project_mapper|
    project_mapper.with_options :conditions => {:method => :get} do |project_views|
      project_views.connect 'projects/:id/settings/:tab', :controller => 'projects', :action => 'settings'
      project_views.connect 'projects/:project_id/issues/:copy_from/copy', :controller => 'issues', :action => 'new'
    end
  end
  
  map.with_options :controller => 'activities', :action => 'index', :conditions => {:method => :get} do |activity|
    activity.connect 'projects/:id/activity'
    activity.connect 'projects/:id/activity.:format'
    activity.connect 'activity', :id => nil
    activity.connect 'activity.:format', :id => nil
  end

    
  map.with_options :controller => 'issue_categories' do |categories|
    categories.connect 'projects/:project_id/issue_categories/new', :action => 'new'
  end
  
  map.with_options :controller => 'repositories' do |repositories|
    repositories.with_options :conditions => {:method => :get} do |repository_views|
      repository_views.connect 'projects/:id/repository', :action => 'show'
      repository_views.connect 'projects/:id/repository/edit', :action => 'edit'
      repository_views.connect 'projects/:id/repository/statistics', :action => 'stats'
      repository_views.connect 'projects/:id/repository/revisions', :action => 'revisions'
      repository_views.connect 'projects/:id/repository/revisions.:format', :action => 'revisions'
      repository_views.connect 'projects/:id/repository/revisions/:rev', :action => 'revision'
      repository_views.connect 'projects/:id/repository/revisions/:rev/diff', :action => 'diff'
      repository_views.connect 'projects/:id/repository/revisions/:rev/diff.:format', :action => 'diff'
      repository_views.connect 'projects/:id/repository/revisions/:rev/raw/*path', :action => 'entry', :format => 'raw', :requirements => { :rev => /[a-z0-9\.\-_]+/ }
      repository_views.connect 'projects/:id/repository/revisions/:rev/:action/*path', :requirements => { :rev => /[a-z0-9\.\-_]+/ }
      repository_views.connect 'projects/:id/repository/raw/*path', :action => 'entry', :format => 'raw'
      # TODO: why the following route is required?
      repository_views.connect 'projects/:id/repository/entry/*path', :action => 'entry'
      repository_views.connect 'projects/:id/repository/:action/*path'
    end
    
    repositories.connect 'projects/:id/repository/:action', :conditions => {:method => :post}
  end
  
  map.connect 'attachments/:id', :controller => 'attachments', :action => 'show', :id => /\d+/
  map.connect 'attachments/:id/:filename', :controller => 'attachments', :action => 'show', :id => /\d+/, :filename => /.*/
  map.connect 'attachments/download/:id/:filename', :controller => 'attachments', :action => 'download', :id => /\d+/, :filename => /.*/
   
  map.resources :groups
  
  #left old routes at the bottom for backwards compat
  map.connect 'projects/:project_id/issues/:action', :controller => 'issues'
  map.connect 'projects/:project_id/documents/:action', :controller => 'documents'
  map.connect 'projects/:project_id/boards/:action/:id', :controller => 'boards'
  map.connect 'boards/:board_id/topics/:action/:id', :controller => 'messages'
  map.connect 'wiki/:id/:page/:action', :page => nil, :controller => 'wiki'
  map.connect 'issues/:issue_id/relations/:action/:id', :controller => 'issue_relations'
  map.connect 'projects/:project_id/news/:action', :controller => 'news'  
  map.connect 'projects/:project_id/timelog/:action/:id', :controller => 'timelog', :project_id => /.+/
  map.with_options :controller => 'repositories' do |omap|
    omap.repositories_show 'repositories/browse/:id/*path', :action => 'browse'
    omap.repositories_changes 'repositories/changes/:id/*path', :action => 'changes'
    omap.repositories_diff 'repositories/diff/:id/*path', :action => 'diff'
    omap.repositories_entry 'repositories/entry/:id/*path', :action => 'entry'
    omap.repositories_entry 'repositories/annotate/:id/*path', :action => 'annotate'
    omap.connect 'repositories/revision/:id/:rev', :action => 'revision'
  end
  
  map.with_options :controller => 'sys' do |sys|
    sys.connect 'sys/projects.:format', :action => 'projects', :conditions => {:method => :get}
    sys.connect 'sys/projects/:id/repository.:format', :action => 'create_project_repository', :conditions => {:method => :post}
  end
 
  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect 'robots.txt', :controller => 'welcome', :action => 'robots'
  # Used for OpenID
  map.root :controller => 'account', :action => 'login'
end

#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

OpenProject::Application.routes.draw do
  root :to => 'welcome#index', :as => 'home'

  scope :controller => 'account' do
    get '/account/force_password_change', :action => 'force_password_change'
    post '/account/change_password', :action => 'change_password'
    match '/login', :action => 'login',  :as => 'signin', :via => [:get, :post]
    get '/logout', :action => 'logout', :as => 'signout'
  end

  namespace :api do

    namespace :v1 do
      resources :issues
      resources :news
      resources :projects do
        collection do
          get :level_list
        end

        resources :issues
        resources :news
      end
      resources :time_entries, :controller => 'timelog'
      resources :users
    end

    namespace :v2 do

      resources :authentication
      resources :planning_element_journals
      resources :planning_element_statuses
      resources :colors, :controller => 'planning_element_type_colors'
      resources :planning_element_types do
        collection do
          get :paginate_planning_element_types
        end
      end
      resources :planning_elements
      resources :project_types do
        collection do
          get :paginate_project_types
        end
      end
      resources :reported_project_statuses do
        collection do
          get :paginate_reported_project_statuses
        end
      end
      resources :timelines

      resources :projects do
        resources :planning_elements
        resources :reportings do
          get :available_projects, :on => :collection
        end
        resources :project_associations do
          get :available_projects, :on => :collection
        end
      end

    end
  end

  match '/roles/workflow/:id/:role_id/:type_id' => 'roles#workflow'
  match '/help/:ctrl/:page' => 'help#index'

  resources :types

  # only providing routes for journals when there are multiple subclasses of journals
  # all subclasses will look for the journals routes
  resources :journals, :only => [:edit, :update] do
    get :preview, on: :member
  end

  # REVIEW: review those wiki routes
  scope "projects/:project_id/wiki/:id" do
    resource :wiki_menu_item, :only => [:edit, :update]
  end

  get   'projects/:project_id/wiki/new' => 'wiki#new', :as => 'wiki_new'
  post  'projects/:project_id/wiki/new' => 'wiki#create', :as => 'wiki_create'
  post  'projects/:project_id/wiki/preview' => 'wiki#preview', :as => 'wiki_preview'
  get   'projects/:project_id/wiki/:id/new' => 'wiki#new_child', :as => 'wiki_new_child'
  get   'projects/:project_id/wiki/:id/toc' => 'wiki#index', :as => 'wiki_page_toc'
  post  'projects/:id/wiki' => 'wikis#edit'
  match 'projects/:id/wiki/destroy' => 'wikis#destroy'

  # generic route for adding/removing watchers.
  # Models declared as acts_as_watchable will be automatically added to
  # OpenProject::Acts::Watchable::Routes.watched
  scope ':object_type/:object_id', :constraints => OpenProject::Acts::Watchable::Routes do
    resources :watchers, :only => [:new, :create]

    match '/watch' => 'watchers#watch', :via => :post
    match '/unwatch' => 'watchers#unwatch', :via => :delete
  end

  resources :watchers, :only => [:destroy]

  # TODO: remove
  scope "issues" do
    match 'changes' => 'journals#index', :as => 'changes'
  end

  resources :projects, :except => [:edit] do
    member do
      # this route let's you access the project specific settings (by tab)
      #
      #   settings_project_path(@project)
      #     => "/projects/1/settings"
      #
      #   settings_project_path(@project, :tab => 'members')
      #     => "/projects/1/settings/members"
      #
      get 'settings(/:tab)', :action => 'settings', :as => :settings

      get :copy
      post :copy
      put :modules
      put :archive
      put :unarchive

      # Destroy uses a get request to prompt the user before the actual DELETE request
      get :destroy_info, :as => 'confirm_destroy'

    end

    resource :enumerations, :controller => 'project_enumerations', :only => [:update, :destroy]

    resources :versions, :only => [:new, :create] do
      collection do
        put :close_completed
      end
    end

    # this is only another name for versions#index
    # For nice "road in the url for the index action
    # this could probably be rewritten with a resource :as => 'roadmap'
    match '/roadmap' => 'versions#index', :via => :get

    resources :news, :only => [:index, :new, :create] do
      collection do
        resource :preview, :controller => "news/previews", :only => [:create], :as => "news_preview"
      end
    end

    namespace :time_entries do
      resource :report, :controller => 'reports', :only => [:show]
    end
    resources :time_entries, :controller => 'timelog'

    resources :wiki, :except => [:index, :new, :create] do
      collection do
        get :export
        get :date_index
        get '/index' => 'wiki#index'
      end

      member do
        get '/diff/:version/vs/:version_from' => 'wiki#diff', :as => 'wiki_diff'
        get '/diff(/:version)' => 'wiki#diff', :as => 'wiki_diff'
        get '/annotate/:version' => 'wiki#annotate', :as => 'wiki_annotate'
        match :rename, :via => [:get, :put]
        get :parent_page, :action => 'edit_parent_page'
        put :parent_page, :action => 'update_parent_page'
        get :history
        post :preview
        post :protect
        post :add_attachment
        get  :list_attachments
      end
    end
    # as routes for index and show are swapped
    # it is necessary to define the show action later
    # than any other route as it otherwise would
    # work as a catchall for everything under /wiki
    get 'wiki' => "wiki#show"

    namespace :issues do
      resources :calendar, :controller => 'calendars', :only => [:index]
    end

    resources :issues, :only => [] do
      collection do
        match '/report/:detail' => 'issues/reports#report_details', :via => :get
        match '/report' => 'issues/reports#report', :via => :get
      end
    end

    resources :work_packages, :only => [:new, :create, :index] do
      get :new_type, :on => :collection
      put :preview, :on => :collection
    end

    resources :activity, :activities, :only => :index, :controller => 'activities'

    resources :boards

    resources :issue_categories, :except => [:index, :show], :shallow => true

    resources :members, :only => [:create, :update, :destroy], :shallow => true do
      get :autocomplete, :on => :collection
    end
  end

  #TODO: evaluate whether this can be turned into a namespace
  scope "admin" do
    match "/projects" => 'admin#projects', :via => :get

    resources :enumerations

    resources :groups do
      member do
        get :autocomplete_for_user
        #this should be put into it's own resource
        match "/members" => 'groups#add_users', :via => :post, :as => 'members_of'
        match "/members/:user_id" => 'groups#remove_user', :via => :delete, :as => 'member_of'
        #this should be put into it's own resource
        match "/memberships/:membership_id" => 'groups#edit_membership', :via => :put, :as => 'membership_of'
        match "/memberships/:membership_id" => 'groups#destroy_membership', :via => :delete, :as => 'membership_of'
        match "/memberships" => 'groups#create_memberships', :via => :post, :as => 'memberships_of'
      end
    end

    resources :roles, :only => [:index, :new, :create, :edit, :update, :destroy] do
      collection do
        put '/' => 'roles#bulk_update'
        get :report
      end
    end

    resources :auth_sources, :ldap_auth_sources do
      member do
        get :test_connection
      end
    end
  end

  # this is to support global actions on issues and
  # for backwards compatibility
  namespace :issues do
    resources :calendar, :controller => 'calendars', :only => [:index]

    # have a global autocompleter for issues
    # TODO: make this ressourceful
    match 'auto_complete' => 'auto_completes#issues', :via => [:get, :post], :format => false

    # TODO: separate routes and action for get and post
    match 'context_menu' => 'context_menus#issues', :via => [:get, :post], :format => false
  end

  resources :issues, :only => [] do
    namespace :time_entries do
      resource :report, :controller => 'reports', :only => [:show]
    end

    resources :time_entries, :controller => 'timelog'

    resources :relations, :controller => 'issue_relations', :only => [:create, :destroy]

    collection do
      get :bulk_edit, :format => false
      put :bulk_update, :format => false
    end
  end

  resources :work_packages, :only => [:show, :edit, :update, :index] do
    get :new_type, :on => :member
    put :preview, :on => :member

    resources :relations, :controller => 'work_package_relations', :only => [:create, :destroy]

    # move bulk of wps
    get 'move/new' => 'work_packages/moves#new', :on => :collection, :as => 'new_move'
    post 'move' => 'work_packages/moves#create', :on => :collection, :as => 'move'
    # move individual wp
    resource :move, :controller => 'work_packages/moves', :only => [:new, :create]

    resources :time_entries, :controller => 'timelog'
    # this duplicate mapping is required for the timelog_helper
    namespace :time_entries do
      resource :report, :controller => 'reports'
    end
  end

  resources :versions, :only => [:show, :edit, :update, :destroy] do
    member do
      get :status_by
    end
  end

  # Misc journal routes. TODO: move into resources
  match '/journals/:id/diff/:field' => 'journals#diff', :via => :get, :as => 'journal_diff'


  namespace :time_entries do
    resource :report, :controller => 'reports',
      :only => [:show]
  end

  resources :time_entries, :controller => 'timelog'

  resources :activity, :activities, :only => :index, :controller => 'activities'

  resources :users do
    member do
      match '/edit/:tab' => 'users#edit', :via => :get
      match '/memberships/:membership_id/destroy' => 'users#destroy_membership', :via => :post
      match '/memberships/:membership_id' => 'users#edit_membership', :via => :post
      match '/memberships' => 'users#edit_membership', :via => :post
      post :change_status
      post :edit_membership
      post :destroy_membership
      get :deletion_info
    end
  end

  resources :boards, :only => [] do
    resources :topics, :controller => 'messages', :except => [:index], :shallow => true do
      collection do
        post :preview
      end

      member do
        get :quote
        post :reply, :as => 'reply_to'
        post :preview
      end
    end
  end

  resources :news, :only => [:index, :destroy, :update, :edit, :show] do
    resources :comments, :controller => 'news/comments', :only => [:create, :destroy], :shallow => true

    resource :preview, :controller => 'news/previews', :only => [:create]
  end

  scope :controller => 'repositories' do
    scope :via => :get do
      match '/projects/:id/repository', :action => :show
      match '/projects/:id/repository/edit', :action => :edit
      match '/projects/:id/repository/statistics', :action => :stats
      match '/projects/:id/repository/committers', :action => :committers
      match '/projects/:id/repository/graph', :action => :graph
      match '/projects/:id/repository/diff', :action => :diff
      match '/projects/:id/repository/revisions', :action => :revisions
      match '/projects/:id/repository/revisions.:format', :action => :revisions
      match '/projects/:id/repository/revisions/:rev', :action => :revision
      match '/projects/:id/repository/revisions/:rev/diff/*path(.:format)', :action => :diff
      match '/projects/:id/repository/revisions/:rev/raw/*path', :action => :entry, :kind => 'raw', :rev => /[a-z0-9\.\-_]+/
      match '/projects/:id/repository/revisions/:rev/:action/*path', :rev => /[a-z0-9\.\-_]+/
      match '/projects/:id/repository/raw/*path', :action => :entry, :kind => 'raw'
      # TODO: why the following route is required?
      match '/projects/:id/repository/entry/*path', :action => :entry
      match '/projects/:id/repository/:action/*path'
    end

    match '/projects/:id/repository/:action', :via => :post
  end


  resources :attachments, :only => [:show, :destroy], :format => false do
    member do
      scope :via => :get,  :constraints => { :id => /\d+/, :filename => /[^\/]*/ } do
        match 'download(/:filename)' => 'attachments#download', :as => 'download'
        match ':filename' => 'attachments#show'
      end
    end
  end
  # redirect for backwards compatibility
  scope :constraints => { :id => /\d+/, :filename => /[^\/]*/ } do
    match "/attachments/download/:id/:filename" => redirect("/attachments/%{id}/download/%{filename}"), :format => false
    match "/attachments/download/:id" => redirect("/attachments/%{id}/download"), :format => false
  end

  #left old routes at the bottom for backwards compat
  scope :controller => 'repositories' do
    match '/repositories/browse/:id/*path', :action => 'browse', :as => 'repositories_show'
    match '/repositories/changes/:id/*path', :action => 'changes', :as => 'repositories_changes'
    match '/repositories/diff/:id/*path', :action => 'diff', :as => 'repositories_diff'
    match '/repositories/entry/:id/*path', :action => 'entry', :as => 'repositories_entry'
    match '/repositories/annotate/:id/*path', :action => 'annotate', :as => 'repositories_entry'
    match '/repositories/revision/:id/:rev', :action => 'revision'
  end

  scope :controller => 'sys' do
    match '/sys/projects.:format', :action => 'projects', :via => :get
    match '/sys/projects/:id/repository.:format', :action => 'create_project_repository', :via => :post
  end

  # alternate routes for the current user
  scope "my" do
    match '/deletion_info' => 'users#deletion_info', :via => :get, :as => 'delete_my_account_info'
  end

  scope :controller => 'my' do
    get '/my/password', :action => 'password'
    post '/my/change_password', :action => 'change_password'
  end

  get 'authentication' => 'authentication#index'

  resources :colors, :controller => 'planning_element_type_colors' do
     member do
       get :confirm_destroy
       get :move
       post :move
     end
  end

  resources :planning_element_statuses, :controller => 'planning_element_statuses'

  resources :planning_element_types, :controller => 'planning_element_types' do
    collection do
      get :paginate_planning_element_types
    end
    member do
      get :confirm_destroy
      get :move
      post :move
    end
  end

  resources :project_types, :controller => 'project_types' do
    member do
      get :confirm_destroy
      get :move
      post :move
    end

    resources :projects, :only => [:index, :show], :controller => 'projects'
    resources :reported_project_statuses,          :controller => 'reported_project_statuses'
  end

  resources :projects, :only => [:index, :show], :controller => 'projects' do
    resources :planning_element_types, :controller => 'planning_element_types' do
      member do
        get :confirm_destroy
        get :move
        post :move
      end
    end

    resources :planning_elements,      :controller => 'planning_elements' do
      collection do
        get :all
        delete :destroy_all
        get :confirm_destroy_all
      end

      member do
        get :confirm_destroy
      end

      resources :journals, :controller => 'planning_element_journals',
                                           :only       => [:index, :create]
    end
    resources :project_associations,   :controller => 'project_associations' do
      get :confirm_destroy, :on => :member
      get :available_projects, :on => :collection
    end

    resources :reportings,             :controller => 'reportings' do
      get :confirm_destroy, :on => :member
    end

    resources :timelines,              :controller => 'timelines'

    resources :principals, :controller => 'timelines_principals' do
      collection do
        get :paginate_principals
      end
    end
  end

  resources :reported_project_statuses, :controller => 'reported_project_statuses' do
    collection do
      get :paginate_reported_project_statuses
    end
  end

  # Install the default route as the lowest priority.
  match '/:controller(/:action(/:id))'
  match '/robots' => 'welcome#robots', :defaults => { :format => :txt }
  # Used for OpenID
  root :to => 'account#login'
end

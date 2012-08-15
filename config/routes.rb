#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
OpenProject::Application.routes.draw do
  scope Redmine::Utils.relative_url_root.blank? ? "/" : Redmine::Utils.relative_url_root do
    # Add your own custom routes here.
    # The priority is based upon order of creation: first created -> highest priority.

    # Here's a sample route:
    # connect 'products/:id', :controller => 'catalog', :action => 'view'
    # Keep in mind you can assign values other than :controller and :action

    root :to => 'Welcome#index', :as => 'home'

    match '/login' => 'account#login', :as => 'signin'
    match '/logout' => 'account#logout', :as => 'signout'

    match '/roles/workflow/:id/:role_id/:tracker_id' => 'roles#worklfow'
    match '/help/:ctrl/:page' => 'help#index'

    scope :controller => 'time_entry_reports', :action => 'report', :via => :get do
      match '/projects/:project_id/issues/:issue_id/time_entries/report(.:format)'
      match '/projects/:project_id/time_entries/report(.:format)'
      match '/time_entries/report(.:format)'
    end

    resources :time_entries, :controller => 'timelog'

    match '/projects/:id/wiki' => 'wikis#edit', :via => :post
    match '/projects/:id/wiki/destroy' => 'wikis#destroy', :via => [:get, :post]

    scope :controller => 'messages' do
      scope :via => :get do
        match '/boards/:board_id/topics/new', :action => :new
        match '/boards/:board_id/topics/:id', :action => :show
        match '/boards/:board_id/topics/:id/edit', :action => :edit
      end
      scope :via => :post do
        match '/boards/:board_id/topics/new', :action => :new
        match '/boards/:board_id/topics/:id/replies', :action => :reply
        match '/boards/:board_id/topics/:id/:action', :action => /edit|destroy/
      end
    end

    scope :controller => 'documents' do
      scope :via => :get do
        match '/projects/:project_id/documents', :action => :index
        match '/projects/:project_id/documents/new', :action => :new
        match '/documents/:id', :action => :show
        match '/documents/:id/edit', :action => :edit
      end
      scope :via => :post do
        match '/projects/:project_id/documents', :action => :new
        match '/documents/:id/:action', :action => /destroy|edit/
      end
    end

    # only providing routes for journals when there are multiple subclasses of journals
    # all subclasses will look for the journals routes
    resources :journals, :only => [:edit, :update]

    namespace :issues do
    end

    # generic route for adding/removing watchers
    # looks to be ressourceful
    scope ':object_type/:object_id', :constraints => { :object_type => /issues|messages|boards/,
                                                       :object_id => /\d+/ } do
      resources :watchers, :only => [:new]

      match '/watch' => 'watchers#watch', :via => :post
      match '/unwatch' => 'watchers#unwatch', :via => :delete
    end

    resources :watchers, :only => [:destroy]

    # TODO: remove
    scope "issues" do
      match 'changes' => 'journals#index', :as => 'changes'
    end

    resources :projects do
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

        get 'copy'
        post 'copy'
        post 'modules'
        post 'archive'
        post 'unarchive'
      end

      resource 'enumerations', :controller => 'project_enumerations', :only => [:update, :destroy]
      resources :files, :only => [:index, :new, :create]

      resources :versions, :only => [:new, :create] do
        collection do
          put :close_completed
        end
      end

      # this is only another name for versions#index
      # For nice "road in the url for the index action
      # this could probably be rewritten with a resource :as => 'roadmap'
      match '/roadmap' => 'versions#index', :via => :get

      resources :news, :shallow => true
      resources :time_entries, :controller => 'timelog', :path_prefix => 'projects/:project_id'

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
          match :rename, :via => [:get, :post]
          get :history
          post :preview
          post :protect
          post :add_attachment
        end
      end
      # as routes for index and show are swapped
      # it is necessary to define the show action later
      # than any other route as it otherwise would
      # work as a catchall for everything under /wiki
      get 'wiki' => "wiki#show"

      namespace :issues do
        resources :gantt, :controller => 'gantts', :only => [:index]
        resources :calendar, :controller => 'calendars', :only => [:index]
      end

      resources :issues, :except => [:show, :edit, :update, :destroy] do
        # should probably belong to :member, but requires :copy_from instead
        # of the default :id
        get ':copy_from/copy', :action => "new", :on => :collection, :as => "copy"

        collection do
          get :all

          # get a preview of a new issue (i.e. one without an ID)
          match '/new/preview' => 'previews#issue', :as => 'preview_new', :via => :post
        end
      end

      resources :activity, :activities, :only => :index, :controller => 'activities'

      resources :boards
    end

    #TODO: evaluate whether this can be turned into a namespace
    scope "admin" do
      match "/projects" => 'admin#projects', :via => :get

      resources :enumerations, :only => [:index, :edit, :update, :destroy, :new, :create]

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
      resources :gantt, :controller => 'gantts', :only => [:index]
      resources :calendar, :controller => 'calendars', :only => [:index]

      # have a global autocompleter for issues
      # TODO: make this ressourceful
      match 'auto_complete' => 'auto_completes#issues', :via => [:get, :post], :format => false

      # TODO: separate routes and action for get and post
      match 'context_menu' => 'context_menus#issues', :via => [:get, :post], :format => false

      resource :move, :controller => 'moves', :only => [:new, :create]
    end

    # TODO: remove create as issues should be created scoped under project
    resources :issues, :only => [:create, :show, :edit, :update, :destroy] do
      resources :time_entries, :controller => 'timelog'

      member do
        # this route is defined so that it has precedence of the one defined on the collection
        delete :destroy
      end

      collection do
        get :bulk_edit, :format => false
        put :bulk_update, :format => false

        delete :destroy
      end
    end

    resources :versions, :only => [:show, :edit, :update, :destroy] do
      member do
        get :status_by
      end
    end

    # Misc issue routes. TODO: move into resources
    match '/issues/preview/:id' => 'previews#issue', :as => 'preview_issue'  # TODO: would look nicer as /issues/:id/preview
    match '/issues/:id/quoted' => 'journals#new', :id => /\d+/, :via => :post, :as => 'quoted_issue'
    match '/issues/:id/destroy' => 'issues#destroy', :via => :post # legacy

    scope :controller => 'reports', :via => :get do
      match '/projects/:id/issues/report', :action => :issue_report
      match '/projects/:id/issues/report/:detail', :action => :issue_report_details
    end

    resources :activity, :activities, :only => :index, :controller => 'activities'

    scope  :controller => 'issue_relations', :via => :post do
      match '/issues/:issue_id/relations(/:id)', :action => :new
      match '/issues/:issue_id/relations/:id/destroy', :action => :destroy
    end

    match '/projects/:id/members/new' => 'members#new'

    resources :users, :member => {
      :edit_membership => :post,
      :destroy_membership => :post,
      :deletion_info => :get
    }

    scope :controller => 'users' do
      match '/users/:id/edit/:tab', :action => 'edit', :tab => nil, :via => :get

      scope :via => :post do
        match '/users/:id/memberships', :action => 'edit_membership'
        match '/users/:id/memberships/:membership_id', :action => 'edit_membership'
        match '/users/:id/memberships/:membership_id/destroy', :action => 'destroy_membership'
      end
    end


    match '/news' => 'news#index', :as => 'all_news'
    match '/news.:format' => 'news#index', :as => 'formatted_all_news'
    match '/news/preview' => 'previews#news', :as => 'preview_news'
    match '/news/:id/comments' => 'comments#create', :via => :post
    match '/news/:id/comments/:comment_id' => 'comments#destroy', :via => :delete

    # Destroy uses a get request to prompt the user before the actual DELETE request
    match '/projects/:id/destroy' => 'project#destroy', :via => :get, :as => 'project_destroy_confirm'

    scope :controller => 'issue_categories' do
      match '/projects/:project_id/issue_categories/new', :action => :new
    end

    scope :controller => 'repositories' do
      scope :via => :get do
        match '/projects/:id/repository', :action => :show
        match '/projects/:id/repository/edit', :action => :edit
        match '/projects/:id/repository/statistics', :action => :stats
        match '/projects/:id/repository/revisions', :action => :revisions
        match '/projects/:id/repository/revisions.:format', :action => :revisions
        match '/projects/:id/repository/revisions/:rev', :action => :revision
        match '/projects/:id/repository/revisions/:rev/diff', :action => :diff
        match '/projects/:id/repository/revisions/:rev/diff.:format', :action => :diff
        match '/projects/:id/repository/revisions/:rev/raw/*path', :action => :entry, :format => 'raw', :rev => /[a-z0-9\.\-_]+/
        match '/projects/:id/repository/revisions/:rev/:action/*path', :rev => /[a-z0-9\.\-_]+/
        match '/projects/:id/repository/raw/*path', :action => :entry, :format => 'raw'
        # TODO: why the following route is required?
        match '/projects/:id/repository/entry/*path', :action => :entry
        match '/projects/:id/repository/:action/*path'
      end

      match '/projects/:id/repository/:action', :via => :post
    end

    resources :attachments, :only => [:show], :format => false do
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

    resources :groups

    #left old routes at the bottom for backwards compat
    match '/projects/:project_id/documents/:action', :controller => 'documents'
    match '/projects/:project_id/boards/:action/:id', :controller => 'boards'
    match '/boards/:board_id/topics/:action/:id', :controller => 'messages'
    match '/issues/:issue_id/relations/:action/:id', :controller => 'issue_relations'
    match '/projects/:project_id/news/:action', :controller => 'news'
    match '/projects/:project_id/timelog/:action/:id', :controller => 'timelog', :project_id => /.+/
    scope :controller => 'repositories' do
      match '/repositories/browse/:id/*path', :action => 'browse', :as => 'repositories_show'
      match '/repositories/changes/:id/*path', :action => 'changes', :as => 'repositories_changes'
      match '/repositories/diff/:id/*path', :action => 'diff', :as => 'repositories_diff'
      match '/repositories/entry/:id/*path', :action => 'entry', :as => 'repositories_entry'
      match '/repositories/annotate/:id/*path', :action => 'annotate', :as => 'stylesheet_link_tag'
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

    # Install the default route as the lowest priority.
    match '/:controller(/:action(/:id))'
    match '/robots.txt' => 'welcome#robots'
    # Used for OpenID
    root :to => 'account#login'
  end
end

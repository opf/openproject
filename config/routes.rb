#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++


OpenProject::Application.routes.draw do
  root :to => 'welcome#index', :as => 'home'

  rails_relative_url_root = OpenProject::Configuration['rails_relative_url_root'] || ''

  # Redirect deprecated issue links to new work packages uris
  match '/issues(/)'    => redirect("#{rails_relative_url_root}/work_packages/")
  # The URI.escape doesn't escape / unless you ask it to.
  # see https://github.com/rails/rails/issues/5688
  match '/issues/*rest' => redirect { |params, req| "#{rails_relative_url_root}/work_packages/#{URI.escape(params[:rest])}" }

  # Redirect wp short url for work packages to full URL
  match '/wp(/)'    => redirect("#{rails_relative_url_root}/work_packages/")
  match '/wp/*rest' => redirect { |params, req| "#{rails_relative_url_root}/work_packages/#{URI.escape(params[:rest])}" }

  scope :controller => 'account' do
    get '/account/force_password_change', :action => 'force_password_change'
    post '/account/change_password', :action => 'change_password'
    get '/account/lost_password', :action => 'lost_password'
    
    # omniauth routes
    post '/auth/:provider/callback', :action => 'omniauth_login', :as => 'omniauth_login'
    get '/auth/failure', action: 'omniauth_failure'

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
      resources :users, only: [:index]
      resources :planning_element_journals
      resources :statuses
      resources :colors, :controller => 'planning_element_type_colors'
      resources :planning_element_types
      resources :planning_elements
      resources :project_types
      resources :reported_project_statuses
      resources :statuses, :only => [:index, :show]
      resources :timelines
      resources :planning_element_priorities, only: [:index]

      resources :projects do
        resources :planning_elements
        resources :planning_element_types
        resources :reportings do
          get :available_projects, :on => :collection
        end
        resources :project_associations do
          get :available_projects, :on => :collection
        end
        resources :statuses, :only => [:index, :show]

        member do
          get :planning_element_custom_fields
        end
        resources :workflows, only: [:index]
      end

      resources :custom_fields

      namespace :pagination, :as => 'paginate' do
        [:users,
         :principals,
         :statuses,
         :types,
         :project_types,
         :reported_project_statuses,
         :projects].each do |model|
          resources model, :only => [:index]
        end
      end

    end
  end

  match '/roles/workflow/:id/:role_id/:type_id' => 'roles#workflow'
  match '/help/:ctrl/:page' => 'help#index'

  resources :types
  resources :statuses, :except => :show do
    collection do
      post 'update_work_package_done_ratio'
    end
  end
  resources :custom_fields, :except => :show
  match "(projects/:project_id)/search" => 'search#index', :as => "search"

  # only providing routes for journals when there are multiple subclasses of journals
  # all subclasses will look for the journals routes
  resources :journals, :only => [:edit, :update] do
    get :preview, on: :member
  end

  # REVIEW: review those wiki routes
  scope "projects/:project_id/wiki/:id" do
    resource :wiki_menu_item, :only => [:edit, :update]
  end

  scope "projects/:project_id/query/:query_id" do
    resources :query_menu_items, :except => [:show]
  end

  get   'projects/:project_id/wiki/new' => 'wiki#new', :as => 'wiki_new'
  post  'projects/:project_id/wiki/new' => 'wiki#create', :as => 'wiki_create'
  get   'projects/:project_id/wiki/:id/new' => 'wiki#new_child', :as => 'wiki_new_child'
  get   'projects/:project_id/wiki/:id/toc' => 'wiki#index', :as => 'wiki_page_toc'
  post  'projects/:project_id/wiki/preview' => 'wiki#preview', as: 'preview_wiki'
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

      match "copy_project_from_(:coming_from)" => "copy_projects#copy_project", :via => :get, :as => :copy_from,
            constraints: { coming_from: /(admin|settings)/ }
      match "copy" => "copy_projects#copy", :via => :post
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

    resources :news, :only => [:index, :new, :create]

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
        post :protect
        post :add_attachment
        get  :list_attachments
        get :select_main_menu_item, to: 'wiki_menu_items#select_main_menu_item'
        post :replace_main_menu_item, to: 'wiki_menu_items#replace_main_menu_item'
        post :preview
      end
    end
    # as routes for index and show are swapped
    # it is necessary to define the show action later
    # than any other route as it otherwise would
    # work as a catchall for everything under /wiki
    get 'wiki' => "wiki#show"

    namespace :work_packages do
      resources :calendar, :controller => 'calendars', :only => [:index]
    end

    resources :work_packages, :only => [:new, :create, :index] do
      get :new_type, :on => :collection

      collection do
        match '/report/:detail' => 'work_packages/reports#report_details', :via => :get
        match '/report' => 'work_packages/reports#report', :via => :get
      end
    end

    resources :activity, :activities, :only => :index, :controller => 'activities'

    resources :boards do
      member do
        get :confirm_destroy
        get :move
        post :move
      end
    end

    resources :categories, :except => [:index, :show], :shallow => true

    resources :members, :only => [:create, :update, :destroy], :shallow => true do
      get :autocomplete, :on => :collection
    end

    resource :repository, :only => [:destroy] do
      get :edit #needed as show is configured manually with a wildcard
      post :edit
      get :committers
      post :committers
      get :graph
      get :revisions

      get "/statistics", :action => :stats, :as => 'stats'

      get '(/revisions/:rev)/diff.:format', :action => :diff
      get '(/revisions/:rev)/diff(/*path)', :action => :diff,
                                            :format => false

      get '(/revisions/:rev)/:format/*path', :action => :entry,
                                             :format => /raw/,
                                             :rev => /[a-z0-9\.\-_]+/

      %w{diff annotate changes entry browse}.each do |action|
        get "(/revisions/:rev)/#{action}(/*path)", :format => false,
                                                   :action => action,
                                                   :rev => /[a-z0-9\.\-_]+/
      end

      get '/revision(/:rev)', :rev => /[a-z0-9\.\-_]+/,
                              :action => :revision

      get '(/revisions/:rev)(/*path)', :action => :show,
                                       :format => false,
                                       :rev => /[a-z0-9\.\-_]+/

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

  namespace :work_packages do
    match 'auto_complete' => 'auto_completes#index', :via => [:get, :post]
    match 'context_menu' => 'context_menus#index', :via => [:get, :post], :format => false
    resources :calendar, :controller => 'calendars', :only => [:index]
    resource :bulk, :controller => 'bulk', :only => [:edit, :update, :destroy]
  end

  resources :work_packages, :only => [:show, :edit, :update, :index] do
    get :new_type, :on => :member

    resources :relations, :controller => 'work_package_relations', :only => [:create, :destroy]

    # move bulk of wps
    get 'move/new' => 'work_packages/moves#new', :on => :collection, :as => 'new_move'
    post 'move' => 'work_packages/moves#create', :on => :collection, :as => 'move'
    # move individual wp
    resource :move, :controller => 'work_packages/moves', :only => [:new, :create]

    # this duplicate mapping is required for the timelog_helper
    namespace :time_entries do
      resource :report, :controller => 'reports'
    end
    resources :time_entries, :controller => 'timelog'

    post :preview, on: :collection
    post :preview, on: :member
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

      member do
        get :quote
        post :reply, :as => 'reply_to'
        post :preview
      end

      post :preview, on: :collection
    end
  end

  resources :news, :only => [:index, :destroy, :update, :edit, :show] do
    resources :comments, :controller => 'news/comments', :only => [:create, :destroy], :shallow => true

    post :preview, on: :member
    post :preview, on: :collection
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
    match "/attachments/download/:id/:filename" => redirect("#{rails_relative_url_root}/attachments/%{id}/download/%{filename}"), :format => false
    match "/attachments/download/:id" => redirect("#{rails_relative_url_root}/attachments/%{id}/download"), :format => false
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
    resources :project_associations,   :controller => 'project_associations' do
      get :confirm_destroy, :on => :member
      get :available_projects, :on => :collection
    end

    resources :reportings,             :controller => 'reportings' do
      get :confirm_destroy, :on => :member
    end

    resources :timelines,              :controller => 'timelines'
  end

  resources :reported_project_statuses, :controller => 'reported_project_statuses'

  # Install the default route as the lowest priority.
  match '/:controller(/:action(/:id))'
  match '/robots' => 'welcome#robots', :defaults => { :format => :txt }
  # Used for OpenID
  root :to => 'account#login'
end

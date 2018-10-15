#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

OpenProject::Application.routes.draw do
  root to: 'homescreen#index', as: 'home'
  rails_relative_url_root = OpenProject::Configuration['rails_relative_url_root'] || ''

  # Redirect deprecated issue links to new work packages uris
  get '/issues(/)'    => redirect("#{rails_relative_url_root}/work_packages")
  # The URI.escape doesn't escape / unless you ask it to.
  # see https://github.com/rails/rails/issues/5688
  get '/issues/*rest' => redirect { |params, _req| "#{rails_relative_url_root}/work_packages/#{URI.escape(params[:rest])}" }

  # Respond with 410 gone for APIV2 calls
  match '/api/v2(/*unmatched_route)', to: proc { [410, {}, ['']] }, via: :all
  match '/assets/compiler.js.map', to: proc { [404, {}, ['']] }, via: :all

  # Redirect wp short url for work packages to full URL
  get '/wp(/)'    => redirect("#{rails_relative_url_root}/work_packages")
  get '/wp/*rest' => redirect { |params, _req| "#{rails_relative_url_root}/work_packages/#{URI.escape(params[:rest])}" }

  # Add catch method for Rack OmniAuth to allow route helpers
  # Note: This renders a 404 in rails but is caught by omniauth in Rack before
  get '/auth/failure', to: 'account#omniauth_failure'
  get '/auth/:provider', to: proc { [404, {}, ['']] }, as: 'omniauth_start'
  match '/auth/:provider/callback', to: 'account#omniauth_login', as: 'omniauth_login', via: %i[get post]

  # In case assets are actually delivered by a node server (e.g. in test env)
  # we redirect all requests to socksjs necessary to support HMR to that server.
  # Status code 307 is important so that POST requests are repeated as POST.
  if FrontendAssetHelper.assets_proxied?
    match '/sockjs-node/*appendix',
          to: redirect("http://localhost:4200/sockjs-node/%{appendix}", status: 307),
          format: false,
          via: :all

    match '/assets/frontend/*appendix',
          to: redirect("http://localhost:4200/assets/frontend/%{appendix}", status: 307),
          format: false,
          via: :all
  end

  scope controller: 'account' do
    get '/account/force_password_change', action: 'force_password_change'
    post '/account/change_password', action: 'change_password'
    match '/account/lost_password', action: 'lost_password', via: %i[get post]
    match '/account/register', action: 'register', via: %i[get post patch]
    get '/account/activate', action: 'activate'

    match '/login', action: 'login',  as: 'signin', via: %i[get post]
    get '/logout', action: 'logout', as: 'signout'

    get '/sso', action: 'auth_source_sso_failed', as: 'sso_failure'

    get '/login/:stage/failure', action: 'stage_failure', as: 'stage_failure'
    get '/login/:stage/:secret', action: 'stage_success', as: 'stage_success'

    get '/account/consent', action: 'consent', as: 'account_consent'
    get '/account/decline_consent', action: 'decline_consent', as: 'account_decline_consent'
    post '/account/confirm_consent', action: 'confirm_consent', as: 'account_confirm_consent'
  end

  # Because of https://github.com/intridea/grape/pull/853/files this has to be
  # placed behind handling the deprecated v1 because otherwise, a 405 is
  # returned for all routes for which the v3 has also resources. Grape does
  # remove the prefix (v3) before checking whether the method is supported. I
  # don't understand why that should make sense.
  mount API::Root => '/'

  get '/roles/workflow/:id/:role_id/:type_id' => 'roles#workflow'

  get   '/types/:id/edit/:tab' => "types#edit",
        as: "edit_type_tab"
  match '/types/:id/update/:tab' => "types#update",
        as: "update_type_tab",
        via: %i[post patch]
  resources :types do
    post 'move/:id', action: 'move', on: :collection
  end

  resources :statuses, except: :show do
    collection do
      post 'update_work_package_done_ratio'
    end
  end

  get 'custom_style/:digest/logo/:filename' => 'custom_styles#logo_download',
      as: 'custom_style_logo',
      constraints: { filename: /[^\/]*/ }

  get 'custom_style/:digest/favicon/:filename' => 'custom_styles#favicon_download',
      as: 'custom_style_favicon',
      constraints: { filename: /[^\/]*/ }

  get 'custom_style/:digest/touch-icon/:filename' => 'custom_styles#touch_icon_download',
      as: 'custom_style_touch_icon',
      constraints: { filename: /[^\/]*/ }

  get 'highlighting/styles' => 'highlighting#styles',
      as: 'highlighting_css_styles'

  resources :custom_fields, except: :show do
    member do
      match "options/:option_id",
            to: "custom_fields#delete_option",
            via: :delete,
            as: :delete_option_of
    end
  end

  get '(projects/:project_id)/search' => 'search#index', as: 'search'

  # only providing routes for journals when there are multiple subclasses of journals
  # all subclasses will look for the journals routes
  resources :journals, only: :index do
    get 'diff/:field', action: :diff, on: :member, as: 'diff'
  end

  # REVIEW: review those wiki routes
  scope 'projects/:project_id/wiki/:id' do
    resource :wiki_menu_item, only: %i[edit update]
  end

  # generic route for adding/removing watchers.
  # Models declared as acts_as_watchable will be automatically added to
  # OpenProject::Acts::Watchable::Routes.watched
  scope ':object_type/:object_id', constraints: OpenProject::Acts::Watchable::Routes do
    match '/watch' => 'watchers#watch', via: :post
    match '/unwatch' => 'watchers#unwatch', via: :delete
  end

  resources :projects, except: [:edit] do
    member do
      # this route let's you access the project specific settings (by tab)
      #
      #   settings_project_path(@project)
      #     => "/projects/1/settings"
      #
      #   settings_project_path(@project, tab: 'members')
      #     => "/projects/1/settings/members"
      #
      get 'settings(/:tab)', controller: 'project_settings', action: 'show', as: :settings

      get 'identifier', action: 'identifier'
      patch 'identifier', action: 'update_identifier'

      match 'copy_project_from_(:coming_from)' => 'copy_projects#copy_project', via: :get, as: :copy_from,
            constraints: { coming_from: /(admin|settings)/ }
      match 'copy_from_(:coming_from)' => 'copy_projects#copy', via: :post, as: :copy,
            constraints: { coming_from: /(admin|settings)/ }
      put :modules
      put :custom_fields
      put :archive
      put :unarchive
      patch :types

      get 'column_sums', controller: 'work_packages'

      # Destroy uses a get request to prompt the user before the actual DELETE request
      get :destroy_info, as: 'confirm_destroy'
    end

    collection do
      get :level_list
    end

    resource :enumerations, controller: 'project_enumerations', only: %i[update destroy]

    resources :versions, only: %i[new create] do
      collection do
        put :close_completed
      end
    end

    # this is only another name for versions#index
    # For nice "road in the url for the index action
    # this could probably be rewritten with a resource as: 'roadmap'
    match '/roadmap' => 'versions#index', via: :get

    resources :news, only: %i[index new create]

    namespace :time_entries do
      resource :report, controller: 'reports', only: [:show]
    end
    resources :time_entries, controller: 'timelog'

    # Match everything to be the ID of the wiki page except the part that
    # is reserved for the format. This assumes that we have only two formats:
    # .txt and .html
    resources :wiki,
              constraints: { id: /([^\/]+(?=\.markdown)|[^\/]+)/ },
              except: %i[index create] do
      collection do
        post '/new' => 'wiki#create', as: 'create'
        get :export
        get :date_index
        get '/index' => 'wiki#index'
      end

      member do
        get '/new' => 'wiki#new_child', as: 'new_child'
        get '/diff/:version/vs/:version_from' => 'wiki#diff', as: 'wiki_diff_compare'
        get '/diff(/:version)' => 'wiki#diff', as: 'wiki_diff'
        get '/annotate/:version' => 'wiki#annotate', as: 'wiki_annotate'
        get '/toc' => 'wiki#index'
        match :rename, via: %i[get patch]
        get :parent_page, action: 'edit_parent_page'
        patch :parent_page, action: 'update_parent_page'
        get :history
        post :protect
        post :add_attachment
        get :list_attachments
        get :select_main_menu_item, to: 'wiki_menu_items#select_main_menu_item'
        post :replace_main_menu_item, to: 'wiki_menu_items#replace_main_menu_item'
      end
    end

    # as routes for index and show are swapped
    # it is necessary to define the show action later
    # than any other route as it otherwise would
    # work as a catchall for everything under /wiki
    get 'wiki' => 'wiki#show'

    namespace :work_packages do
      resources :calendar, controller: 'calendars', only: [:index]
    end

    resources :work_packages, only: [] do
      collection do
        get '/report/:detail' => 'work_packages/reports#report_details'
        get '/report' => 'work_packages/reports#report'
      end

      # states managed by client-side routing on work_package#index
      get '(/*state)' => 'work_packages#index', on: :collection, as: ''
      get '/create_new' => 'work_packages#index', on: :collection, as: 'new_split'
      get '/new' => 'work_packages#index', on: :collection, as: 'new'

      # state for show view in project context
      get '(/*state)' => 'work_packages#show', on: :member, as: ''
    end

    resources :activity, :activities, only: :index, controller: 'activities'

    resources :boards do
      member do
        get :confirm_destroy
        get :move
        post :move
      end
    end

    resources :categories, except: %i[index show], shallow: true

    resources :members, only: %i[index create update destroy], shallow: true do
      collection do
        get :paginate_users
        match :autocomplete_for_member, via: %i[get post]
      end
    end

    resource :repository, controller: 'repositories', except: [:new] do
      # Destroy uses a get request to prompt the user before the actual DELETE request
      get :destroy_info
      get :committers
      post :committers
      get :graph
      get :revisions

      get '/statistics', action: :stats, as: 'stats'

      get '(/revisions/:rev)/diff.:format', action: :diff
      get '(/revisions/:rev)/diff(/*repo_path)',
          action: :diff,
          format: false

      get '(/revisions/:rev)/:format/*repo_path',
          action: :entry,
          format: /raw/,
          rev: /[\w0-9\.\-_]+/

      %w{diff annotate changes entry browse}.each do |action|
        get "(/revisions/:rev)/#{action}(/*repo_path)",
            format: 'html',
            action: action,
            constraints: { rev: /[\w0-9\.\-_]+/, repo_path: /.*/ },
            as: "#{action}_revision"
      end

      get '/revision(/:rev)', rev: /[\w0-9\.\-_]+/,
                              action: :revision,
                              as: 'show_revision'

      get '(/revisions/:rev)(/*repo_path)',
          action: :show,
          format: 'html',
          constraints: { rev: /[\w0-9\.\-_]+/, repo_path: /.*/ },
          as: 'show_revisions_path'
    end
  end

  resources :admin, controller: :admin, only: :index do
    collection do
      get :plugins
      get :info
      post :force_user_language
      post :test_email
    end
  end

  scope 'admin' do
    resource :announcements, only: %i[edit update]
    constraints(Enterprise) do
      resource :enterprise, only: %i[show create destroy]
    end
    resources :enumerations

    delete 'design/logo' => 'custom_styles#logo_delete', as: 'custom_style_logo_delete'
    delete 'design/favicon' => 'custom_styles#favicon_delete', as: 'custom_style_favicon_delete'
    delete 'design/touch_icon' => 'custom_styles#touch_icon_delete', as: 'custom_style_touch_icon_delete'
    get 'design/upsale' => 'custom_styles#upsale', as: 'custom_style_upsale'
    post 'design/colors' => 'custom_styles#update_colors', as: 'update_design_colors'
    resource :custom_style, only: %i[update show create], path: 'design'

    resources :attribute_help_texts, only: %i(index new create edit update destroy)

    resources :groups do
      member do
        get :autocomplete_for_user
        # this should be put into it's own resource
        match '/members' => 'groups#add_users', via: :post, as: 'members_of'
        match '/members/:user_id' => 'groups#remove_user', via: :delete, as: 'member_of'
        # this should be put into it's own resource
        match '/memberships/:membership_id' => 'groups#edit_membership', via: :put, as: 'membership_of'
        match '/memberships/:membership_id' => 'groups#destroy_membership', via: :delete
        match '/memberships' => 'groups#create_memberships', via: :post, as: 'memberships_of'
      end
    end

    resources :roles, only: %i[index new create edit update destroy] do
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

    resources :custom_actions, except: :show
  end

  # We should fix this crappy routing (split up and rename controller methods)
  get '/settings' => 'settings#index'
  scope 'settings', controller: 'settings' do
    match 'edit', action: 'edit', via: %i[get post]
    match 'plugin/:id', action: 'plugin', via: %i[get post]
  end

  # We should fix this crappy routing (split up and rename controller methods)
  get '/workflows' => 'workflows#index'
  scope 'workflows', controller: 'workflows' do
    match 'edit', action: 'edit', via: %i[get post]
    match 'copy', action: 'copy', via: %i[get post]
  end

  namespace :work_packages do
    match 'auto_complete' => 'auto_completes#index', via: %i[get post]
    resources :calendar, controller: 'calendars', only: [:index]
    resource :bulk, controller: 'bulk', only: %i[edit update destroy]
    # FIXME: this is kind of evil!! We need to remove this soonest and
    # cover the functionality. Route is being used in work-package-service.js:331
    get '/bulk' => 'bulk#destroy'
  end

  resources :work_packages, only: [:index] do
    get :column_data, on: :collection # TODO move to API

    # move bulk of wps
    get 'move/new' => 'work_packages/moves#new', on: :collection, as: 'new_move'
    post 'move' => 'work_packages/moves#create', on: :collection, as: 'move'
    # move individual wp
    resource :move, controller: 'work_packages/moves', only: %i[new create]

    # this duplicate mapping is required for the timelog_helper
    namespace :time_entries do
      resource :report, controller: 'reports'
    end
    resources :time_entries, controller: 'timelog'

    # states managed by client-side routing on work_package#index
    get 'details/*state' => 'work_packages#index', on: :collection, as: :details

    # states managed by client-side (angular) routing on work_package#show
    get '/' => 'work_packages#index', on: :collection, as: 'index'
    get '/create_new' => 'work_packages#index', on: :collection, as: 'new_split'
    get '/new' => 'work_packages#index', on: :collection, as: 'new', state: 'new'
    get '(/*state)' => 'work_packages#show', on: :member, as: ''
    get '/edit' => 'work_packages#show', on: :member, as: 'edit'
  end

  resources :versions, only: %i[show edit update destroy] do
    member do
      get :status_by
    end
  end

  namespace :time_entries do
    resource :report, controller: 'reports',
                      only: [:show]
  end

  resources :time_entries, controller: 'timelog'

  resources :activity, :activities, only: :index, controller: 'activities'

  resources :users do
    resources :memberships, controller: 'users/memberships', only: %i[update create destroy]

    member do
      match '/edit/:tab' => 'users#edit', via: :get, as: 'tab_edit'
      match '/change_status/:change_action' => 'users#change_status_info', via: :get, as: 'change_status_info'
      post :change_status
      post :resend_invitation
      get :deletion_info
    end
  end

  resources :boards, only: [] do
    resources :topics, controller: 'messages', except: [:index], shallow: true do
      member do
        get :quote
        post :reply, as: 'reply_to'
      end
    end
  end

  resources :news, only: %i[index destroy update edit show] do
    resources :comments, controller: 'news/comments', only: %i[create destroy], shallow: true
  end

  # redirect for backwards compatibility
  scope constraints: { id: /\d+/, filename: /[^\/]*/ } do
    get '/attachments/download/:id/:filename',
        to: redirect("#{rails_relative_url_root}/attachments/%{id}/%{filename}"),
        format: false

    get '/attachments/download/:id',
        to: redirect("#{rails_relative_url_root}/attachments/%{id}"),
        format: false
  end

  resources :attachments, only: %i{destroy fulltext}, format: false do
    member do
      scope via: :get, constraints: { id: /\d+/, filename: /[^\/]*/ } do
        match '(/:filename)' => 'attachments#download', as: 'download'
      end

      scope via: :get, constraints: { id: /\d+/, filename: /[^\/]*/ } do
        match '(/:filename/fulltext)' => 'attachments#fulltext', as: 'fulltext'
      end
    end
  end

  resource :help, controller: :help, only: [] do
    member do
      get :keyboard_shortcuts
      get :text_formatting
    end
  end

  scope controller: 'sys' do
    match '/sys/repo_auth', action: 'repo_auth', via: %i[get post]
    get '/sys/projects', action: 'projects'
    get '/sys/fetch_changesets', action: 'fetch_changesets'
    get '/sys/projects/:id/repository/update_storage', action: 'update_required_storage'
  end

  # alternate routes for the current user
  scope 'my' do
    match '/deletion_info' => 'users#deletion_info', via: :get, as: 'delete_my_account_info'
  end

  scope controller: 'my' do
    post '/my/add_block', action: 'add_block'
    post '/my/remove_block', action: 'remove_block'
    post '/my/order_blocks', action: 'order_blocks'
    get '/my/page_layout', action: 'page_layout'
    get '/my/password', action: 'password'
    post '/my/change_password', action: 'change_password'
    get '/my/page', action: 'page'
    match '/my/account', action: 'account', via: %i[get patch]
    match '/my/settings', action: 'settings', via: %i[get patch]
    match '/my/mail_notifications', action: 'mail_notifications', via: %i[get patch]
    post '/my/generate_rss_key', action: 'generate_rss_key'
    post '/my/generate_api_key', action: 'generate_api_key'
    get '/my/access_token', action: 'access_token'
  end

  scope controller: 'onboarding' do
    patch 'user_settings', action: 'user_settings'
  end

  get 'authentication' => 'authentication#index'

  resources :colors do
    member do
      get :confirm_destroy
      get :move
      post :move
    end
  end

  # This route should probably be removed, but it's used at least by one cuke and we don't
  # want to break it.
  # This route intentionally occurs after the admin/roles/new route, so that one takes
  # precedence when creating routes (possibly via helpers).
  get 'roles/new' => 'roles#new', as: 'deprecated_roles_new'

  get '/robots' => 'homescreen#robots', defaults: { format: :txt }

  root to: 'account#login'

  # Development route for styleguide
  if Rails.env.development?
    get '/styleguide' => redirect('/assets/styleguide.html')
  end
end

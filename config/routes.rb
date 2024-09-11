#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

Rails.application.routes.draw do
  root to: "homescreen#index", as: "home"
  rails_relative_url_root = OpenProject::Configuration["rails_relative_url_root"] || ""

  # Route for error pages
  get "/404", to: "errors#not_found"
  get "/422", to: "errors#unacceptable"
  get "/500", to: "errors#internal_error"

  # Route for health_checks
  get "/health_check" => "ok_computer/ok_computer#show", check: "web"
  # Override the default `all` checks route to return the full check
  get "/health_checks/all" => "ok_computer/ok_computer#show", check: "full"
  mount OkComputer::Engine, at: "/health_checks"

  get "/api/docs" => "api_docs#index"

  # Redirect deprecated issue links to new work packages uris
  get "/issues(/)" => redirect("#{rails_relative_url_root}/work_packages")
  # The URI.escape doesn't escape / unless you ask it to.
  # see https://github.com/rails/rails/issues/5688
  get "/issues/*rest" => redirect { |params, _req|
    "#{rails_relative_url_root}/work_packages/#{URI::RFC2396_Parser.new.escape(params[:rest])}"
  }

  # Respond with 410 gone for APIV2 calls
  match "/api/v2(/*unmatched_route)", to: proc { [410, {}, [""]] }, via: :all
  match "/assets/compiler.js.map", to: proc { [404, {}, [""]] }, via: :all

  # Redirect wp short url for work packages to full URL
  get "/wp(/)" => redirect("#{rails_relative_url_root}/work_packages")
  get "/wp/*rest" => redirect { |params, _req|
    "#{rails_relative_url_root}/work_packages/#{URI::RFC2396_Parser.new.escape(params[:rest])}"
  }

  # Add catch method for Rack OmniAuth to allow route helpers
  # Note: This renders a 404 in rails but is caught by omniauth in Rack before
  get "/auth/failure", to: "account#omniauth_failure"
  get "/auth/:provider", to: proc { [404, {}, [""]] }, as: "omniauth_start"
  match "/auth/:provider/callback", to: "account#omniauth_login", as: "omniauth_login", via: %i[get post]

  # In case assets are actually delivered by a node server (e.g. in test env)
  # forward requests to the proxy
  if FrontendAssetHelper.assets_proxied?
    match "/assets/frontend/*appendix",
          to: redirect("#{FrontendAssetHelper.cli_proxy}/assets/frontend/%{appendix}", status: 307),
          format: false,
          via: :all
  end

  # Shared route concerns
  # TODO: Add description how to configure controller to support shares
  concern :shareable do
    resources :members, path: "shares", controller: "shares", only: %i[index create update destroy] do
      member do
        post "resend_invite" => "shares#resend_invite"
      end

      collection do
        get :dialog, to: "shares#dialog"
        patch :bulk, to: "shares#bulk_update"
        put :bulk, to: "shares#bulk_update"
        delete :bulk, to: "shares#bulk_destroy"
      end
    end
  end

  scope controller: "account" do
    get "/account/force_password_change", action: "force_password_change"
    post "/account/change_password", action: "change_password"
    match "/account/lost_password", action: "lost_password", via: %i[get post]
    match "/account/register", action: "register", via: %i[get post patch]
    get "/account/activate", action: "activate"

    match "/login", action: "login", as: "signin", via: %i[get post]
    get "/login/internal", action: "internal_login", as: "internal_signin"
    get "/logout", action: "logout", as: "signout"

    get "/sso", action: "auth_source_sso_failed", as: "sso_failure"

    get "/login/:stage/failure", action: "stage_failure", as: "stage_failure"
    get "/login/:stage/:secret", action: "stage_success", as: "stage_success"

    get "/account/consent", action: "consent", as: "account_consent"
    get "/account/decline_consent", action: "decline_consent", as: "account_decline_consent"
    post "/account/confirm_consent", action: "confirm_consent", as: "account_confirm_consent"
  end

  # Because of https://github.com/intridea/grape/pull/853/files this has to be
  # placed behind handling the deprecated v1 because otherwise, a 405 is
  # returned for all routes for which the v3 has also resources. Grape does
  # remove the prefix (v3) before checking whether the method is supported. I
  # don't understand why that should make sense.
  mount API::Root => "/api"

  # OAuth authorization routes
  use_doorkeeper do
    # Do not add global application controller
    skip_controllers :applications, :authorized_applications
  end

  get "/roles/workflow/:id/:role_id/:type_id" => "roles#workflow"

  get "/types/:id/edit/:tab" => "types#edit",
      as: "edit_type_tab"
  match "/types/:id/update/:tab" => "types#update",
        as: "update_type_tab",
        via: %i[post patch]
  resources :types do
    post "move/:id", action: "move", on: :collection
  end

  resources :statuses, except: :show

  get "custom_style/:digest/logo/:filename" => "custom_styles#logo_download",
      as: "custom_style_logo",
      constraints: { filename: /[^\/]*/ }

  get "custom_style/:digest/export_logo/:filename" => "custom_styles#export_logo_download",
      as: "custom_style_export_logo",
      constraints: { filename: /[^\/]*/ }

  get "custom_style/:digest/export_cover/:filename" => "custom_styles#export_cover_download",
      as: "custom_style_export_cover",
      constraints: { filename: /[^\/]*/ }

  get "custom_style/:digest/favicon/:filename" => "custom_styles#favicon_download",
      as: "custom_style_favicon",
      constraints: { filename: /[^\/]*/ }

  get "custom_style/:digest/touch-icon/:filename" => "custom_styles#touch_icon_download",
      as: "custom_style_touch_icon",
      constraints: { filename: /[^\/]*/ }

  get "highlighting/styles(/:version_tag)" => "highlighting#styles",
      as: "highlighting_css_styles"

  resources :custom_fields, except: :show do
    member do
      delete "options/:option_id", to: "custom_fields#delete_option", as: :delete_option_of

      post :reorder_alphabetical
    end
  end

  get "(projects/:project_id)/search" => "search#index", as: "search"

  # only providing routes for journals when there are multiple subclasses of journals
  # all subclasses will look for the journals routes
  resources :journals, only: :index do
    get "diff/:field", action: :diff, on: :member, as: "diff"
  end

  # REVIEW: review those wiki routes
  scope "projects/:project_id/wiki/:id" do
    resource :wiki_menu_item, only: %i[edit update]
  end

  # generic route for adding/removing watchers
  scope ":object_type/:object_id", constraints: OpenProject::Acts::Watchable::RouteConstraint do
    post "/watch" => "watchers#watch"
    delete "/unwatch" => "watchers#unwatch"
  end

  # generic route for adding/removing favorites
  scope ":object_type/:object_id", constraints: OpenProject::Acts::Favorable::RouteConstraint do
    post "/favorite" => "favorites#favorite"
    delete "/favorite" => "favorites#unfavorite"
  end

  resources :project_queries, only: %i[show new create update destroy], controller: "projects/queries" do
    concerns :shareable

    member do
      get :rename
      post :toggle_public
      get :destroy_confirmation_modal
    end

    collection do
      get :configure_view_modal
    end
  end

  namespace :projects do
    resource :menu, only: %i[show]
  end

  resources :projects, except: %i[show edit create update] do
    scope module: "projects" do
      namespace "settings" do
        resource :general, only: %i[show], controller: "general"
        resource :modules, only: %i[show update]
        resource :types, only: %i[show update]
        resource :project_custom_fields, only: %i[show] do
          member do
            post :toggle
          end
          collection do
            put :enable_all_of_section
            put :disable_all_of_section
          end
        end
        resource :custom_fields, only: %i[show update]
        resource :repository, only: %i[show], controller: "repository"
        resource :versions, only: %i[show]
        resource :categories, only: %i[show update]
        resource :storage, only: %i[show], controller: "storage"
      end

      resource :templated, only: %i[create destroy], controller: "templated"
      resource :archive, only: %i[create destroy], controller: "archive"
      resource :identifier, only: %i[show update], controller: "identifier"
    end

    member do
      get "settings", to: redirect("projects/%{id}/settings/general/")

      get :copy

      patch :types

      # Destroy uses a get request to prompt the user before the actual DELETE request
      get :destroy_info, as: "confirm_destroy"
      post :deactivate_work_package_attachments
    end

    collection do
      get :export_list_modal
    end

    resources :versions, only: %i[new create] do
      collection do
        put :close_completed
      end
    end

    # this is only another name for versions#index
    # For nice "road in the url for the index action
    # this could probably be rewritten with a resource as: 'roadmap'
    get "/roadmap" => "versions#index"

    resources :news, only: %i[index new create]

    # Match everything to be the ID of the wiki page except the part that
    # is reserved for the format. This assumes that we have only two formats:
    # .txt and .html
    resources :wiki,
              constraints: { id: /([^\/]+(?=\.markdown)|[^\/]+)/ },
              except: %i[index create] do
      collection do
        post "/new" => "wiki#create", as: "create"
        get :export
        get "/index" => "wiki#index"
        get :menu
      end

      member do
        get "/new" => "wiki#new_child", as: "new_child"
        get "/diff/:version/vs/:version_from" => "wiki#diff", as: "wiki_diff_compare"
        get "/diff(/:version)" => "wiki#diff", as: "wiki_diff"
        get "/annotate/:version" => "wiki#annotate", as: "wiki_annotate"
        get "/toc" => "wiki#index"
        match :rename, via: %i[get patch]
        get :parent_page, action: "edit_parent_page"
        patch :parent_page, action: "update_parent_page"
        get :history
        post :protect
        get :select_main_menu_item, to: "wiki_menu_items#select_main_menu_item"
        post :replace_main_menu_item, to: "wiki_menu_items#replace_main_menu_item"
        get :menu
      end
    end

    # as routes for index and show are swapped
    # it is necessary to define the show action later
    # than any other route as it otherwise would
    # work as a catchall for everything under /wiki
    get "wiki" => "wiki#show"

    resources :work_packages, only: [] do
      collection do
        get "/report/:detail" => "work_packages/reports#report_details"
        get "/report" => "work_packages/reports#report"
        get "menu" => "work_packages/menus#show"
        get "/export_dialog" => "work_packages#export_dialog"
      end

      # states managed by client-side routing on work_package#index
      get "(/*state)" => "work_packages#index", on: :collection, as: ""
      get "/create_new" => "work_packages#index", on: :collection, as: "new_split"
      get "/new" => "work_packages#index", on: :collection, as: "new"

      # state for show view in project context
      get "(/*state)" => "work_packages#show", on: :member, as: ""
    end

    resources :activity, :activities, only: :index, controller: "activities" do
      collection do
        get :menu
      end
    end

    resources :forums do
      member do
        get :confirm_destroy
        get :move
        post :move
      end
    end

    resources :categories, except: %i[index show], shallow: true

    resources :members, only: %i[index create update], shallow: true do
      collection do
        delete "by_principal/:principal_id", action: :destroy_by_principal

        get :autocomplete_for_member
      end
    end

    namespace :members do
      resource :menu, only: %[show]
    end

    resource :repository, controller: "repositories", except: [:new] do
      # Destroy uses a get request to prompt the user before the actual DELETE request
      get :destroy_info
      get :committers
      post :committers
      get :graph
      get :revisions

      get "/statistics", action: :stats, as: "stats"

      get "(/revisions/:rev)/diff.:format", action: :diff
      get "(/revisions/:rev)/diff(/*repo_path)",
          action: :diff,
          format: "html",
          constraints: { rev: /[\w.\-]+/, repo_path: /.*/ }

      get "(/revisions/:rev)/:format/*repo_path",
          action: :entry,
          format: /raw/,
          rev: /[\w.\-]+/

      %w{diff annotate changes entry browse}.each do |action|
        get "(/revisions/:rev)/#{action}(/*repo_path)",
            format: "html",
            action:,
            constraints: { rev: /[\w.\-]+/, repo_path: /.*/ },
            as: "#{action}_revision"
      end

      get "/revision(/:rev)", rev: /[\w.\-]+/,
                              action: :revision,
                              as: "show_revision"

      get "(/revisions/:rev)(/*repo_path)",
          action: :show,
          format: "html",
          constraints: { rev: /[\w.\-]+/, repo_path: /.*/ },
          as: "show_revisions_path"
    end
  end

  resources :admin, controller: :admin, only: :index do
    collection do
      get :plugins
      get :info
      post :test_email
    end
  end

  scope "admin" do
    resource :announcements, only: %i[edit update]
    constraints(Constraints::Enterprise) do
      resource :enterprise, only: %i[show create destroy]
      scope controller: "enterprises" do
        post "enterprise/save_trial_key" => "enterprises#save_trial_key"
        delete "enterprise/delete_trial_key" => "enterprises#delete_trial_key"
      end
    end
    resources :enumerations do
      post "move/:id", action: "move", on: :collection
    end

    delete "design/logo" => "custom_styles#logo_delete", as: "custom_style_logo_delete"
    delete "design/export_logo" => "custom_styles#export_logo_delete", as: "custom_style_export_logo_delete"
    delete "design/export_cover" => "custom_styles#export_cover_delete", as: "custom_style_export_cover_delete"
    delete "design/favicon" => "custom_styles#favicon_delete", as: "custom_style_favicon_delete"
    delete "design/touch_icon" => "custom_styles#touch_icon_delete", as: "custom_style_touch_icon_delete"
    get "design/upsale" => "custom_styles#upsale", as: "custom_style_upsale"
    post "design/colors" => "custom_styles#update_colors", as: "update_design_colors"
    post "design/themes" => "custom_styles#update_themes", as: "update_design_themes"
    post "design/export_cover_text_color" => "custom_styles#update_export_cover_text_color",
         as: "update_custom_style_export_cover_text_color"

    resource :custom_style, only: %i[update show create], path: "design"

    resources :attribute_help_texts, only: %i(index new create edit update destroy)

    resources :groups, except: %i[show] do
      member do
        # this should be put into it's own resource
        post "/members" => "groups#add_users", as: "members_of"
        delete "/members/:user_id" => "groups#remove_user", as: "member_of"
        # this should be put into it's own resource
        patch "/memberships/:membership_id" => "groups#edit_membership", as: "membership_of"
        put "/memberships/:membership_id" => "groups#edit_membership"
        delete "/memberships/:membership_id" => "groups#destroy_membership"
        post "/memberships" => "groups#create_memberships", as: "memberships_of"
      end
    end

    resources :roles, except: %i[show] do
      collection do
        put "/" => "roles#bulk_update"
        get :report
      end
    end

    resources :ldap_auth_sources do
      member do
        get :test_connection
      end
    end

    resources :custom_actions, except: :show

    namespace :oauth do
      resources :applications
    end
  end

  namespace :admin do
    namespace :settings do
      SettingsHelper.system_settings_tabs.each do |tab|
        get tab[:name], controller: tab[:controller], action: :show, as: tab[:name].to_s
        patch tab[:name], controller: tab[:controller], action: :update, as: "update_#{tab[:name]}"
      end

      resource :authentication, controller: "/admin/settings/authentication_settings", only: %i[show update]
      resource :attachments, controller: "/admin/settings/attachments_settings", only: %i[show update]
      resource :virus_scanning, controller: "/admin/settings/virus_scanning_settings", only: %i[show update] do
        collection do
          get :av_form
        end
      end

      resource :incoming_mails, controller: "/admin/settings/incoming_mails_settings", only: %i[show update]
      resource :aggregation, controller: "/admin/settings/aggregation_settings", only: %i[show update]
      resource :mail_notifications, controller: "/admin/settings/mail_notifications_settings", only: %i[show update]
      resource :api, controller: "/admin/settings/api_settings", only: %i[show update]
      # It is important to have this named something else than "work_packages".
      # Otherwise the angular ui-router will also recognize that as a WorkPackage page and apply according classes.
      resource :work_package_tracking, controller: "/admin/settings/work_packages_settings", only: %i[show update]
      resource :projects, controller: "/admin/settings/projects_settings", only: %i[show update]
      resource :new_project, controller: "/admin/settings/new_project_settings", only: %i[show update]
      resources :project_custom_fields, controller: "/admin/settings/project_custom_fields" do
        member do
          delete "options/:option_id", action: "delete_option", as: :delete_option_of
          post :reorder_alphabetical
          put :move
          put :drop

          get :project_mappings
          get :new_link
          post :link
          delete :unlink
        end
      end
      resources :project_custom_field_sections, controller: "/admin/settings/project_custom_field_sections",
                                                only: %i[create update destroy] do
        member do
          put :move
          put :drop
        end
      end
      resource :working_days_and_hours, controller: "/admin/settings/working_days_and_hours_settings", only: %i[show update]
      resource :users, controller: "/admin/settings/users_settings", only: %i[show update]
      resource :date_format, controller: "/admin/settings/date_format_settings", only: %i[show update]
      resource :icalendar, controller: "/admin/settings/icalendar_settings", only: %i[show update]

      # Redirect /settings to general settings
      get "/", to: redirect("/admin/settings/general")

      # Plugin settings
      get "plugin/:id", action: :show_plugin
      post "plugin/:id", action: :update_plugin
    end

    resources :quarantined_attachments,
              controller: "/admin/attachments/quarantined_attachments",
              only: %i[index destroy]

    resource :backups, controller: "/admin/backups", only: %i[show] do
      collection do
        get :reset_token
        post :reset_token, action: :perform_token_reset

        post :delete_token
      end
    end
  end

  resource :workflows, only: %i[edit update show] do
    member do
      # We should fix this crappy routing (split up and rename controller methods)
      match "copy", action: "copy", via: %i[get post]
    end
  end

  namespace :work_packages do
    get "menu" => "menus#show"

    match "auto_complete" => "auto_completes#index", via: %i[get post]
    resource :bulk, controller: "bulk", only: %i[edit update destroy]
    # FIXME: this is kind of evil!! We need to remove this soonest and
    # cover the functionality. Route is being used in work-package-service.js:331
    get "/bulk" => "bulk#destroy"
  end

  resources :work_packages, only: [:index] do
    concerns :shareable

    # move bulk of wps
    get "move/new" => "work_packages/moves#new", on: :collection, as: "new_move"
    post "move" => "work_packages/moves#create", on: :collection, as: "move"
    # move individual wp
    resource :move, controller: "work_packages/moves", only: %i[new create]

    # states managed by client-side routing on work_package#index
    get "details/*state" => "work_packages#index", on: :collection, as: :details

    resource :progress, only: %i[new edit update], controller: "work_packages/progress"
    collection do
      resource :progress,
               only: :create,
               controller: "work_packages/progress",
               as: :work_package_progress
    end
    get "/export_dialog" => "work_packages#export_dialog", on: :collection, as: "export_dialog"

    get "/split_view/update_counter" => "work_packages/split_view#update_counter",
        on: :member

    # states managed by client-side (angular) routing on work_package#show
    get "/" => "work_packages#index", on: :collection, as: "index"
    get "/create_new" => "work_packages#index", on: :collection, as: "new_split"
    get "/new" => "work_packages#index", on: :collection, as: "new", state: "new"
    # We do not want to match the work package export routes
    get "(/*state)" => "work_packages#show", on: :member, as: "", constraints: { id: /\d+/, state: /(?!(shares|split_view)).+/ }
    get "/share_upsale" => "work_packages#index", on: :collection, as: "share_upsale"
    get "/edit" => "work_packages#show", on: :member, as: "edit"
  end

  resources :versions, only: %i[show edit update destroy] do
    member do
      get :status_by
    end
  end

  resources :activity, :activities, only: :index, controller: "activities" do
    collection do
      get :menu
    end
  end

  resources :users, constraints: { id: /(\d+|me)/ }, except: :edit do
    resources :memberships, controller: "users/memberships", only: %i[update create destroy]

    member do
      get "/edit(/:tab)" => "users#edit", as: "edit"
      get "/change_status/:change_action" => "users#change_status_info", as: "change_status_info"
      post :change_status
      post :resend_invitation
      get :deletion_info
    end
  end

  resources :placeholder_users, except: :edit do
    resources :memberships, controller: "placeholder_users/memberships", only: %i[update create destroy]

    member do
      get "/edit(/:tab)" => "placeholder_users#edit", as: "edit"
      get :deletion_info
    end
  end

  # The show page of groups is public and thus moved out of the admin scope
  resources :groups, only: %i[show], as: :show_group

  resources :forums, only: [] do
    resources :topics, controller: "messages", except: [:index], shallow: true do
      member do
        get :quote
        post :reply, as: "reply_to"
      end
    end
  end

  resources :news, only: %i[index destroy update edit show] do
    resources :comments, controller: "news/comments", only: %i[create destroy], shallow: true
  end

  # redirect for backwards compatibility
  scope "attachments",
        constraints: { id: /\d+/, filename: /[^\/]*/ },
        format: false do
    get "/download/:id/:filename",
        to: redirect("#{rails_relative_url_root}/attachments/%{id}/%{filename}")

    get "/download/:id",
        to: redirect("#{rails_relative_url_root}/attachments/%{id}")

    scope ":id" do
      get "(/:filename)",
          to: redirect("#{rails_relative_url_root}/api/v3/attachments/%{id}/content")

      delete "",
             to: redirect("#{rails_relative_url_root}/api/v3/attachments/%{id}")
    end
  end

  resource :help, controller: :help, only: [] do
    member do
      get :keyboard_shortcuts
      get :text_formatting
    end
  end

  scope controller: "sys" do
    match "/sys/repo_auth", action: "repo_auth", via: %i[get post]
    get "/sys/projects", action: "projects"
    get "/sys/fetch_changesets", action: "fetch_changesets"
    get "/sys/projects/:id/repository/update_storage", action: "update_required_storage"
  end

  # alternate routes for the current user
  scope "my" do
    get "/deletion_info" => "users#deletion_info", as: "delete_my_account_info"
    post "/oauth/revoke_application/:application_id" => "oauth/grants#revoke_application", as: "revoke_my_oauth_application"
    delete "/storage_token/:id" => "my#delete_storage_token", as: "storage_token_delete"

    resources :sessions, controller: "my/sessions", as: "my_sessions", only: %i[index show destroy]
    resources :auto_login_tokens, controller: "my/auto_login_tokens", as: "my_auto_login_tokens", only: %i[destroy]
  end

  scope controller: "my" do
    get "/my/password", action: "password"
    post "/my/change_password", action: "change_password"

    get "/my/account", action: "account"
    get "/my/settings", action: "settings"
    get "/my/notifications", action: "notifications"
    get "/my/reminders", action: "reminders"

    patch "/my/account", action: "update_account"
    patch "/my/settings", action: "update_settings"

    post "/my/generate_rss_key", action: "generate_rss_key"
    delete "/my/revoke_rss_key", action: "revoke_rss_key"
    post "/my/generate_api_key", action: "generate_api_key"
    delete "/my/revoke_api_key", action: "revoke_api_key"
    delete "/my/revoke_ical_token", action: "revoke_ical_token"
    get "/my/access_token", action: "access_token"
  end

  scope controller: "onboarding" do
    patch "user_settings", action: "user_settings"
  end

  resources :colors do
    member do
      get :confirm_destroy
      get :move
      post :move
    end
  end

  get "/robots" => "homescreen#robots", defaults: { format: :txt }

  root to: "account#login"

  concern :with_split_view do |options|
    get "details/:work_package_id(/:tab)",
        action: options.fetch(:action, :split_view),
        defaults: { tab: :overview },
        as: :details,
        work_package_split_view: true
  end

  resources :notifications, only: :index do
    collection do
      concerns :with_split_view, base_route: :notifications_path

      post :mark_all_read
      resource :menu, module: :notifications, only: %i[show], as: :notifications_menu
    end
  end

  namespace :notifications do
    resource :menu, only: %i[show]
  end

  scope :notifications do
    get "/share_upsale" => "notifications#share_upsale", as: "notifications_share_upsale"
    get "/date_alerts" => "notifications#date_alerts", as: "notifications_date_alert_upsale"
    get "/", to: "notifications#index", as: :notifications_center
  end

  # OAuthClient needs a "callback" URL that Nextcloud calls with a "code" (see OAuth2 RFC)
  scope "oauth_clients/:oauth_client_id" do
    get "callback", controller: "oauth_clients", action: :callback
    get "ensure_connection", controller: "oauth_clients", action: :ensure_connection, as: "oauth_clients_ensure_connection"
  end

  if OpenProject::Configuration.lookbook_enabled?
    mount Lookbook::Engine, at: "/lookbook"
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
    mount GoodJob::Engine => "good_job"
  end
end

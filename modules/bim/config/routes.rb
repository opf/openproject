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
  # API v3 routes for BIM element links and templates
  namespace :api do
    namespace :v3 do
      namespace :bim do
        # Element links
        resources :element_links, controller: "element_links", only: %i[index show create update destroy]

        # Bulk operations for element links
        namespace :element_links do
          post :bulk_create, controller: "bulk_operations", action: :bulk_create
          patch :bulk_update, controller: "bulk_operations", action: :bulk_update
          post :bulk_delete, controller: "bulk_operations", action: :bulk_delete
          post :bulk_status_change, controller: "bulk_operations", action: :bulk_status_change
          post :apply_template, controller: "bulk_operations", action: :apply_template
          post :create_work_packages, controller: "bulk_operations", action: :create_work_packages
          post :refresh_properties, controller: "bulk_operations", action: :refresh_properties
          post :find_matching, controller: "bulk_operations", action: :find_matching
        end

        # Link templates
        resources :link_templates, controller: "link_templates", only: %i[index show create update destroy] do
          member do
            post :clone
            get :statistics
          end
        end

        # Clashes
        resources :clashes, controller: "clashes", only: %i[index show create update destroy] do
          collection do
            post :detect
            get :statistics
          end
          member do
            post :approve
            post :resolve
          end
        end

        # Model Comparisons
        resources :comparisons, controller: "comparisons", only: %i[index show create update destroy] do
          member do
            post :approve
            post :reject
          end
        end

        # Progress Baselines
        resources :baselines, controller: "baselines", only: %i[index show create update destroy] do
          member do
            post :snapshot
            post :set_current
            get :compare
          end
        end

        # Element Progress Tracking
        resources :progress, controller: "progress", only: %i[index show create update destroy] do
          collection do
            post :bulk_update
            post :sync_work_packages
            get :statistics
          end
        end

        # BIM Dashboards & Reporting
        resources :dashboards, controller: "dashboards", only: %i[index show create update destroy] do
          member do
            post :clone
            post :refresh
          end
          collection do
            get :default
          end
        end

        # Dashboard Widgets
        resources :widgets, controller: "dashboard_widgets", only: %i[show create update destroy] do
          member do
            post :refresh
          end
        end

        # Metrics Aggregation
        resources :metrics, controller: "metrics", only: %i[index]

        # Federated Models (nested under projects in API paths)
      end
    end
  end

  # Project-scoped federation routes
  namespace :api do
    namespace :v3 do
      resources :projects, only: [] do
        namespace :bim do
          resources :federations, controller: "bim/federations", only: %i[index show create update destroy] do
            member do
              post :align
              get :viewer_config
            end
          end
        end
      end

      namespace :bim do
        # IFC Models API
        resources :ifc_models, controller: "ifc_models", only: %i[index show create update destroy] do
          member do
            get :conversion_logs
            get :metadata
            post :refresh_metadata
            # 3D Viewer features
            get 'saved_views', to: 'viewer#saved_views'
            post 'saved_views', to: 'viewer#create_saved_view'
            get 'section_configs', to: 'viewer#section_configs'
            post 'section_configs', to: 'viewer#create_section_config'
            get 'measurements', to: 'viewer#measurements'
            post 'measurements', to: 'viewer#create_measurement'
            get 'measurements/export', to: 'viewer#export_measurements'
            get 'annotations', to: 'viewer#annotations'
            post 'annotations', to: 'viewer#create_annotation'
          end
        end

        # 3D Viewer resource endpoints
        resources :saved_views, controller: "viewer", only: [] do
          member do
            get :show_saved_view, action: :show_saved_view, as: 'show'
            patch :update_saved_view, action: :update_saved_view, as: 'update'
            delete :destroy_saved_view, action: :destroy_saved_view, as: 'destroy'
          end
        end

        resources :section_configs, controller: "viewer", only: [] do
          member do
            delete :destroy_section_config, action: :destroy_section_config, as: 'destroy'
          end
        end

        resources :measurements, controller: "viewer", only: [] do
          member do
            delete :destroy_measurement, action: :destroy_measurement, as: 'destroy'
          end
        end

        resources :annotations, controller: "viewer", only: [] do
          member do
            patch :update_annotation, action: :update_annotation, as: 'update'
            delete :destroy_annotation, action: :destroy_annotation, as: 'destroy'
          end
        end

        # Collaboration features
        resources :comment_mentions, controller: "comment_mentions", only: [:index] do
          collection do
            get ':comment_id', action: :show, as: 'comment'
          end
        end

        # Comment reactions
        resources :comments, only: [] do
          member do
            get 'reactions', to: 'comment_reactions#index'
            post 'reactions', to: 'comment_reactions#create'
            post 'reactions/toggle', to: 'comment_reactions#toggle'
            delete 'reactions', to: 'comment_reactions#destroy'
          end
        end

        # IFC Model viewer presence
        resources :ifc_models, only: [] do
          member do
            get 'presence', to: 'viewer_presence#index'
            post 'presence', to: 'viewer_presence#create'
            put 'presence', to: 'viewer_presence#update'
            patch 'presence', to: 'viewer_presence#update'
            delete 'presence', to: 'viewer_presence#destroy'
          end
        end

        # Security & Authentication: API tokens
        resources :api_tokens, controller: "api_tokens", only: %i[index show create update destroy] do
          member do
            post :revoke
          end
        end

        # Performance & Cache Management
        namespace :performance do
          get 'cache_stats', action: :cache_stats
          post 'cache_cleanup', action: :cache_cleanup
          get 'conversion_metrics', action: :conversion_metrics
          get 'model/:id/logs', action: :conversion_logs, as: 'conversion_logs'
        end

        # Workflow Automation
        namespace :workflows, controller: "workflows" do
          # Workflow templates
          get 'templates', action: :index_templates, as: 'templates'
          post 'templates', action: :create_template
          get 'templates/:id', action: :show_template, as: 'template'
          patch 'templates/:id', action: :update_template
          delete 'templates/:id', action: :destroy_template

          # Workflow logs
          get 'logs', action: :logs

          # Workflowable operations
          post ':workflowable_type/:workflowable_id/transition', action: :execute_transition, as: 'transition'
          get ':workflowable_type/:workflowable_id/available_transitions', action: :available_transitions, as: 'available_transitions'
          get ':workflowable_type/:workflowable_id/state', action: :workflow_state, as: 'state'
          get ':workflowable_type/:workflowable_id/timeline', action: :workflow_timeline, as: 'timeline'
        end
      end
    end
  end

  # Security & Authentication: Project-scoped audit logs
  namespace :api do
    namespace :v3 do
      resources :projects, only: [] do
        namespace :bim do
          resources :audit_logs, controller: "bim/audit_logs", only: [:index] do
            collection do
              get :export
              get :report
            end
          end
        end
      end
    end
  end

  scope "", as: "bcf" do
    mount Bim::Bcf::API::Root => "/api/bcf"

    scope "projects/:project_id", as: "project" do
      get "bcf/menu" => "bim/menus#show"

      resources :issues, controller: "bim/bcf/issues", except: :index do
        get :upload, action: :upload, on: :collection
        post :prepare_import, action: :prepare_import, on: :collection
        post :configure_import, action: :configure_import, on: :collection
        post :import, action: :perform_import, on: :collection
      end

      # IFC viewer frontend
      get "bcf(/*state)", to: "bim/ifc_models/ifc_viewer#show", as: :frontend

      # IFC model management
      resources :ifc_models, controller: "bim/ifc_models/ifc_models" do
        collection do
          get :defaults
          get :direct_upload_finished
          post :set_direct_upload_file_name
        end
      end
    end
  end
end
